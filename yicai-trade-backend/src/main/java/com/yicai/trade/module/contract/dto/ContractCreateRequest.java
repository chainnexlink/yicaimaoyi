package com.yicai.trade.module.contract.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Schema(name = "ContractCreateRequest", description = "创建合同请求")
public class ContractCreateRequest {

    @Schema(description = "关联询价单ID")
    private Long inquiryId;

    @Schema(description = "关联报价单ID")
    private Long quotationId;

    @Schema(description = "关联拍卖ID")
    private Long auctionId;

    @Schema(description = "供应商ID（平台代采时可为空或为平台ID）")
    private Long supplierId;

    @Schema(description = "合同类型: PURCHASE/SERVICE/FRAMEWORK")
    private String contractType;
    
    @Schema(description = "采购模式: PLATFORM_PROCUREMENT(平台代采)/DIRECT_PROCUREMENT(直接采购)")
    private String procurementMode;
    
    @Schema(description = "AI推荐的供应商列表（JSON格式，平台代采时使用）")
    private String recommendedSuppliers;
    
    @Schema(description = "智能匹配会话ID")
    private String smartMatchSessionId;
    
    @Schema(description = "智能匹配产品名称")
    private String smartMatchProductName;
    
    @Schema(description = "智能匹配品类代码")
    private String smartMatchCategoryCode;

    @NotBlank(message = "合同标题必填")
    @Schema(description = "合同标题")
    private String contractTitle;

    @NotNull(message = "合同金额必填")
    @Schema(description = "合同总金额")
    private BigDecimal totalAmount;

    @Schema(description = "币种，默认CNY")
    private String currency;

    @Schema(description = "合同正文内容")
    private String contractContent;

    @Schema(description = "使用的模板ID")
    private Long templateId;

    @Schema(description = "使用的模板代码（前端传入，与templateId二选一）")
    private String templateCode;

    @Schema(description = "供应商名称")
    private String supplierName;

    @Schema(description = "采购数量")
    private Integer quantity;

    @Schema(description = "计量单位")
    private String unit;

    @Schema(description = "交货地址")
    private String deliveryAddress;

    @Schema(description = "平台服务费率")
    private String serviceRate;

    @Schema(description = "合同生效日期")
    private LocalDate startDate;

    @Schema(description = "合同到期日期")
    private LocalDate endDate;

    @Schema(description = "约定交付日期")
    private LocalDate deliveryDate;

    @Schema(description = "付款条款（JSON格式）")
    private String paymentTerms;

    @Schema(description = "质量标准")
    private String qualityStandards;

    @Schema(description = "备注")
    private String remark;
}
