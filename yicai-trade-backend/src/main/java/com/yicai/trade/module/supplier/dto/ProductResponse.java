package com.yicai.trade.module.supplier.dto;

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
public class ProductResponse {
    private Long id;
    private Long supplierId;
    private String productName;
    private String category;
    private String description;
    private BigDecimal price;
    private String unit;
    private Integer minOrderQty;
    private String imageUrl;
    private String status;
    private LocalDateTime createdAt;
}
