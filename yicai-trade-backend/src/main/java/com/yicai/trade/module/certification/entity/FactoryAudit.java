package com.yicai.trade.module.certification.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "t_factory_audit")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class FactoryAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "audit_no", unique = true, length = 50)
    private String auditNo;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "company_name", length = 200)
    private String companyName;

    @Column(name = "factory_address", length = 500)
    private String factoryAddress;

    @Column(name = "audit_type", length = 30)
    private String auditType; // INITIAL, ANNUAL, SPOT_CHECK, RENEWAL

    @Column(name = "audit_items", length = 3000)
    private String auditItems; // JSON: checklist items with pass/fail

    @Column(name = "auditor_name", length = 100)
    private String auditorName;

    @Column(name = "auditor_id")
    private Long auditorId;

    @Column(name = "audit_date")
    private LocalDate auditDate;

    @Column(name = "production_capacity", length = 200)
    private String productionCapacity;

    @Column(name = "employee_count")
    private Integer employeeCount;

    @Column(name = "factory_area")
    private Integer factoryArea; // square meters

    @Column(name = "equipment_list", length = 2000)
    private String equipmentList;

    @Column(name = "quality_system", length = 200)
    private String qualitySystem; // ISO9001, ISO14001, etc.

    @Column(name = "photos", length = 2000)
    private String photos; // JSON array of photo URLs

    @Column(name = "overall_score")
    private Integer overallScore; // 0-100

    @Column(name = "conclusion", length = 2000)
    private String conclusion;

    @Column(length = 20)
    @Builder.Default
    private String status = "SCHEDULED"; // SCHEDULED, IN_PROGRESS, COMPLETED, PASSED, FAILED

    @Column(name = "next_audit_date")
    private LocalDate nextAuditDate;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
