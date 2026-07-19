package com.yicai.trade.module.order.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_order_escrow")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class OrderEscrow {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "escrow_no", nullable = false, unique = true, length = 50)
    private String escrowNo;

    @NonNull
    @Column(name = "order_id", nullable = false, unique = true)
    private Long orderId;

    @NonNull
    @Column(name = "order_no", nullable = false, length = 50)
    private String orderNo;

    @NonNull
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @NonNull
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 订单总金额 */
    @NonNull
    @Column(name = "order_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal orderAmount;

    /** 托管金额（扣除平台佣金和返佣后的实际托管额） */
    @NonNull
    @Column(name = "escrow_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal escrowAmount;

    /** 平台佣金金额（不纳入托管） */
    @Column(name = "commission_amount", precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal commissionAmount = BigDecimal.ZERO;

    /** 返佣金额（不纳入托管） */
    @Column(name = "rebate_amount", precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal rebateAmount = BigDecimal.ZERO;

    /**
     * 托管状态：
     * FROZEN   - 已冻结（买家付款后资金被托管）
     * RELEASING - 释放中（买家申请提前释放，等待审批）
     * RELEASED - 已释放（资金已到账供应商）
     * REFUNDED - 已退款（订单取消，资金退回买家）
     */
    @NonNull
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "FROZEN";

    /** 计划释放天数（管理员设置） */
    @Column(name = "release_days")
    @Builder.Default
    private Integer releaseDays = 7;

    /** 计划自动释放时间 */
    @Column(name = "auto_release_at")
    private LocalDateTime autoReleaseAt;

    /** 实际释放时间 */
    @Column(name = "released_at")
    private LocalDateTime releasedAt;

    /** 提前释放申请原因 */
    @Column(name = "early_release_reason", length = 500)
    private String earlyReleaseReason;

    /** 提前释放申请时间 */
    @Column(name = "early_release_requested_at")
    private LocalDateTime earlyReleaseRequestedAt;

    /** 审批人ID */
    @Column(name = "approved_by")
    private Long approvedBy;

    /** 审批意见 */
    @Column(name = "approval_remark", length = 500)
    private String approvalRemark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
