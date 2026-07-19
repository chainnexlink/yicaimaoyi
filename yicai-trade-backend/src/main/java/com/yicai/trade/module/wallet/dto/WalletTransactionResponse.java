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
public class WalletTransactionResponse {

    private Long id;
    private String transactionNo;
    private Long walletId;
    private Long ownerId;
    private String ownerType;
    private String transactionType;
    private String transactionTypeDisplay;
    private BigDecimal amount;
    private BigDecimal balanceBefore;
    private BigDecimal balanceAfter;
    private Long contractId;
    private String contractNo;
    private Long commissionId;
    private String description;
    private LocalDateTime createdAt;
}
