package com.yicai.trade.module.order.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EscrowResponse {
    private Long id;
    private String escrowNo;
    private Long orderId;
    private String orderNo;
    private Long buyerId;
    private Long supplierId;
    private BigDecimal orderAmount;
    private BigDecimal escrowAmount;
    private BigDecimal commissionAmount;
    private BigDecimal rebateAmount;
    private String status;
    private String statusText;
    private Integer releaseDays;
    private LocalDateTime autoReleaseAt;
    private LocalDateTime releasedAt;
    private String earlyReleaseReason;
    private LocalDateTime earlyReleaseRequestedAt;
    private Long approvedBy;
    private String approvalRemark;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
