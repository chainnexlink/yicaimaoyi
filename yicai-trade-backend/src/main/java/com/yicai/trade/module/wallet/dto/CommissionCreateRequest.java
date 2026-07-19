package com.yicai.trade.module.wallet.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CommissionCreateRequest {

    @NotNull(message = "合同ID不能为空")
    private Long contractId;

    /** 客户自定义返佣比例，1%-10%，传入小数形式如 0.05 表示5% */
    @NotNull(message = "返佣比例不能为空")
    @DecimalMin(value = "0.01", message = "返佣比例最低1%")
    @DecimalMax(value = "0.10", message = "返佣比例最高10%")
    private BigDecimal rebateRate;
}
