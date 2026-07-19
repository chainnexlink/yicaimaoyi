package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class BridgeSubscriptionResponse {
    private Long id;
    private String subscriptionNo;
    private Long supplierId;
    private String channelType;
    private String status;
    private BigDecimal amount;
    private Long paymentId;
    private LocalDate startDate;
    private LocalDate endDate;
    private Boolean autoRenew;
    private LocalDateTime createdAt;
}
