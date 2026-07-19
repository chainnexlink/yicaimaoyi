package com.yicai.trade.module.contract.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "合同详情响应")
public class ContractResponse {

    private Long id;
    private String contractNo;
    private Long inquiryId;
    private Long quotationId;
    private Long auctionId;
    private Long buyerId;
    private Long supplierId;

    private String contractType;
    private String contractTitle;
    private BigDecimal totalAmount;
    private String currency;
    
    // 采购模式相关
    @Schema(description = "采购模式: PLATFORM_PROCUREMENT(平台代采)/DIRECT_PROCUREMENT(直接采购)")
    private String procurementMode;
    
    @Schema(description = "采购模式显示名称")
    private String procurementModeDisplay;
    
    @Schema(description = "AI推荐的供应商列表（JSON）")
    private String recommendedSuppliers;
    
    @Schema(description = "智能匹配会话ID")
    private String smartMatchSessionId;
    
    @Schema(description = "智能匹配产品名称")
    private String smartMatchProductName;
    
    @Schema(description = "智能匹配品类代码")
    private String smartMatchCategoryCode;

    private String contractContent;
    private Long templateId;

    // 签署状态
    private String status;
    private Boolean buyerSigned;
    private LocalDateTime buyerSignedAt;
    private Boolean supplierSigned;
    private LocalDateTime supplierSignedAt;

    // 履约信息
    private LocalDate startDate;
    private LocalDate endDate;
    private LocalDate deliveryDate;
    private String paymentTerms;
    private String qualityStandards;

    // 文件
    private String contractPdfUrl;

    // 关联订单
    private Long orderId;

    // 平台监管
    private Boolean platformReviewed;
    private Long platformReviewerId;
    private LocalDateTime platformReviewedAt;
    private String platformReviewNote;

    private String remark;

    // 纸质合同审核
    private String physicalContractUrl;
    private LocalDateTime physicalContractUploadedAt;
    private String contractReviewStatus;
    private Long contractReviewedBy;
    private LocalDateTime contractReviewedAt;
    private String contractReviewNote;

    // 变更记录
    private List<ChangeLogResponse> changeLogs;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChangeLogResponse {
        private Long id;
        private String changeType;
        private String changeReason;
        private String initiatorType;
        private Long initiatorId;
        private String initiatorName;
        private String status;
        private String approvalNote;
        private LocalDateTime approvedAt;
        private LocalDateTime createdAt;
    }
}
