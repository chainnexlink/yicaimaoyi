package com.yicai.trade.module.messagebridge.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class MessageCreatedEvent extends ApplicationEvent {

    private static final long serialVersionUID = 1L;

    private final Long messageId;
    private final Long receiverId;

    public MessageCreatedEvent(Object source, Long messageId, Long receiverId) {
        super(source);
        this.messageId = messageId;
        this.receiverId = receiverId;
    }
}
