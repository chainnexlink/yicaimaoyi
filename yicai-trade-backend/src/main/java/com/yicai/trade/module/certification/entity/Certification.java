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
@Table(name = "t_certification")
@EntityListeners(AuditingEntityListener.class)
@EqualsAndHashCode(of = {"id"})
public class Certification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cert_no", unique = true, length = 30)
    private String certNo;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "company_name", length = 200)
    private String companyName;

    @Column(name = "credit_code", length = 30)
    private String creditCode;

    @Column(name = "company_type", length = 50)
    private String companyType;

    @Column(name = "registered_capital", length = 50)
    private String registeredCapital;

    @Column(name = "found_date")
    private LocalDate foundDate;

    @Column(name = "company_address", length = 500)
    private String companyAddress;

    // 法人信息
    @Column(name = "legal_name", length = 50)
    private String legalName;

    @Column(name = "legal_id_number", length = 30)
    private String legalIdNumber;

    @Column(name = "legal_phone", length = 20)
    private String legalPhone;

    @Column(name = "legal_id_front", length = 500)
    private String legalIdFront;

    @Column(name = "legal_id_back", length = 500)
    private String legalIdBack;

    // 资质证书
    @Column(name = "business_license", length = 500)
    private String businessLicense;

    @Column(name = "cert_type", length = 50)
    private String certType;

    @Column(name = "other_certs", length = 2000)
    private String otherCerts;

    @Column(name = "materials", length = 2000)
    private String materials;

    // 联系人信息
    @Column(name = "contact_name", length = 50)
    private String contactName;

    @Column(name = "contact_title", length = 50)
    private String contactTitle;

    @Column(name = "contact_phone", length = 20)
    private String contactPhone;

    @Column(name = "contact_email", length = 100)
    private String contactEmail;

    // 审核信息
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "audit_remark", length = 500)
    private String auditRemark;

    @Column(name = "audited_by", length = 50)
    private String auditedBy;

    @Column(name = "audited_at")
    private LocalDateTime auditedAt;

    @Column(name = "expire_at")
    private LocalDateTime expireAt;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
