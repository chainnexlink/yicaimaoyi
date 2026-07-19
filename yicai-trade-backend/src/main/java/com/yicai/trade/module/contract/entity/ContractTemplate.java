package com.yicai.trade.module.contract.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_contract_template")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class ContractTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NonNull
    @Column(name = "template_name", nullable = false, length = 100)
    private String templateName;

    @NonNull
    @Column(name = "template_code", nullable = false, unique = true, length = 50)
    private String templateCode;

    @NonNull
    @Column(name = "template_type", length = 20)
    @Builder.Default
    private String templateType = "STANDARD";

    @NonNull
    @Column(name = "template_content", nullable = false, columnDefinition = "TEXT")
    private String templateContent;

    @Column(name = "template_variables", columnDefinition = "JSON")
    private String templateVariables;

    @Column(length = 50)
    private String category;

    @Column(length = 50)
    private String industry;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "is_default")
    @Builder.Default
    private Boolean isDefault = false;

    @Column(length = 20)
    @Builder.Default
    private String version = "1.0";

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "submitter_type", length = 20)
    @Builder.Default
    private String submitterType = "PLATFORM";

    @Column(name = "submitter_id")
    private Long submitterId;

    @Column(name = "submitter_name", length = 100)
    private String submitterName;

    @Column(name = "file_url", length = 500)
    private String fileUrl;

    @Column(name = "file_name", length = 200)
    private String fileName;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "audit_status", length = 20)
    @Builder.Default
    private String auditStatus = "APPROVED";

    @Column(name = "audit_by")
    private Long auditBy;

    @Column(name = "audit_name", length = 100)
    private String auditName;

    @Column(name = "audit_at")
    private LocalDateTime auditAt;

    @Column(name = "audit_note", columnDefinition = "TEXT")
    private String auditNote;

    @Column(name = "usage_count")
    @Builder.Default
    private Integer usageCount = 0;

    @Column(name = "created_by")
    private Long createdBy;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
