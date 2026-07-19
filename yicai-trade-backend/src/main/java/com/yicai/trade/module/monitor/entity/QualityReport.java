package com.yicai.trade.module.monitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "t_quality_report")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QualityReport {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "monitor_id")
    private Long monitorId;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @Column(name = "report_no", nullable = false, unique = true, length = 50)
    private String reportNo;

    @Column(name = "report_type")
    private String reportType; // INTERIM/FINAL/SPECIAL

    @Column(name = "report_title", nullable = false, length = 200)
    private String reportTitle;

    @Column(name = "inspection_date", nullable = false)
    private LocalDate inspectionDate;

    @Column(name = "inspector_name")
    private String inspectorName;

    @Column(name = "sample_count")
    private Integer sampleCount;

    @Column(name = "pass_count")
    private Integer passCount;

    @Column(name = "fail_count")
    private Integer failCount;

    @Column(name = "pass_rate", precision = 5, scale = 2)
    private BigDecimal passRate;

    @Column(name = "inspection_items", columnDefinition = "JSON")
    private String inspectionItems;

    @Column(length = 20)
    private String conclusion; // PASS/CONDITIONAL_PASS/FAIL/PENDING

    @Column(name = "conclusion_note", columnDefinition = "TEXT")
    private String conclusionNote;

    @Column(name = "report_pdf_url", length = 500)
    private String reportPdfUrl;

    @Column(columnDefinition = "JSON")
    private String photos;

    @Column(length = 20)
    private String status; // DRAFT/SUBMITTED/REVIEWED

    @Column(name = "reviewed_by")
    private Long reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (reportType == null) reportType = "INTERIM";
        if (conclusion == null) conclusion = "PENDING";
        if (status == null) status = "DRAFT";
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
