package com.yicai.trade.module.wallet.dto;

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
public class CommissionResponse {

    private Long id;
    private String commissionNo;
    private Long contractId;
    private String contractNo;
    private Long buyerId;
    private Long supplierId;
    private BigDecimal contractAmount;
    private BigDecimal platformRate;
    private BigDecimal platformFee;
    private BigDecimal rebateRate;
    private BigDecimal rebateAmount;
    private BigDecimal totalServiceFee;
    private String status;
    private String statusDisplay;
    private LocalDateTime collectedAt;
    private LocalDateTime rebatedAt;
    private String remark;
    private LocalDateTime createdAt;
}
