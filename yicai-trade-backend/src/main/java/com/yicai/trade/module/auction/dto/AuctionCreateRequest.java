package com.yicai.trade.module.auction.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 创建拍卖请求
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuctionCreateRequest {

    /** 拍卖类型: REVERSE_AUCTION(反向拍卖), TENDER(招标), INQUIRY(询比价) */
    @Pattern(regexp = "REVERSE_AUCTION|TENDER|INQUIRY", message = "竞价类型无效")
    private String auctionType;

    /** 币种: CNY/USD/EUR/GBP */
    @Pattern(regexp = "CNY|USD|EUR|GBP|JPY|CAD|AUD", message = "报价币种无效")
    private String currency;

    /** 产品名称 */
    @NotBlank(message = "产品名称不能为空")
    @Size(max = 200, message = "产品名称不能超过200个字符")
    private String productName;

    /** 产品分类 */
    @Size(max = 100, message = "产品分类不能超过100个字符")
    private String productCategory;

    /** 产品规格描述 */
    @NotBlank(message = "产品规格说明不能为空")
    @Size(max = 2000, message = "产品规格说明不能超过2000个字符")
    private String specification;

    /** 采购数量 */
    @NotNull(message = "采购数量不能为空")
    @Min(value = 1, message = "采购数量必须大于0")
    private Integer quantity;

    /** 数量单位 */
    @Size(max = 20, message = "数量单位不能超过20个字符")
    private String unit;

    /** 起拍价/最高限价 */
    @NotNull(message = "最高单价不能为空")
    @DecimalMin(value = "0.00", inclusive = false, message = "最高单价必须大于0")
    private BigDecimal startingPrice;

    /** 最低降价幅度 */
    @DecimalMin(value = "0.00", inclusive = false, message = "最低降价幅度必须大于0")
    private BigDecimal minDecrement;

    /** 底价（隐藏），低于此价不接受 */
    private BigDecimal reservePrice;

    /** 是否公开底价 */
    private Boolean showReservePrice;

    /** 是否仅邀请制 */
    private Boolean inviteOnly;

    /** 出价冷却时间（秒） */
    private Integer bidCooldownSeconds;

    // ========== 报名时间 ==========
    
    /** 报名开始时间 */
    private LocalDateTime signupStartTime;

    /** 报名结束时间 */
    private LocalDateTime signupEndTime;

    // ========== 竞价时间 ==========

    /** 拍卖开始时间 */
    @NotNull(message = "竞价开始时间不能为空")
    private LocalDateTime startTime;

    /** 拍卖结束时间 */
    @NotNull(message = "竞价结束时间不能为空")
    private LocalDateTime endTime;

    // ========== 反拍规则 ==========

    /** 最少参与供应商数量(不足则流标) */
    @Min(value = 1, message = "最少参与供应商不能少于1家")
    @Max(value = 100, message = "最少参与供应商不能超过100家")
    private Integer minParticipants;

    /** 延时分钟数 */
    @Min(value = 1, message = "延时时长不能少于1分钟")
    @Max(value = 60, message = "延时时长不能超过60分钟")
    private Integer extensionMinutes;

    /** 触发延时的剩余时间(分钟) */
    @Min(value = 1, message = "延时触发时间不能少于1分钟")
    @Max(value = 60, message = "延时触发时间不能超过60分钟")
    private Integer extensionTriggerMinutes;

    /** 最大延时次数 */
    @Min(value = 0, message = "最大延时次数不能小于0")
    @Max(value = 100, message = "最大延时次数不能超过100")
    private Integer maxExtensions;

    /** 是否允许供应商查看排名 */
    private Boolean showRanking;

    /** 是否允许供应商查看最低价 */
    private Boolean showLowestPrice;

    // ========== 综合评分 ==========

    /** 是否启用综合评分 */
    private Boolean scoringEnabled;

    /** 价格权重（百分比） */
    private Integer priceWeight;

    /** 交期权重 */
    private Integer deliveryWeight;

    /** 质量权重 */
    private Integer qualityWeight;

    /** 服务权重 */
    private Integer serviceWeight;

    // ========== 交付信息 ==========

    /** 交货地址 */
    @Size(max = 500, message = "交货地址不能超过500个字符")
    private String deliveryAddress;

    /** 要求交货日期 */
    private LocalDate requiredDeliveryDate;

    /** 付款方式说明 */
    @Size(max = 500, message = "付款方式说明不能超过500个字符")
    private String paymentTerms;

    /** 备注 */
    @Size(max = 1000, message = "备注不能超过1000个字符")
    private String remark;

    /** 封面图片URL */
    private String coverImage;

    /** 附件URLs(JSON数组) */
    private String attachments;

    /** 被邀请的供应商ID列表（邀请制时使用） */
    private List<Long> inviteSupplierIds;
}
