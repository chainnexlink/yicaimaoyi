package com.yicai.trade.module.payment.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.math.BigDecimal;

@Getter
public class PaymentSuccessEvent extends ApplicationEvent {
    private static final long serialVersionUID = 1L;

    private final Long paymentId;
    private final Long orderId;
    private final Long payerId;
    private final BigDecimal amount;

    public PaymentSuccessEvent(Object source, Long paymentId, Long orderId, Long payerId, BigDecimal amount) {
        super(source);
        this.paymentId = paymentId;
        this.orderId = orderId;
        this.payerId = payerId;
        this.amount = amount;
    }
}
