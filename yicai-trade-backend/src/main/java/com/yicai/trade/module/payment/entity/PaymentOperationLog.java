package com.yicai.trade.module.payment.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_payment_operation_log")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class PaymentOperationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "payment_id")
    private Long paymentId;

    @Column(name = "payment_no", length = 50)
    private String paymentNo;

    @Column(name = "refund_id")
    private Long refundId;

    @Column(name = "refund_no", length = 50)
    private String refundNo;

    /** CREATE/CONFIRM/CANCEL/EXPIRE/REFUND_CREATE/REFUND_APPROVE/REFUND_REJECT/REFUND_PROCESS */
    @Column(name = "operation_type", nullable = false, length = 30)
    private String operationType;

    @Column(name = "from_status", length = 20)
    private String fromStatus;

    @Column(name = "to_status", length = 20)
    private String toStatus;

    @Column(name = "operator_id")
    private Long operatorId;

    @Column(name = "operator_name", length = 100)
    private String operatorName;

    @Column(name = "remark", columnDefinition = "TEXT")
    private String remark;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
