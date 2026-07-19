package com.yicai.trade.module.payment.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.math.BigDecimal;

@Getter
public class RefundSuccessEvent extends ApplicationEvent {
    private static final long serialVersionUID = 1L;

    private final Long refundId;
    private final Long orderId;
    private final Long applicantId;
    private final BigDecimal refundAmount;

    public RefundSuccessEvent(Object source, Long refundId, Long orderId, Long applicantId, BigDecimal refundAmount) {
        super(source);
        this.refundId = refundId;
        this.orderId = orderId;
        this.applicantId = applicantId;
        this.refundAmount = refundAmount;
    }
}
