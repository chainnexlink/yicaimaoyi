package com.yicai.trade.module.demand.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class DemandRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String description;
    private String categoryCode;
    private String categoryName;
    private Integer quantity;
    private String unit;
    private BigDecimal budget;
    private Integer expectedDeliveryDays;
}
