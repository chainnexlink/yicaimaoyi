package com.yicai.trade.module.product.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class ProductRequest {
    @NotBlank(message = "产品名称不能为空")
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
}
