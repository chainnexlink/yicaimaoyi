package com.yicai.trade.module.messagebridge.gateway.impl;

import com.yicai.trade.module.messagebridge.gateway.BridgeSendRequest;
import com.yicai.trade.module.messagebridge.gateway.BridgeSendResult;
import com.yicai.trade.module.messagebridge.gateway.MessageBridgeGateway;
import com.yicai.trade.module.messagebridge.repository.BridgeConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class QQBotBridgeGateway implements MessageBridgeGateway {

    private final BridgeConfigRepository configRepository;

    @Override
    public String getChannel() {
        return "QQ_BOT";
    }

    @Override
    public BridgeSendResult sendMessage(BridgeSendRequest request) {
        // TODO: 接入QQ Bot API
        // 1. 从configRepository获取QQ_BOT_APP_ID, QQ_BOT_TOKEN
        // 2. 鉴权获取access_token
        // 3. 调用QQ Bot消息发送API
        log.warn("[QQBot] QQ Bot API not yet implemented, message not sent to {}", request.getChannelUserId());
        return BridgeSendResult.builder()
                .success(false)
                .message("QQ Bot API not yet implemented")
                .build();
    }

    @Override
    public boolean verifyBinding(String channelUserId, String verificationCode) {
        // TODO: QQ Bot绑定验证
        log.warn("[QQBot] Binding verification not yet implemented");
        return false;
    }

    @Override
    public boolean isAvailable() {
        return configRepository.findByConfigKey("QQ_BOT_APP_ID")
                .map(c -> !c.getConfigValue().isEmpty())
                .orElse(false);
    }
}
