package com.yicai.trade.module.payment.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class RefundResponse {
    
    private Long id;
    private String refundNo;
    private Long paymentId;
    private String paymentNo;
    private Long orderId;
    private String orderNo;
    private Long applicantId;
    private String applicantName;
    private BigDecimal refundAmount;
    private String refundReason;
    private String refundType;
    private String status;
    private Long auditorId;
    private String auditorName;
    private String auditRemark;
    private LocalDateTime auditedAt;
    private String transactionId;
    private LocalDateTime refundedAt;
    private LocalDateTime createdAt;
}
