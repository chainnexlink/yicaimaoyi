package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 拍卖报名记录
 * 供应商需要先报名才能参与竞价
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_signup", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"auction_id", "supplier_id"})
})
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionSignup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 所属拍卖 */
    @NonNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "auction_id", nullable = false)
    private Auction auction;

    /** 报名供应商ID */
    @NonNull
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 供应商公司名称 */
    @Column(name = "supplier_company", length = 200)
    private String supplierCompany;

    /** 联系人 */
    @Column(name = "contact_name", length = 50)
    private String contactName;

    /** 联系电话 */
    @Column(name = "contact_phone", length = 20)
    private String contactPhone;

    /**
     * 报名状态
     * PENDING=待审核, APPROVED=已通过, REJECTED=已拒绝
     */
    @Column(length = 20)
    @Builder.Default
    private String status = "APPROVED";

    /** 报名备注/承诺说明 */
    @Column(name = "remark", length = 500)
    private String remark;

    /** 资质承诺(JSON格式，记录供应商勾选的承诺项) */
    @Column(name = "qualification_promise", length = 2000)
    private String qualificationPromise;

    /** 报名IP地址 */
    @Column(name = "signup_ip", length = 50)
    private String signupIp;

    /** 关联的邀请ID（邀请制时） */
    @Column(name = "invitation_id")
    private Long invitationId;

    /** 审核备注 */
    @Column(name = "audit_remark", length = 500)
    private String auditRemark;

    /** 审核时间 */
    @Column(name = "audited_at")
    private LocalDateTime auditedAt;

    /** 审核人ID */
    @Column(name = "audited_by")
    private Long auditedBy;

    /** 是否已参与出价 */
    @Column(name = "has_bid")
    @Builder.Default
    private Boolean hasBid = false;

    /** 最后出价时间 */
    @Column(name = "last_bid_time")
    private LocalDateTime lastBidTime;

    /** 出价次数 */
    @Column(name = "bid_count")
    @Builder.Default
    private Integer bidCount = 0;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
