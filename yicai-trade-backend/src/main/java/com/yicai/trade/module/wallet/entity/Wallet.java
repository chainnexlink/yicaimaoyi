package com.yicai.trade.module.wallet.entity;

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
@Table(name = "t_wallet", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"owner_id", "owner_type"})
})
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Wallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 所有者ID（用户/供应商/平台ID） */
    @NonNull
    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    /** 所有者类型：BUYER / SUPPLIER / PLATFORM */
    @NonNull
    @Column(name = "owner_type", nullable = false, length = 20)
    private String ownerType;

    /** 零钱余额 */
    @NonNull
    @Column(nullable = false, precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal balance = BigDecimal.ZERO;

    /** 冻结金额（提现中、退款中等） */
    @NonNull
    @Column(name = "frozen_amount", nullable = false, precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal frozenAmount = BigDecimal.ZERO;

    /** 累计收入 */
    @NonNull
    @Column(name = "total_income", nullable = false, precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal totalIncome = BigDecimal.ZERO;

    /** 累计支出 */
    @NonNull
    @Column(name = "total_expense", nullable = false, precision = 14, scale = 2)
    @Builder.Default
    private BigDecimal totalExpense = BigDecimal.ZERO;

    /** 钱包状态：ACTIVE / FROZEN / CLOSED */
    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
