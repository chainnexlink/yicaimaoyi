package com.yicai.trade.module.payment.entity;

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
@Table(name = "t_refund")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Refund {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "refund_no", nullable = false, unique = true, length = 50)
    private String refundNo;

    @NonNull
    @Column(name = "payment_id", nullable = false)
    private Long paymentId;

    @Column(name = "payment_no", length = 50)
    private String paymentNo;

    @NonNull
    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "order_no", length = 50)
    private String orderNo;

    @NonNull
    @Column(name = "applicant_id", nullable = false)
    private Long applicantId;

    @Column(name = "applicant_name", length = 100)
    private String applicantName;

    @NonNull
    @Column(name = "refund_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal refundAmount;

    @NonNull
    @Column(name = "refund_reason", nullable = false, length = 500)
    private String refundReason;

    @NonNull
    @Column(name = "refund_type", length = 20)
    @Builder.Default
    private String refundType = "FULL";

    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "auditor_id")
    private Long auditorId;

    @Column(name = "auditor_name", length = 100)
    private String auditorName;

    @Column(name = "audit_remark", columnDefinition = "TEXT")
    private String auditRemark;

    @Column(name = "audited_at")
    private LocalDateTime auditedAt;

    @Column(name = "transaction_id", length = 100)
    private String transactionId;

    @Column(name = "refunded_at")
    private LocalDateTime refundedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
