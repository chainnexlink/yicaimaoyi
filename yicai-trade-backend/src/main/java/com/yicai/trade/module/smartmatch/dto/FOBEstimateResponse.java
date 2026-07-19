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
public class FOBEstimateResponse {
    
    private String sessionId;
    private String supplierCode;
    private FOBBreakdown fobBreakdown;
    private List<SupplierFOB> supplierFOBPrices;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FOBBreakdown {
        private BigDecimal costPrice;
        private BigDecimal domesticFreight;
        private BigDecimal portCharges;
        private BigDecimal customsClearance;
        private BigDecimal exportTaxRebate;
        private BigDecimal fobPrice;
        private String currency;
        private String unit;
        private String fromCity;
        private String toPort;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SupplierFOB {
        private String supplierCode;
        private String factoryName;
        private String city;
        private BigDecimal fobPrice;
        private BigDecimal domesticFreight;
        private String estimatedDeliveryDays;
    }
}
