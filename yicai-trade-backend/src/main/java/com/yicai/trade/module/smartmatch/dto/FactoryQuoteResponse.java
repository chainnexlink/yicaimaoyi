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
public class FactoryQuoteResponse {

    private String sessionId;
    private QuoteBreakdown quoteBreakdown;
    private List<SupplierQuote> supplierQuotes;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuoteBreakdown {
        private BigDecimal costPrice;               // 出厂成本
        private BigDecimal industryProfitMarginLow; // 行业利润率下限(%)
        private BigDecimal industryProfitMarginHigh;// 行业利润率上限(%)
        private BigDecimal factoryQuoteLow;         // 工厂报价下限
        private BigDecimal factoryQuoteHigh;        // 工厂报价上限
        private BigDecimal platformPriceLow;        // 同平台参考最低价(来自第三步)
        private BigDecimal platformPriceHigh;       // 同平台参考最高价(来自第三步)
        private String currency;
        private String unit;
        private String industryReferenceNote;       // 行业参考说明
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SupplierQuote {
        private String supplierCode;
        private String factoryName;
        private String city;
        private String industrialBelt;          // 产业带
        private String mainProducts;            // 主营产品
        private Integer matchScore;             // 匹配分数 0-100
        private String matchReason;             // 匹配原因(AI分析)
        private BigDecimal estimatedCostPrice;  // 预估出厂成本
        private BigDecimal quoteLow;
        private BigDecimal quoteHigh;
        private String quoteReason;             // 报价说明
    }
}
