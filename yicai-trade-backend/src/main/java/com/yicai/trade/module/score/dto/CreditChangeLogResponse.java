package com.yicai.trade.module.score.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class CreditChangeLogResponse {
    private Long id;
    private Long supplierId;
    private String changeType;
    private String dimension;
    private BigDecimal oldScore;
    private BigDecimal newScore;
    private BigDecimal changeAmount;
    private Long relatedId;
    private String relatedType;
    private String reason;
    private LocalDateTime createdAt;
}
