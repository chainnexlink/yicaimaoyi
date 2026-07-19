package com.yicai.trade.module.inquiry.dto;

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
public class QuotationResponse {
    private Long id;
    private Long inquiryId;
    private Long supplierId;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;
    private Integer deliveryDays;
    private String description;
    private String status;
    private LocalDateTime createdAt;
}
