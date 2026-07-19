package com.yicai.trade.module.score.entity;

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
@Table(name = "t_credit_change_log")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class CreditChangeLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "change_type", length = 30)
    private String changeType;
    // ORDER_COMPLETE, LATE_DELIVERY, QUALITY_PASS, QUALITY_FAIL,
    // DISPUTE_WIN, DISPUTE_LOSE, BUYER_REVIEW, AFTERSALE, MANUAL_ADJUST

    @Column(name = "dimension", length = 20)
    private String dimension; // DELIVERY, QUALITY, SERVICE, DISPUTE, OVERALL

    @Column(name = "old_score", precision = 5, scale = 2)
    private BigDecimal oldScore;

    @Column(name = "new_score", precision = 5, scale = 2)
    private BigDecimal newScore;

    @Column(name = "change_amount", precision = 5, scale = 2)
    private BigDecimal changeAmount;

    @Column(name = "related_id")
    private Long relatedId;

    @Column(name = "related_type", length = 30)
    private String relatedType; // ORDER, DISPUTE, AFTERSALE, REVIEW

    @Column(length = 500)
    private String reason;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
