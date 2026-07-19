package com.yicai.trade.module.score.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class SupplierCreditResponse {
    private Long id;
    private Long supplierId;
    private BigDecimal creditScore;
    private String creditLevel;
    private BigDecimal deliveryScore;
    private BigDecimal qualityScore;
    private BigDecimal serviceScore;
    private BigDecimal disputeScore;
    private Integer totalOrders;
    private Integer completedOrders;
    private Integer onTimeDeliveries;
    private Integer lateDeliveries;
    private Integer qualityPassCount;
    private Integer qualityFailCount;
    private Integer totalDisputes;
    private Integer lostDisputes;
    private Integer totalAftersales;
    private BigDecimal avgResponseHours;
    private BigDecimal avgBuyerRating;
    private Integer totalReviews;
    // Computed rates
    private String onTimeRate;
    private String qualityRate;
    private String disputeLoseRate;
    private LocalDateTime lastCalculatedAt;
}
