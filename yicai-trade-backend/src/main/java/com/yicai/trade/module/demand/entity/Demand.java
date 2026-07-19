package com.yicai.trade.module.demand.entity;

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
@Table(name = "t_demand")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Demand {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "demand_no", unique = true, length = 30)
    private String demandNo;

    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;

    @Column(name = "buyer_company_name", length = 200)
    private String buyerCompanyName;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "category_code", length = 50)
    private String categoryCode;

    @Column(name = "category_name", length = 100)
    private String categoryName;

    @Column
    private Integer quantity;

    @Column(length = 20)
    private String unit;

    @Column(precision = 15, scale = 2)
    private BigDecimal budget;

    @Column(name = "expected_delivery_days")
    private Integer expectedDeliveryDays;

    @Column(name = "response_count")
    @Builder.Default
    private Integer responseCount = 0;

    @Column(name = "view_count")
    @Builder.Default
    private Integer viewCount = 0;

    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";  // PENDING, ACTIVE, MATCHED, CLOSED

    @Column(name = "audit_status", length = 20)
    @Builder.Default
    private String auditStatus = "PENDING";  // PENDING, APPROVED, REJECTED

    @Column(name = "audit_remark", length = 500)
    private String auditRemark;

    @Column(name = "auditor_id")
    private Long auditorId;

    @Column(name = "audit_time")
    private LocalDateTime auditTime;

    @Column(name = "expire_time")
    private LocalDateTime expireTime;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
