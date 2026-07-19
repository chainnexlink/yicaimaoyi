package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 拍卖押金记录
 * 
 * 状态: PAID=已缴纳, REFUNDED=已退还, FORFEITED=已没收, PENDING_REFUND=待退还
 * 支付方式: WALLET=钱包, VOUCHER=抵用券, MIXED=混合
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_auction_deposit")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class AuctionDeposit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "deposit_no", nullable = false, unique = true, length = 50)
    private String depositNo;

    @Column(name = "auction_id")
    private Long auctionId;

    @Column(name = "auction_no", length = 50)
    private String auctionNo;

    @NonNull
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** BUYER / SUPPLIER */
    @NonNull
    @Column(name = "user_type", nullable = false, length = 20)
    private String userType;

    @Column(name = "company_name", length = 200)
    private String companyName;

    @NonNull
    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal amount;

    @Column(length = 10)
    @Builder.Default
    private String currency = "USD";

    /** 使用的抵用券ID（如果用了券） */
    @Column(name = "voucher_id")
    private Long voucherId;

    /** WALLET / VOUCHER / MIXED */
    @Column(name = "payment_method", length = 30)
    @Builder.Default
    private String paymentMethod = "WALLET";

    /** PAID / REFUNDED / FORFEITED / PENDING_REFUND */
    @NonNull
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "PAID";

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "refunded_at")
    private LocalDateTime refundedAt;

    @Column(name = "refund_reason", length = 500)
    private String refundReason;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
