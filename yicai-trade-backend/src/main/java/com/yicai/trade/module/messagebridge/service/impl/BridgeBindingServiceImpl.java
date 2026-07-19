package com.yicai.trade.module.messagebridge.service.impl;

import com.yicai.trade.module.messagebridge.dto.BridgeBindingRequest;
import com.yicai.trade.module.messagebridge.dto.BridgeBindingResponse;
import com.yicai.trade.module.messagebridge.entity.MessageBridgeBinding;
import com.yicai.trade.module.messagebridge.gateway.BridgeGatewayFactory;
import com.yicai.trade.module.messagebridge.gateway.MessageBridgeGateway;
import com.yicai.trade.module.messagebridge.repository.BridgeBindingRepository;
import com.yicai.trade.module.messagebridge.service.BridgeBindingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class BridgeBindingServiceImpl implements BridgeBindingService {

    private final BridgeBindingRepository bindingRepository;
    private final BridgeGatewayFactory gatewayFactory;

    @Override
    @Transactional
    public BridgeBindingResponse bind(Long userId, Long supplierId, BridgeBindingRequest request) {
        // Check if binding already exists
        bindingRepository.findBySupplierIdAndChannelType(supplierId, request.getChannelType())
                .ifPresent(existing -> {
                    if ("BOUND".equals(existing.getBindStatus())) {
                        throw new RuntimeException("该渠道已绑定，请先解绑后再重新绑定");
                    }
                });

        String verificationCode = UUID.randomUUID().toString().substring(0, 6).toUpperCase();

        @lombok.NonNull MessageBridgeBinding binding = MessageBridgeBinding.builder()
                .supplierId(supplierId)
                .userId(userId)
                .channelType(request.getChannelType())
                .channelUserId(request.getChannelUserId())
                .channelUsername(request.getChannelUsername())
                .bindStatus("PENDING")
                .verificationCode(verificationCode)
                .verificationExpire(LocalDateTime.now().plusMinutes(30))
                .build();

        binding = bindingRepository.save(binding);
        log.info("Created binding for supplier {} on channel {}, verification code: {}",
                supplierId, request.getChannelType(), verificationCode);
        return toResponse(binding);
    }

    @Override
    @Transactional
    public BridgeBindingResponse verify(Long userId, String channelType, String verificationCode) {
        // Find binding by user's supplier bindings
        List<MessageBridgeBinding> bindings = bindingRepository.findBySupplierId(userId);
        MessageBridgeBinding binding = bindings.stream()
                .filter(b -> b.getChannelType().equals(channelType) && "PENDING".equals(b.getBindStatus()))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("未找到待验证的绑定记录"));

        if (binding.getVerificationExpire() != null && binding.getVerificationExpire().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("验证码已过期，请重新绑定");
        }

        if (!verificationCode.equals(binding.getVerificationCode())) {
            // Also try gateway-level verification
            MessageBridgeGateway gateway = gatewayFactory.getGateway(channelType);
            if (!gateway.verifyBinding(binding.getChannelUserId(), verificationCode)) {
                throw new RuntimeException("验证码不正确");
            }
        }

        binding.setBindStatus("BOUND");
        binding.setBoundAt(LocalDateTime.now());
        binding.setVerificationCode(null);
        binding.setVerificationExpire(null);
        binding = bindingRepository.save(binding);

        log.info("Verified binding for supplier {} on channel {}", binding.getSupplierId(), channelType);
        return toResponse(binding);
    }

    @Override
    @Transactional
    public void unbind(Long userId, String channelType) {
        List<MessageBridgeBinding> bindings = bindingRepository.findBySupplierId(userId);
        MessageBridgeBinding binding = bindings.stream()
                .filter(b -> b.getChannelType().equals(channelType))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("未找到该渠道的绑定记录"));

        binding.setBindStatus("REVOKED");
        binding.setChannelUserId(null);
        binding.setChannelUsername(null);
        bindingRepository.save(binding);
        log.info("Unbound channel {} for supplier {}", channelType, binding.getSupplierId());
    }

    @Override
    public List<BridgeBindingResponse> getBindings(Long supplierId) {
        return bindingRepository.findBySupplierId(supplierId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public BridgeBindingResponse getBinding(Long supplierId, String channelType) {
        MessageBridgeBinding binding = bindingRepository.findBySupplierIdAndChannelType(supplierId, channelType)
                .orElseThrow(() -> new RuntimeException("未找到该渠道的绑定记录"));
        return toResponse(binding);
    }

    private BridgeBindingResponse toResponse(MessageBridgeBinding binding) {
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
