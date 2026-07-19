package com.yicai.trade.module.auction.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 押金抵用券
 *
 * voucher_type: BUYER_DEPOSIT(采购商押金券), SUPPLIER_DEPOSIT(供应商押金券)
 * status: ACTIVE(可用), USED(已使用), EXPIRED(已过期), REVOKED(已撤销)
 * source: REGISTER(注册赠送), ADMIN_ISSUE(管理员发放), PROMOTION(活动赠送)
 */
@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_deposit_voucher")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class DepositVoucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "voucher_no", nullable = false, unique = true, length = 50)
    private String voucherNo;

    @NonNull
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** BUYER / SUPPLIER */
    @NonNull
    @Column(name = "user_type", nullable = false, length = 20)
    private String userType;

    /** BUYER_DEPOSIT / SUPPLIER_DEPOSIT */
    @NonNull
    @Column(name = "voucher_type", nullable = false, length = 30)
    @Builder.Default
    private String voucherType = "AUCTION_DEPOSIT";

    @NonNull
    @Column(name = "face_value", nullable = false, precision = 14, scale = 2)
    private BigDecimal faceValue;

    @Column(length = 10)
    @Builder.Default
    private String currency = "USD";

    /** ACTIVE / USED / EXPIRED / REVOKED */
    @NonNull
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    /** REGISTER / ADMIN_ISSUE / PROMOTION */
    @Column(length = 50)
    @Builder.Default
    private String source = "REGISTER";

    @Column(name = "used_auction_id")
    private Long usedAuctionId;

    @Column(name = "used_deposit_id")
    private Long usedDepositId;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "used_at")
    private LocalDateTime usedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "issued_by")
    private Long issuedBy;

    @Column(length = 500)
    private String remark;
}
