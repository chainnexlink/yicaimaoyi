package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 电子反拍/拍卖实体
 * 采购商发布采购需求，供应商在规定时间内竞价（反拍=价低者得）
 * 
 * 拍卖类型: REVERSE_AUCTION(反向拍卖), TENDER(招标), INQUIRY(询比价)
 * 
 * 状态流转：
 * DRAFT(草稿) → PENDING_APPROVAL(待审核) → APPROVED(已审核) → SIGNUP(报名中) 
 * → ACTIVE(竞价中) → CONFIRMING(待确认) → CONFIRMED(已确认) → DELIVERING(履约中) → COMPLETED(已完成)
 * 
 * 特殊状态：CANCELLED(已取消), FAILED(流标), VOIDED(废选)
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Auction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 拍卖编号 */
    @NonNull
    @Column(name = "auction_no", nullable = false, unique = true, length = 50)
    private String auctionNo;

    /** 拍卖类型: REVERSE_AUCTION(反向拍卖), TENDER(招标), INQUIRY(询比价) */
    @Column(name = "auction_type", length = 30)
    @Builder.Default
    private String auctionType = "REVERSE_AUCTION";

    /** 币种: CNY/USD/EUR/GBP */
    @Column(name = "currency", length = 10)
    @Builder.Default
    private String currency = "CNY";

    /** 发布采购商ID */
    @NonNull
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    /** 采购商公司名称 */
    @Column(name = "buyer_company", length = 200)
    private String buyerCompany;

    /** 产品名称 */
    @NonNull
    @Column(name = "product_name", nullable = false, length = 200)
    private String productName;

    /** 产品分类 */
    @Column(name = "product_category", length = 100)
    private String productCategory;

    /** 产品规格描述 */
    @Column(name = "specification", length = 2000)
    private String specification;

    /** 采购数量 */
    @NonNull
    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    /** 数量单位 */
    @Column(name = "unit", length = 20)
    @Builder.Default
    private String unit = "件";

    /** 起拍价/最高限价(反拍中供应商出价不得高于此价) */
    @Column(name = "starting_price", precision = 16, scale = 4)
    private BigDecimal startingPrice;

    /** 当前最低出价 */
    @Column(name = "current_lowest_price", precision = 16, scale = 4)
    private BigDecimal currentLowestPrice;

    /** 最低降价幅度 */
    @Column(name = "min_decrement", precision = 16, scale = 4)
    @Builder.Default
    private BigDecimal minDecrement = new BigDecimal("1.00");

    /** 底价（隐藏），低于此价不接受 */
    @Column(name = "reserve_price", precision = 16, scale = 4)
    private BigDecimal reservePrice;

    /** 是否公开底价 */
    @Column(name = "show_reserve_price")
    @Builder.Default
    private Boolean showReservePrice = false;

    /** 参考价（从成本核算系统导入） */
    @Column(name = "reference_price", precision = 16, scale = 4)
    private BigDecimal referencePrice;

    /** 参考价来源说明 */
    @Column(name = "reference_source", length = 200)
    private String referenceSource;

    // ========== 报名时间设置 ==========
    
    /** 报名开始时间 */
    @Column(name = "signup_start_time")
    private LocalDateTime signupStartTime;

    /** 报名结束时间 */
    @Column(name = "signup_end_time")
    private LocalDateTime signupEndTime;

    /** 已报名供应商数量 */
    @Column(name = "signup_count")
    @Builder.Default
    private Integer signupCount = 0;

    /** 是否仅邀请制 */
    @Column(name = "invite_only")
    @Builder.Default
    private Boolean inviteOnly = false;

    // ========== 竞价时间设置 ==========

    /** 拍卖开始时间 */
    @NonNull
    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    /** 拍卖结束时间(可能被延时修改) */
    @NonNull
    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    /** 原始结束时间(用于记录延时前的时间) */
    @Column(name = "original_end_time")
    private LocalDateTime originalEndTime;

    // ========== 反拍规则设置 ==========

    /** 最少参与供应商数量(不足则流标) */
    @Column(name = "min_participants")
    @Builder.Default
    private Integer minParticipants = 3;

    /** 延时分钟数(结束前有新报价则延时) */
    @Column(name = "extension_minutes")
    @Builder.Default
    private Integer extensionMinutes = 5;

    /** 触发延时的剩余时间(分钟，如最后5分钟内有新报价) */
    @Column(name = "extension_trigger_minutes")
    @Builder.Default
    private Integer extensionTriggerMinutes = 5;

    /** 最大延时次数 */
    @Column(name = "max_extensions")
    @Builder.Default
    private Integer maxExtensions = 10;

    /** 当前已延时次数 */
    @Column(name = "current_extensions")
    @Builder.Default
    private Integer currentExtensions = 0;

    /** 是否允许供应商查看排名 */
    @Column(name = "show_ranking")
    @Builder.Default
    private Boolean showRanking = true;

    /** 是否允许供应商查看最低价 */
    @Column(name = "show_lowest_price")
    @Builder.Default
    private Boolean showLowestPrice = true;

    /** 出价冷却时间（秒） */
    @Column(name = "bid_cooldown_seconds")
    @Builder.Default
    private Integer bidCooldownSeconds = 0;

    // ========== 综合评分设置 ==========

    /** 是否启用综合评分 */
    @Column(name = "scoring_enabled")
    @Builder.Default
    private Boolean scoringEnabled = false;

    /** 价格权重（百分比） */
    @Column(name = "price_weight")
    @Builder.Default
    private Integer priceWeight = 100;

    /** 交期权重 */
    @Column(name = "delivery_weight")
    @Builder.Default
    private Integer deliveryWeight = 0;

    /** 质量权重 */
    @Column(name = "quality_weight")
    @Builder.Default
    private Integer qualityWeight = 0;

    /** 服务权重 */
    @Column(name = "service_weight")
    @Builder.Default
    private Integer serviceWeight = 0;

    // ========== 状态信息 ==========

    /** 
     * 拍卖状态
     * DRAFT=草稿, PENDING_APPROVAL=待审核, APPROVED=已审核, SIGNUP=报名中,
     * ACTIVE=竞价中, CONFIRMING=待确认, CONFIRMED=已确认, 
     * DELIVERING=履约中, COMPLETED=已完成, CANCELLED=已取消, FAILED=流标, VOIDED=废选
     */
    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "DRAFT";

    /** 审核人ID */
    @Column(name = "approver_id")
    private Long approverId;

    /** 审核时间 */
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    /** 审核备注/驳回原因 */
    @Column(name = "approval_remark", length = 500)
    private String approvalRemark;

    // ========== 中标信息 ==========

    /** 中标供应商ID */
    @Column(name = "winner_supplier_id")
    private Long winnerSupplierId;

    /** 中标供应商公司名称 */
    @Column(name = "winner_company", length = 200)
    private String winnerCompany;

    /** 中标价格 */
    @Column(name = "winning_price", precision = 16, scale = 4)
    private BigDecimal winningPrice;

    /** 出价次数统计 */
    @Column(name = "bid_count")
    @Builder.Default
    private Integer bidCount = 0;

    /** 参与供应商数量 */
    @Column(name = "participant_count")
    @Builder.Default
    private Integer participantCount = 0;

    // ========== 结果确认 ==========

    /** 结果确认截止时间 */
    @Column(name = "confirm_deadline")
    private LocalDateTime confirmDeadline;

    /** 采购商是否确认结果 */
    @Column(name = "buyer_confirmed")
    @Builder.Default
    private Boolean buyerConfirmed = false;

    /** 采购商确认时间 */
    @Column(name = "buyer_confirmed_at")
    private LocalDateTime buyerConfirmedAt;

    /** 供应商是否确认结果 */
    @Column(name = "supplier_confirmed")
    @Builder.Default
    private Boolean supplierConfirmed = false;

    /** 供应商确认时间 */
    @Column(name = "supplier_confirmed_at")
    private LocalDateTime supplierConfirmedAt;

    // ========== 订单关联 ==========

    /** 生成的订单ID */
    @Column(name = "order_id")
    private Long orderId;

    /** 生成的合同ID */
    @Column(name = "contract_id")
    private Long contractId;

    // ========== 交付信息 ==========

    /** 交货地址 */
    @Column(name = "delivery_address", length = 500)
    private String deliveryAddress;

    /** 要求交货日期 */
    @Column(name = "required_delivery_date")
    private java.time.LocalDate requiredDeliveryDate;

    /** 付款方式说明 */
    @Column(name = "payment_terms", length = 500)
    private String paymentTerms;

    /** 其他要求/备注 */
    @Column(name = "remark", length = 2000)
    private String remark;

    /** 封面图片URL */
    @Column(name = "cover_image", length = 500)
    private String coverImage;

    /** 附件URLs(JSON数组) */
    @Column(name = "attachments", length = 2000)
    private String attachments;

    // ========== 关联数据 ==========

    /** 出价记录 */
    @NonNull
    @OneToMany(mappedBy = "auction", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<AuctionBid> bids = new ArrayList<>();

    /** 报名记录 */
    @NonNull
    @OneToMany(mappedBy = "auction", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<AuctionSignup> signups = new ArrayList<>();

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
