package com.yicai.trade.module.wallet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_wallet_transaction")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class WalletTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "transaction_no", nullable = false, unique = true, length = 50)
    private String transactionNo;

    @NonNull
    @Column(name = "wallet_id", nullable = false)
    private Long walletId;

    @NonNull
    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @NonNull
    @Column(name = "owner_type", nullable = false, length = 20)
    private String ownerType;

    /**
     * 交易类型：
     * COMMISSION_REBATE  - 佣金返佣（合同结束返回客户零钱）
     * COMMISSION_INCOME  - 平台佣金收入（2%固定佣金）
     * WITHDRAW           - 提现
     * RECHARGE           - 充值
     * FREEZE             - 冻结
     * UNFREEZE           - 解冻
     * ADJUST             - 平台调整
     */
    @NonNull
    @Column(name = "transaction_type", nullable = false, length = 30)
    private String transactionType;

    /** 交易金额（正数入账，负数出账） */
    @NonNull
    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal amount;

    /** 交易前余额 */
    @Column(name = "balance_before", precision = 14, scale = 2)
    private BigDecimal balanceBefore;

    /** 交易后余额 */
    @Column(name = "balance_after", precision = 14, scale = 2)
    private BigDecimal balanceAfter;

    /** 关联合同ID */
    @Column(name = "contract_id")
    private Long contractId;

    /** 关联合同号 */
    @Column(name = "contract_no", length = 50)
    private String contractNo;

    /** 关联佣金记录ID */
    @Column(name = "commission_id")
    private Long commissionId;

    /** 交易说明 */
    @Column(length = 500)
    private String description;

    /** 操作人ID */
    @Column(name = "operator_id")
    private Long operatorId;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
