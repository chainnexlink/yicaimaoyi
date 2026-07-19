package com.yicai.trade.module.order.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

/**
 * 订单状态变更事件
 * 当订单状态发生变化时由OrderService发布，其他模块（如拍卖模块）可以监听此事件进行状态同步。
 */
@Getter
public class OrderStatusChangedEvent extends ApplicationEvent {
    private static final long serialVersionUID = 1L;

    private final Long orderId;
    private final String fromStatus;
    private final String toStatus;
    private final Long operatorId;

    public OrderStatusChangedEvent(Object source, Long orderId, String fromStatus, String toStatus, Long operatorId) {
        super(source);
        this.orderId = orderId;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.operatorId = operatorId;
    }
}
