package com.yicai.trade.module.monitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "t_production_monitor")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionMonitor {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "monitor_setting_id", nullable = false)
    private Long monitorSettingId;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 50)
    private String stage;

    @Column(name = "progress_percent")
    private Integer progressPercent;

    @Column(columnDefinition = "JSON")
    private String photos;

    @Column(columnDefinition = "JSON")
    private String videos;

    @Column(columnDefinition = "JSON")
    private String attachments;

    @Column(name = "upload_type")
    private String uploadType; // SCHEDULED/EXTRA/URGENT

    @Column(name = "uploader_id")
    private Long uploaderId;

    @Column(name = "uploader_name")
    private String uploaderName;

    @Column(name = "review_status")
    private String reviewStatus; // PENDING/APPROVED/REJECTED

    @Column(name = "reviewer_id")
    private Long reviewerId;

    @Column(name = "reviewer_name")
    private String reviewerName;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "review_note", columnDefinition = "TEXT")
    private String reviewNote;

    @Column(name = "buyer_viewed")
    private Boolean buyerViewed;

    @Column(name = "buyer_viewed_at")
    private LocalDateTime buyerViewedAt;

    @Column(name = "buyer_feedback", columnDefinition = "TEXT")
    private String buyerFeedback;

    @Column(name = "buyer_rating")
    private Integer buyerRating;

    @Column(name = "is_overdue")
    private Boolean isOverdue;

    @Column(name = "overdue_days")
    private Integer overdueDays;

    @Column(name = "has_quality_issue")
    private Boolean hasQualityIssue;

    @Column(name = "quality_issue_note", columnDefinition = "TEXT")
    private String qualityIssueNote;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (reviewStatus == null) reviewStatus = "PENDING";
        if (uploadType == null) uploadType = "SCHEDULED";
        if (progressPercent == null) progressPercent = 0;
        if (buyerViewed == null) buyerViewed = false;
        if (isOverdue == null) isOverdue = false;
        if (overdueDays == null) overdueDays = 0;
        if (hasQualityIssue == null) hasQualityIssue = false;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
