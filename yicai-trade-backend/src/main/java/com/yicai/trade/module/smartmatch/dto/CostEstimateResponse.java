package com.yicai.trade.module.smartmatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CostEstimateResponse {
    
    private String sessionId;
    private CostBreakdown costBreakdown;
    private List<SupplierMatch> suggestedSuppliers;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CostBreakdown {
        private BigDecimal materialCost;
        private BigDecimal processingCost;
        private BigDecimal wasteCost;
        private BigDecimal packagingCost;
        private BigDecimal totalCost;
        private String currency;
        private String unit;
        private String alibabaReferenceNote; // 阿里巴巴参考价格说明
        private BigDecimal platformPriceLow;  // 同平台参考最低价
        private BigDecimal platformPriceHigh; // 同平台参考最高价
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SupplierMatch {
        private String factoryName;
        private String city;
        private String industrialBelt;
        private String mainProducts;
        private Integer matchScore;
        private String matchReason;
        private BigDecimal estimatedCostPrice;
        private String supplierCode;
    }
}
