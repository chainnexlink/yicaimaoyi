package com.yicai.trade.module.monitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "t_monitor_setting")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonitorSetting {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false, unique = true)
    private Long orderId;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "upload_frequency")
    private String uploadFrequency; // DAILY/TWICE_WEEKLY/WEEKLY/BIWEEKLY

    @Column(name = "min_uploads_per_period")
    private Integer minUploadsPerPeriod;

    @Column(name = "require_photo")
    private Boolean requirePhoto;

    @Column(name = "require_video")
    private Boolean requireVideo;

    @Column(name = "require_description")
    private Boolean requireDescription;

    @Column(name = "monitor_stages", columnDefinition = "JSON")
    private String monitorStages;

    @Column(name = "current_stage")
    private String currentStage;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "weight_in_score")
    private Integer weightInScore;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (isActive == null) isActive = true;
        if (uploadFrequency == null) uploadFrequency = "WEEKLY";
        if (minUploadsPerPeriod == null) minUploadsPerPeriod = 1;
        if (requirePhoto == null) requirePhoto = true;
        if (requireVideo == null) requireVideo = false;
        if (requireDescription == null) requireDescription = true;
        if (weightInScore == null) weightInScore = 20;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
