package com.yicai.trade.module.messagebridge.service.impl;

import com.yicai.trade.module.messagebridge.dto.*;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeBinding;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeSubscription;
import com.yicai.trade.module.messagebridge.repository.BridgeBindingRepository;
import com.yicai.trade.module.messagebridge.repository.BridgeConfigRepository;
import com.yicai.trade.module.messagebridge.repository.BridgeSubscriptionRepository;
import com.yicai.trade.module.messagebridge.service.BridgeSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class BridgeSubscriptionServiceImpl implements BridgeSubscriptionService {

    private final BridgeSubscriptionRepository subscriptionRepository;
    private final BridgeConfigRepository configRepository;
    private final BridgeBindingRepository bindingRepository;

    @Override
    @Transactional
    public BridgeSubscriptionResponse subscribe(Long userId, Long supplierId, BridgeSubscriptionRequest request) {
        String subscriptionNo = "BSUB" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase();

        BigDecimal price = configRepository.findByConfigKey("BRIDGE_MONTHLY_PRICE")
                .map(c -> new BigDecimal(c.getConfigValue()))
                .orElse(new BigDecimal("99.00"));

        int trialDays = configRepository.findByConfigKey("BRIDGE_TRIAL_DAYS")
                .map(c -> Integer.parseInt(c.getConfigValue()))
                .orElse(7);

        // First subscription gets trial period
        List<MessageBridgeSubscription> existing = subscriptionRepository
                .findBySupplierIdAndStatus(supplierId, "ACTIVE");
        boolean isTrial = existing.isEmpty();

        LocalDate startDate = LocalDate.now();
        LocalDate endDate = isTrial ? startDate.plusDays(trialDays) : startDate.plusMonths(1);
        BigDecimal amount = isTrial ? BigDecimal.ZERO : price;

        @lombok.NonNull MessageBridgeSubscription subscription = MessageBridgeSubscription.builder()
                .subscriptionNo(subscriptionNo)
                .supplierId(supplierId)
                .userId(userId)
                .channelType(request.getChannelType())
                .status(isTrial ? "ACTIVE" : "PENDING")
                .amount(amount)
                .startDate(startDate)
                .endDate(endDate)
                .autoRenew(request.getAutoRenew() != null ? request.getAutoRenew() : false)
                .build();

        subscription = subscriptionRepository.save(subscription);
        log.info("Created subscription {} for supplier {}, trial={}", subscriptionNo, supplierId, isTrial);
        return toResponse(subscription);
    }

    @Override
    @Transactional
    public BridgeSubscriptionResponse activateSubscription(Long subscriptionId) {
        MessageBridgeSubscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("订阅不存在"));

        if (!"PENDING".equals(subscription.getStatus())) {
            throw new RuntimeException("订阅状态不允许激活");
        }

        subscription.setStatus("ACTIVE");
        if (subscription.getStartDate() == null) {
            subscription.setStartDate(LocalDate.now());
            subscription.setEndDate(LocalDate.now().plusMonths(1));
        }
        subscription = subscriptionRepository.save(subscription);
        log.info("Activated subscription {}", subscription.getSubscriptionNo());
        return toResponse(subscription);
    }

    @Override
    @Transactional
    public void cancelSubscription(Long subscriptionId, Long userId) {
        MessageBridgeSubscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("订阅不存在"));

        if (!subscription.getUserId().equals(userId)) {
            throw new RuntimeException("无权取消该订阅");
        }

        subscription.setStatus("CANCELLED");
        subscription.setAutoRenew(false);
        subscriptionRepository.save(subscription);
        log.info("Cancelled subscription {}", subscription.getSubscriptionNo());
    }

    @Override
    public boolean hasActiveSubscription(Long supplierId, String channelType) {
        List<MessageBridgeSubscription> active = subscriptionRepository
                .findActiveSubscription(supplierId, channelType, LocalDate.now());
        return !active.isEmpty();
    }

    @Override
    public BridgeStatusResponse getSupplierStatus(Long supplierId) {
        List<MessageBridgeSubscription> activeList = subscriptionRepository
                .findBySupplierIdAndStatus(supplierId, "ACTIVE");

        boolean serviceEnabled = configRepository.findByConfigKey("BRIDGE_SERVICE_ENABLED")
                .map(c -> "true".equalsIgnoreCase(c.getConfigValue())).orElse(false);

        BigDecimal price = configRepository.findByConfigKey("BRIDGE_MONTHLY_PRICE")
                .map(c -> new BigDecimal(c.getConfigValue())).orElse(new BigDecimal("99.00"));

        List<BridgeBindingResponse> bindings = bindingRepository.findBySupplierId(supplierId).stream()
                .map(this::toBindingResponse)
                .collect(Collectors.toList());

        String subscriptionStatus = "NONE";
        LocalDate endDate = null;
        Boolean autoRenew = null;

        if (!activeList.isEmpty()) {
            MessageBridgeSubscription active = activeList.get(0);
            if (active.getEndDate() != null && active.getEndDate().isBefore(LocalDate.now())) {
                subscriptionStatus = "EXPIRED";
            } else {
                subscriptionStatus = "ACTIVE";
                endDate = active.getEndDate();
                autoRenew = active.getAutoRenew();
            }
        }

        return BridgeStatusResponse.builder()
                .serviceEnabled(serviceEnabled)
                .subscriptionStatus(subscriptionStatus)
                .subscriptionEndDate(endDate)
                .autoRenew(autoRenew)
                .monthlyPrice(price)
                .bindings(bindings)
                .build();
    }

    @Override
    @Transactional
    public BridgeSubscriptionResponse renewSubscription(Long subscriptionId, Long userId) {
        MessageBridgeSubscription subscription = subscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new RuntimeException("订阅不存在"));

        if (!subscription.getUserId().equals(userId)) {
            throw new RuntimeException("无权续费该订阅");
        }

        BigDecimal price = configRepository.findByConfigKey("BRIDGE_MONTHLY_PRICE")
                .map(c -> new BigDecimal(c.getConfigValue())).orElse(new BigDecimal("99.00"));

        LocalDate newStart = subscription.getEndDate() != null && subscription.getEndDate().isAfter(LocalDate.now())
                ? subscription.getEndDate() : LocalDate.now();

        String renewNo = "BSUB" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase();

        @lombok.NonNull MessageBridgeSubscription renewal = MessageBridgeSubscription.builder()
                .subscriptionNo(renewNo)
                .supplierId(subscription.getSupplierId())
                .userId(userId)
                .channelType(subscription.getChannelType())
                .status("PENDING")
                .amount(price)
                .startDate(newStart)
                .endDate(newStart.plusMonths(1))
                .autoRenew(subscription.getAutoRenew())
                .build();

        renewal = subscriptionRepository.save(renewal);
        log.info("Renewed subscription {} -> {}", subscription.getSubscriptionNo(), renewNo);
        return toResponse(renewal);
    }

    @Override
    public List<BridgeSubscriptionResponse> listSupplierSubscriptions(Long supplierId, int page, int size) {
        Page<MessageBridgeSubscription> pageResult = subscriptionRepository.findBySupplierId(
                supplierId, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return pageResult.getContent().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    public List<BridgeSubscriptionResponse> listAllSubscriptions(String status, int page, int size) {
        Page<MessageBridgeSubscription> pageResult;
        if (status != null && !status.isEmpty()) {
            pageResult = subscriptionRepository.findByStatus(status,
                    PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        } else {
            pageResult = subscriptionRepository.findAll(
                    PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        }
        return pageResult.getContent().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void expireOverdueSubscriptions() {
        List<MessageBridgeSubscription> overdueList = subscriptionRepository
                .findByStatusAndEndDateBefore("ACTIVE", LocalDate.now());

        for (MessageBridgeSubscription sub : overdueList) {
            if (Boolean.TRUE.equals(sub.getAutoRenew())) {
                log.info("Auto-renewing subscription {}", sub.getSubscriptionNo());
                try {
                    renewSubscription(sub.getId(), sub.getUserId());
                } catch (Exception e) {
                    log.error("Auto-renew failed for {}: {}", sub.getSubscriptionNo(), e.getMessage());
                    sub.setStatus("EXPIRED");
                    subscriptionRepository.save(sub);
                }
            } else {
                sub.setStatus("EXPIRED");
                subscriptionRepository.save(sub);
                log.info("Expired subscription {}", sub.getSubscriptionNo());
            }
        }
    }

    @Override
    public void sendExpiryReminders() {
        LocalDate threeDaysLater = LocalDate.now().plusDays(3);
        List<MessageBridgeSubscription> expiringSoon = subscriptionRepository
                .findByStatusAndEndDateBetween("ACTIVE", LocalDate.now(), threeDaysLater);

        for (MessageBridgeSubscription sub : expiringSoon) {
            log.info("Sending expiry reminder for subscription {} (expires {})",
                    sub.getSubscriptionNo(), sub.getEndDate());
            // Future: integrate with MessageService to send actual notification
        }
    }

    private BridgeSubscriptionResponse toResponse(MessageBridgeSubscription subscription) {
        return BridgeSubscriptionResponse.builder()
                .id(subscription.getId())
                .subscriptionNo(subscription.getSubscriptionNo())
                .supplierId(subscription.getSupplierId())
                .channelType(subscription.getChannelType())
                .status(subscription.getStatus())
                .amount(subscription.getAmount())
                .paymentId(subscription.getPaymentId())
                .startDate(subscription.getStartDate())
                .endDate(subscription.getEndDate())
                .autoRenew(subscription.getAutoRenew())
                .createdAt(subscription.getCreatedAt())
                .build();
    }

    private BridgeBindingResponse toBindingResponse(MessageBridgeBinding binding) {
        return BridgeBindingResponse.builder()
                .id(binding.getId())
                .supplierId(binding.getSupplierId())
                .channelType(binding.getChannelType())
                .channelUserId(binding.getChannelUserId())
                .channelUsername(binding.getChannelUsername())
                .bindStatus(binding.getBindStatus())
                .boundAt(binding.getBoundAt())
                .createdAt(binding.getCreatedAt())
                .build();
    }
}
