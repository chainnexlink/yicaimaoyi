package com.yicai.trade.module.messagebridge.gateway;

public interface MessageBridgeGateway {
    String getChannel();
    BridgeSendResult sendMessage(BridgeSendRequest request);
    boolean verifyBinding(String channelUserId, String verificationCode);
    boolean isAvailable();
}
