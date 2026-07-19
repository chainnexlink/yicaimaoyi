package com.yicai.trade.module.inquiry.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.NonNull;

import java.math.BigDecimal;

@Data
public class QuotationCreateRequest {
    @NonNull
    @NotNull
    private Long inquiryId;
    
    @NonNull
    @NotNull
    private BigDecimal unitPrice;
    
    @NonNull
    @NotNull
    private BigDecimal totalPrice;
    
    private Integer deliveryDays;
    
    private String description;
}
