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
@Table(name = "t_platform_commission")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class PlatformCommission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "commission_no", nullable = false, unique = true, length = 50)
    private String commissionNo;

    /** 关联合同ID */
    @NonNull
    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    /** 关联合同号 */
    @Column(name = "contract_no", length = 50)
    private String contractNo;

    /** 买方(客户)ID */
    @NonNull
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    /** 供应商ID */
    @Column(name = "supplier_id")
    private Long supplierId;

    /** 合同总金额 */
    @NonNull
    @Column(name = "contract_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal contractAmount;

    /** 平台固定佣金比例（固定2%） */
    @NonNull
    @Column(name = "platform_rate", nullable = false, precision = 5, scale = 4)
    @Builder.Default
    private BigDecimal platformRate = new BigDecimal("0.0200");

    /** 平台固定佣金金额（合同金额 * 2%） */
    @NonNull
    @Column(name = "platform_fee", nullable = false, precision = 14, scale = 2)
    private BigDecimal platformFee;

    /** 客户自定义返佣比例（1%-10%） */
    @NonNull
    @Column(name = "rebate_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal rebateRate;

    /** 返佣金额（合同金额 * 返佣比例） */
    @NonNull
    @Column(name = "rebate_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal rebateAmount;

    /** 平台服务费总额（固定佣金 + 返佣金额，对外统一称为"平台服务费"） */
    @NonNull
    @Column(name = "total_service_fee", nullable = false, precision = 14, scale = 2)
    private BigDecimal totalServiceFee;

    /**
     * 状态：
     * PENDING    - 待收取（合同签署后）
     * COLLECTED  - 已收取（服务费已收）
     * REBATED    - 已返佣（合同结束，返佣已入客户零钱）
     * CANCELLED  - 已取消（合同取消）
     */
    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    /** 服务费收取时间 */
    @Column(name = "collected_at")
    private LocalDateTime collectedAt;

    /** 返佣执行时间 */
    @Column(name = "rebated_at")
    private LocalDateTime rebatedAt;

    /** 备注 */
    @Column(columnDefinition = "TEXT")
    private String remark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
