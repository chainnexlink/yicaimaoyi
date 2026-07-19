package com.yicai.trade.module.messagebridge.service.impl;

import com.yicai.trade.module.message.entity.Message;
import com.yicai.trade.module.message.repository.MessageRepository;
import com.yicai.trade.module.messagebridge.dto.BridgeLogResponse;
import com.yicai.trade.module.messagebridge.dto.BridgeStatsResponse;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeBinding;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeLog;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeSubscription;
import com.yicai.trade.module.messagebridge.gateway.BridgeGatewayFactory;
import com.yicai.trade.module.messagebridge.gateway.BridgeSendRequest;
import com.yicai.trade.module.messagebridge.gateway.BridgeSendResult;
import com.yicai.trade.module.messagebridge.gateway.MessageBridgeGateway;
import com.yicai.trade.module.messagebridge.repository.BridgeBindingRepository;
import com.yicai.trade.module.messagebridge.repository.BridgeLogRepository;
import com.yicai.trade.module.messagebridge.repository.BridgeSubscriptionRepository;
import com.yicai.trade.module.messagebridge.service.BridgeForwardingService;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
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
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class BridgeForwardingServiceImpl implements BridgeForwardingService {

    private final MessageRepository messageRepository;
    private final SupplierRepository supplierRepository;
    private final BridgeSubscriptionRepository subscriptionRepository;
    private final BridgeBindingRepository bindingRepository;
    private final BridgeLogRepository logRepository;
    private final BridgeGatewayFactory gatewayFactory;

    @Override
    @Transactional
    public void forwardMessage(Long messageId) {
        Optional<Message> messageOpt = messageRepository.findById(messageId);
        if (messageOpt.isEmpty()) {
            log.warn("Message {} not found, skipping forward", messageId);
            return;
        }

        Message message = messageOpt.get();
        Long receiverId = message.getReceiverId();
        if (receiverId == null) {
            return;
        }

        // Find supplier by userId
        Optional<Supplier> supplierOpt = supplierRepository.findByUserId(receiverId);
        if (supplierOpt.isEmpty()) {
            return;
        }

        Supplier supplier = supplierOpt.get();
        Long supplierId = supplier.getId();

        // Get all bound channels for this supplier
        List<MessageBridgeBinding> bindings = bindingRepository.findBySupplierId(supplierId);
        List<MessageBridgeBinding> boundBindings = bindings.stream()
                .filter(b -> "BOUND".equals(b.getBindStatus()))
                .collect(Collectors.toList());

        if (boundBindings.isEmpty()) {
            return;
        }

        for (MessageBridgeBinding binding : boundBindings) {
            String channelType = binding.getChannelType();

            // Check if supplier has active subscription for this channel
            List<MessageBridgeSubscription> activeSubs = subscriptionRepository
                    .findActiveSubscription(supplierId, channelType, LocalDate.now());
            if (activeSubs.isEmpty()) {
                log.debug("No active subscription for supplier {} on channel {}", supplierId, channelType);
                continue;
            }

            // Build and send message
            MessageBridgeGateway gateway = gatewayFactory.getGateway(channelType);
            BridgeSendRequest sendRequest = BridgeSendRequest.builder()
                    .channelUserId(binding.getChannelUserId())
                    .title(message.getTitle())
                    .content(message.getContent())
                    .messageType(message.getType())
                    .relatedId(message.getRelatedId())
                    .relatedType(message.getRelatedType())
                    .build();

            BridgeSendResult result = gateway.sendMessage(sendRequest);

            // Log the forwarding result
            String contentSummary = message.getTitle();
            if (contentSummary != null && contentSummary.length() > 200) {
                contentSummary = contentSummary.substring(0, 200);
            }

            @lombok.NonNull MessageBridgeLog bridgeLog = MessageBridgeLog.builder()
                    .messageId(messageId)
                    .supplierId(supplierId)
                    .channelType(channelType)
                    .direction("OUTBOUND")
                    .contentSummary(contentSummary)
                    .externalMsgId(result.getExternalMsgId())
                    .status(result.isSuccess() ? "SUCCESS" : "FAILED")
                    .errorMessage(result.isSuccess() ? null : result.getMessage())
                    .build();

            logRepository.save(bridgeLog);

            if (result.isSuccess()) {
                log.info("Forwarded message {} to supplier {} via {}", messageId, supplierId, channelType);
            } else {
                log.warn("Failed to forward message {} to supplier {} via {}: {}",
                        messageId, supplierId, channelType, result.getMessage());
            }
        }
    }

    @Override
    @Transactional
    public void receiveExternalMessage(String channelType, String channelUserId, String content) {
        // Find binding by channel info
        Optional<MessageBridgeBinding> bindingOpt = bindingRepository
                .findByChannelTypeAndChannelUserId(channelType, channelUserId);

        if (bindingOpt.isEmpty()) {
            log.warn("No binding found for channel {} user {}", channelType, channelUserId);
            return;
        }

        MessageBridgeBinding binding = bindingOpt.get();

        String contentSummary = content;
        if (contentSummary != null && contentSummary.length() > 200) {
            contentSummary = contentSummary.substring(0, 200);
        }

        @lombok.NonNull MessageBridgeLog bridgeLog = MessageBridgeLog.builder()
                .supplierId(binding.getSupplierId())
                .channelType(channelType)
                .direction("INBOUND")
                .contentSummary(contentSummary)
                .status("SUCCESS")
                .build();

        logRepository.save(bridgeLog);
        log.info("Received external message from channel {} user {}", channelType, channelUserId);
    }

    @Override
    public List<BridgeLogResponse> getSupplierLogs(Long supplierId, int page, int size) {
        Page<MessageBridgeLog> pageResult = logRepository.findBySupplierId(
                supplierId, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return pageResult.getContent().stream().map(this::toLogResponse).collect(Collectors.toList());
    }

    @Override
    public List<BridgeLogResponse> getAllLogs(int page, int size) {
        Page<MessageBridgeLog> pageResult = logRepository.findAll(
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return pageResult.getContent().stream().map(this::toLogResponse).collect(Collectors.toList());
    }

    @Override
    public BridgeStatsResponse getStats() {
        long activeSubscriptions = subscriptionRepository.countByStatus("ACTIVE");
        long totalSubscriptions = subscriptionRepository.count();
        BigDecimal totalRevenue = subscriptionRepository.sumTotalRevenue();

        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        long todayForwards = logRepository.countByCreatedAtAfter(todayStart);
        long totalForwards = logRepository.count();
        long boundUsers = bindingRepository.countByBindStatus("BOUND");

        long successCount = logRepository.countByStatus("SUCCESS");
        long failedCount = logRepository.countByStatus("FAILED");

        long wechatForwards = logRepository.countByChannelType("WECHAT_WORK");
        long qqForwards = logRepository.countByChannelType("QQ_BOT");

        return BridgeStatsResponse.builder()
                .activeSubscriptions(activeSubscriptions)
                .totalSubscriptions(totalSubscriptions)
                .totalRevenue(totalRevenue)
                .todayForwards(todayForwards)
                .totalForwards(totalForwards)
                .boundUsers(boundUsers)
                .wechatForwards(wechatForwards)
                .qqForwards(qqForwards)
                .successCount(successCount)
                .failedCount(failedCount)
                .build();
    }

    private BridgeLogResponse toLogResponse(MessageBridgeLog logEntry) {
        return BridgeLogResponse.builder()
                .id(logEntry.getId())
                .messageId(logEntry.getMessageId())
                .supplierId(logEntry.getSupplierId())
                .channelType(logEntry.getChannelType())
                .direction(logEntry.getDirection())
                .contentSummary(logEntry.getContentSummary())
                .externalMsgId(logEntry.getExternalMsgId())
                .status(logEntry.getStatus())
                .errorMessage(logEntry.getErrorMessage())
                .createdAt(logEntry.getCreatedAt())
                .build();
    }
}
