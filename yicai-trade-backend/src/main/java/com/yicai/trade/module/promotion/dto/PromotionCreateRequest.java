package com.yicai.trade.module.promotion.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PromotionCreateRequest {
    private Long supplierId;
    private String title;
    private String promoType;
    private String targetType;
    private Long targetId;
    private String keywords;
    private BigDecimal bidAmount;
    private BigDecimal dailyBudget;
    private BigDecimal totalBudget;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}
