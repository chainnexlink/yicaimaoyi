package com.yicai.trade.module.product.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ProductResponse {
    private Long id;
    private String productNo;
    private String name;
    private Long supplierId;
    private String supplierName;
    private String category;
    private BigDecimal price;
    private Integer minOrderQuantity;
    private String unit;
    private Integer stock;
    private String description;
    private String imageUrl;
    private String auditStatus;
    private String auditRemark;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
