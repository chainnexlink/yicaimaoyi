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
public class WechatWorkBridgeGateway implements MessageBridgeGateway {

    private final BridgeConfigRepository configRepository;

    @Override
    public String getChannel() {
        return "WECHAT_WORK";
    }

    @Override
    public BridgeSendResult sendMessage(BridgeSendRequest request) {
        // TODO: 接入企业微信API
        // 1. 从configRepository获取WECHAT_WORK_CORP_ID, WECHAT_WORK_AGENT_ID, WECHAT_WORK_SECRET
        // 2. 获取access_token (需缓存)
        // 3. 调用 https://qyapi.weixin.qq.com/cgi-bin/message/send 发送文本卡片消息
        log.warn("[WechatWork] Enterprise WeChat API not yet implemented, message not sent to {}", request.getChannelUserId());
        return BridgeSendResult.builder()
                .success(false)
                .message("Enterprise WeChat API not yet implemented")
                .build();
    }

    @Override
    public boolean verifyBinding(String channelUserId, String verificationCode) {
        // TODO: 企业微信绑定验证
        log.warn("[WechatWork] Binding verification not yet implemented");
        return false;
    }

    @Override
    public boolean isAvailable() {
        return configRepository.findByConfigKey("WECHAT_WORK_CORP_ID")
                .map(c -> !c.getConfigValue().isEmpty())
                .orElse(false);
    }
}
