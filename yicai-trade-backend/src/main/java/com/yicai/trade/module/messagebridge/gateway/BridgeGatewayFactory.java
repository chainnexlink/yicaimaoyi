package com.yicai.trade.module.messagebridge.gateway;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Slf4j
@Component
public class BridgeGatewayFactory {

    private final Map<String, MessageBridgeGateway> gatewayMap;
    private final MessageBridgeGateway defaultGateway;

    public BridgeGatewayFactory(List<MessageBridgeGateway> gateways) {
        this.gatewayMap = gateways.stream()
                .collect(Collectors.toMap(MessageBridgeGateway::getChannel, Function.identity()));
        this.defaultGateway = gatewayMap.getOrDefault("MOCK", gateways.get(0));
        log.info("Initialized BridgeGatewayFactory with {} gateways: {}", gateways.size(), gatewayMap.keySet());
    }

    public MessageBridgeGateway getGateway(String channelType) {
        MessageBridgeGateway gateway = gatewayMap.get(channelType);
        if (gateway == null || !gateway.isAvailable()) {
            log.warn("Gateway for channel {} not available, falling back to default", channelType);
            return defaultGateway;
        }
        return gateway;
    }
}
