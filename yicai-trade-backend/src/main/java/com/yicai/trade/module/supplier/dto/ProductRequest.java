package com.yicai.trade.module.supplier.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NonNull;

import java.math.BigDecimal;

@Data
@Schema(name = "ProductRequest")
public class ProductRequest {
    @NonNull
    @NotBlank(message = "productName required")
    @Schema(description = "productName")
    private String productName;
    private String category;
    private String description;
    private BigDecimal price;
    private String unit;
    private Integer minOrderQty;
    private String imageUrl;
}
