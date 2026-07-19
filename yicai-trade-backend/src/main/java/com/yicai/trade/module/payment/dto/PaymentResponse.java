package com.yicai.trade.module.payment.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentResponse {
    
    private Long id;
    private String paymentNo;
    private Long orderId;
    private String orderNo;
    private Long payerId;
    private String payerName;
    private Long payeeId;
    private String payeeName;
    private BigDecimal amount;
    private String currency;
    private String paymentMethod;
    private String paymentChannel;
    private String status;
    private String transactionId;
    private String bankAccount;
    private String bankName;
    private String remark;
    private LocalDateTime paidAt;
    private LocalDateTime expiredAt;
    private LocalDateTime createdAt;
}
