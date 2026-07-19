package com.yicai.trade.module.contract.entity;

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
@Table(name = "t_contract_change_log")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class ContractChangeLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @NonNull
    @Column(name = "change_type", nullable = false, length = 20)
    private String changeType;

    @Column(name = "change_reason", columnDefinition = "TEXT")
    private String changeReason;

    @NonNull
    @Column(name = "initiator_type", nullable = false, length = 20)
    private String initiatorType;

    @Column(name = "initiator_id")
    private Long initiatorId;

    @Column(name = "initiator_name", length = 100)
    private String initiatorName;

    @Column(name = "old_content", columnDefinition = "TEXT")
    private String oldContent;

    @Column(name = "new_content", columnDefinition = "TEXT")
    private String newContent;

    @NonNull
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "approver_id")
    private Long approverId;

    @Column(name = "approver_name", length = 100)
    private String approverName;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "approval_note", columnDefinition = "TEXT")
    private String approvalNote;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
