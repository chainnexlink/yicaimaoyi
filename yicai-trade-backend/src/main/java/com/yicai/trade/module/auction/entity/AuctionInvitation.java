package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 拍卖邀请记录
 * 采购商可以定向邀请供应商参与拍卖
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_invitation", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"auction_id", "supplier_id"})
})
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 拍卖ID */
    @Column(name = "auction_id", nullable = false)
    private Long auctionId;

    /** 被邀请的供应商ID */
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    /** 供应商公司名称 */
    @Column(name = "supplier_company", length = 200)
    private String supplierCompany;

    /** 邀请说明 */
    @Column(name = "invite_message", length = 500)
    private String inviteMessage;

    /**
     * 邀请状态
     * PENDING=待回复, ACCEPTED=已接受, REJECTED=已拒绝, EXPIRED=已过期
     */
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    /** 回复时间 */
    @Column(name = "responded_at")
    private LocalDateTime respondedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
