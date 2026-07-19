package com.yicai.trade.module.dispute.entity;

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
@Table(name = "t_dispute")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Dispute {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "dispute_no", unique = true, length = 50)
    private String disputeNo;

    @Column(name = "order_id")
    private Long orderId;

    @Column(name = "order_no", length = 50)
    private String orderNo;

    @Column(name = "aftersale_id")
    private Long aftersaleId;

    @Column(name = "initiator_id")
    private Long initiatorId;

    @Column(name = "initiator_role", length = 20)
    private String initiatorRole; // BUYER, SUPPLIER

    @Column(name = "respondent_id")
    private Long respondentId;

    @Column(name = "respondent_role", length = 20)
    private String respondentRole;

    @Column(name = "dispute_type", length = 30)
    private String disputeType; // QUALITY, DELIVERY, PAYMENT, CONTRACT, FRAUD, OTHER

    @Column(name = "severity", length = 10)
    @Builder.Default
    private String severity = "NORMAL"; // LOW, NORMAL, HIGH, CRITICAL

    @Column(name = "description", length = 2000)
    private String description;

    @Column(name = "evidence_urls", length = 2000)
    private String evidenceUrls;

    @Column(name = "claim_amount", precision = 14, scale = 2)
    private BigDecimal claimAmount;

    @Column(name = "awarded_amount", precision = 14, scale = 2)
    private BigDecimal awardedAmount;

    @Column(name = "ruling_type", length = 30)
    private String rulingType; // FULL_REFUND, PARTIAL_REFUND, COMPENSATION, REJECT, MEDIATION

    @Column(name = "ruling_reason", length = 2000)
    private String rulingReason;

    @Column(name = "assigned_to")
    private Long assignedTo;

    @Column(length = 20)
    @Builder.Default
    private String status = "OPEN";
    // OPEN -> UNDER_REVIEW -> MEDIATION -> RULING -> ENFORCING -> CLOSED
    // or OPEN -> WITHDRAWN

    @Column(name = "ruled_at")
    private LocalDateTime ruledAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
