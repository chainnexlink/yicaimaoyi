package com.yicai.trade.module.promotion.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PromotionResponse {
    private Long id;
    private Long supplierId;
    private String title;
    private String promoType;
    private String targetType;
    private Long targetId;
    private String keywords;
    private BigDecimal bidAmount;
    private BigDecimal dailyBudget;
    private BigDecimal totalBudget;
    private BigDecimal spentAmount;
    private Long impressions;
    private Long clicks;
    private Long conversions;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String status;
    private String rejectReason;
    private LocalDateTime createdAt;
}
