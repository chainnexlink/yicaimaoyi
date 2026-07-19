package com.yicai.trade.module.monitor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "t_monitor_alert")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonitorAlert {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "monitor_setting_id")
    private Long monitorSettingId;

    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;

    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @Column(name = "alert_type", nullable = false, length = 30)
    private String alertType; // UPLOAD_OVERDUE/QUALITY_ISSUE/PROGRESS_DELAY/LOW_SCORE

    @Column(name = "alert_level")
    private String alertLevel; // INFO/WARNING/URGENT/CRITICAL

    @Column(name = "alert_title", nullable = false, length = 200)
    private String alertTitle;

    @Column(name = "alert_content", columnDefinition = "TEXT")
    private String alertContent;

    @Column(length = 20)
    private String status; // ACTIVE/ACKNOWLEDGED/RESOLVED/IGNORED

    @Column(name = "resolved_by")
    private Long resolvedBy;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @Column(name = "resolution_note", columnDefinition = "TEXT")
    private String resolutionNote;

    @Column(name = "buyer_notified")
    private Boolean buyerNotified;

    @Column(name = "supplier_notified")
    private Boolean supplierNotified;

    @Column(name = "platform_notified")
    private Boolean platformNotified;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (alertLevel == null) alertLevel = "WARNING";
        if (status == null) status = "ACTIVE";
        if (buyerNotified == null) buyerNotified = false;
        if (supplierNotified == null) supplierNotified = false;
        if (platformNotified == null) platformNotified = false;
    }
}
