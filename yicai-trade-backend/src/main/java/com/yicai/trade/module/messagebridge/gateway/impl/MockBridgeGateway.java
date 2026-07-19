package com.yicai.trade.module.messagebridge.gateway.impl;

import com.yicai.trade.module.messagebridge.gateway.BridgeSendRequest;
import com.yicai.trade.module.messagebridge.gateway.BridgeSendResult;
import com.yicai.trade.module.messagebridge.gateway.MessageBridgeGateway;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Primary
@Component
public class MockBridgeGateway implements MessageBridgeGateway {

    @Override
    public String getChannel() {
        return "MOCK";
    }

    @Override
    public BridgeSendResult sendMessage(BridgeSendRequest request) {
        log.info("[MockBridge] Sending message to {}: title={}, type={}", 
                request.getChannelUserId(), request.getTitle(), request.getMessageType());
        return BridgeSendResult.builder()
                .success(true)
                .externalMsgId("MOCK-" + UUID.randomUUID().toString().substring(0, 8))
                .message("Mock message sent successfully")
                .build();
    }

    @Override
    public boolean verifyBinding(String channelUserId, String verificationCode) {
        log.info("[MockBridge] Verifying binding for user {}, code={}", channelUserId, verificationCode);
        return true;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }
}
