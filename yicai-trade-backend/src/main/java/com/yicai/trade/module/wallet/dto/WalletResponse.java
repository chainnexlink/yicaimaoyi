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
public class WalletResponse {

    private Long id;
    private Long ownerId;
    private String ownerType;
    private BigDecimal balance;
    private BigDecimal frozenAmount;
    private BigDecimal availableBalance;
    private BigDecimal totalIncome;
    private BigDecimal totalExpense;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
