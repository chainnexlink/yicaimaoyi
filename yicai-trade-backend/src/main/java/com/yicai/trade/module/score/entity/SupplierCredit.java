package com.yicai.trade.module.score.entity;

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
@Table(name = "t_supplier_credit")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class SupplierCredit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_id", unique = true)
    private Long supplierId;

    @Column(name = "credit_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal creditScore = new BigDecimal("100.00"); // 0-100 scale

    @Column(name = "credit_level", length = 10)
    @Builder.Default
    private String creditLevel = "A"; // AAA, AA, A, B, C, D

    // Dimensional scores (0-100)
    @Column(name = "delivery_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal deliveryScore = new BigDecimal("100.00");

    @Column(name = "quality_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal qualityScore = new BigDecimal("100.00");

    @Column(name = "service_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal serviceScore = new BigDecimal("100.00");

    @Column(name = "dispute_score", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal disputeScore = new BigDecimal("100.00");

    // Statistics
    @Column(name = "total_orders")
    @Builder.Default
    private Integer totalOrders = 0;

    @Column(name = "completed_orders")
    @Builder.Default
    private Integer completedOrders = 0;

    @Column(name = "on_time_deliveries")
    @Builder.Default
    private Integer onTimeDeliveries = 0;

    @Column(name = "late_deliveries")
    @Builder.Default
    private Integer lateDeliveries = 0;

    @Column(name = "quality_pass_count")
    @Builder.Default
    private Integer qualityPassCount = 0;

    @Column(name = "quality_fail_count")
    @Builder.Default
    private Integer qualityFailCount = 0;

    @Column(name = "total_disputes")
    @Builder.Default
    private Integer totalDisputes = 0;

    @Column(name = "lost_disputes")
    @Builder.Default
    private Integer lostDisputes = 0;

    @Column(name = "total_aftersales")
    @Builder.Default
    private Integer totalAftersales = 0;

    @Column(name = "avg_response_hours", precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal avgResponseHours = BigDecimal.ZERO;

    @Column(name = "avg_buyer_rating", precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal avgBuyerRating = new BigDecimal("5.00"); // 1-5

    @Column(name = "total_reviews")
    @Builder.Default
    private Integer totalReviews = 0;

    @Column(name = "last_calculated_at")
    private LocalDateTime lastCalculatedAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
