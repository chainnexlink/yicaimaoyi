package com.yicai.trade.module.auction.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 出价请求
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BidRequest {

    /** 拍卖ID */
    @NotNull(message = "竞价ID不能为空")
    private Long auctionId;

    /** 出价金额(单价) */
    @NotNull(message = "出价金额不能为空")
    @DecimalMin(value = "0.00", inclusive = false, message = "出价金额必须大于0")
    private BigDecimal bidPrice;

    /** 承诺交货天数（综合评分模式下使用） */
    @Min(value = 1, message = "承诺交货天数不能少于1天")
    @Max(value = 3650, message = "承诺交货天数不能超过3650天")
    private Integer promisedDeliveryDays;

    /** 供应商备注 */
    @Size(max = 500, message = "供应商备注不能超过500个字符")
    private String remark;
}
