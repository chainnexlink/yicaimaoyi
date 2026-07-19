package com.yicai.trade.module.messagebridge.event;

import com.yicai.trade.module.messagebridge.service.BridgeForwardingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class BridgeEventListener {

    private final BridgeForwardingService bridgeForwardingService;

    @Async
    @EventListener
    public void onMessageCreated(MessageCreatedEvent event) {
        try {
            log.debug("Received MessageCreatedEvent: messageId={}, receiverId={}", 
                    event.getMessageId(), event.getReceiverId());
            bridgeForwardingService.forwardMessage(event.getMessageId());
        } catch (Exception e) {
            log.error("Error forwarding message {}: {}", event.getMessageId(), e.getMessage(), e);
        }
    }
}
