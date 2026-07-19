package com.yicai.trade.module.contract.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_contract")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Contract {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "contract_no", nullable = false, unique = true, length = 50)
    private String contractNo;

    @Column(name = "inquiry_id")
    private Long inquiryId;

    @Column(name = "quotation_id")
    private Long quotationId;

    @Column(name = "auction_id")
    private Long auctionId;

    @NonNull
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @NonNull
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    // 合同基本信息
    @NonNull
    @Column(name = "contract_type", length = 20)
    @Builder.Default
    private String contractType = "PURCHASE";  // PURCHASE, SERVICE, FRAMEWORK
    
    /**
     * 采购模式：
     * - PLATFORM_PROCUREMENT: 平台代采（供应商未入驻，与平台签约）
     * - DIRECT_PROCUREMENT: 直接采购（供应商已入驻，直接签约）
     */
    @Column(name = "procurement_mode", length = 30)
    @Builder.Default
    private String procurementMode = "DIRECT_PROCUREMENT";
    
    /**
     * AI推荐的供应商列表（JSON格式，平台代采时使用）
     * 格式: [{"supplierCode":"xxx","factoryName":"xxx","city":"xxx","quoteLow":10,"quoteHigh":20}]
     */
    @Column(name = "recommended_suppliers", columnDefinition = "TEXT")
    private String recommendedSuppliers;
    
    /**
     * 智能匹配会话ID（从智能匹配模块创建的合同）
     */
    @Column(name = "smart_match_session_id", length = 100)
    private String smartMatchSessionId;
    
    /**
     * 智能匹配产品名称
     */
    @Column(name = "smart_match_product_name", length = 200)
    private String smartMatchProductName;
    
    /**
     * 智能匹配品类代码
     */
    @Column(name = "smart_match_category_code", length = 50)
    private String smartMatchCategoryCode;

    @NonNull
    @Column(name = "contract_title", nullable = false, length = 200)
    private String contractTitle;

    @NonNull
    @Column(name = "total_amount", precision = 12, scale = 2, nullable = false)
    private BigDecimal totalAmount;

    @NonNull
    @Column(length = 10)
    @Builder.Default
    private String currency = "CNY";

    // 合同内容
    @Column(name = "contract_content", columnDefinition = "TEXT")
    private String contractContent;

    @Column(name = "template_id")
    private Long templateId;

    // 签署状态
    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "DRAFT";

    @Column(name = "buyer_signed")
    @Builder.Default
    private Boolean buyerSigned = false;

    @Column(name = "buyer_signed_at")
    private LocalDateTime buyerSignedAt;

    @Column(name = "buyer_signature", columnDefinition = "TEXT")
    private String buyerSignature;

    @Column(name = "supplier_signed")
    @Builder.Default
    private Boolean supplierSigned = false;

    @Column(name = "supplier_signed_at")
    private LocalDateTime supplierSignedAt;

    @Column(name = "supplier_signature", columnDefinition = "TEXT")
    private String supplierSignature;

    // 履约信息
    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "delivery_date")
    private LocalDate deliveryDate;

    @Column(name = "payment_terms", columnDefinition = "TEXT")
    private String paymentTerms;

    @Column(name = "quality_standards", columnDefinition = "TEXT")
    private String qualityStandards;

    // 文件存储
    @Column(name = "contract_pdf_url", length = 500)
    private String contractPdfUrl;

    @Column(name = "contract_hash", length = 128)
    private String contractHash;

    // 关联订单
    @Column(name = "order_id")
    private Long orderId;

    // 平台监管
    @Column(name = "platform_reviewed")
    @Builder.Default
    private Boolean platformReviewed = false;

    @Column(name = "platform_reviewer_id")
    private Long platformReviewerId;

    @Column(name = "platform_reviewed_at")
    private LocalDateTime platformReviewedAt;

    @Column(name = "platform_review_note", columnDefinition = "TEXT")
    private String platformReviewNote;

    @Column(columnDefinition = "TEXT")
    private String remark;

    // 纸质合同上传审核
    @Column(name = "physical_contract_url", length = 500)
    private String physicalContractUrl;

    @Column(name = "physical_contract_uploaded_at")
    private LocalDateTime physicalContractUploadedAt;

    @Column(name = "contract_review_status", length = 20)
    private String contractReviewStatus;

    @Column(name = "contract_reviewed_by")
    private Long contractReviewedBy;

    @Column(name = "contract_reviewed_at")
    private LocalDateTime contractReviewedAt;

    @Column(name = "contract_review_note", columnDefinition = "TEXT")
    private String contractReviewNote;

    @Column(name = "buyer_sign_ip", length = 50)
    private String buyerSignIp;

    @Column(name = "supplier_sign_ip", length = 50)
    private String supplierSignIp;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
