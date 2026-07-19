package com.yicai.trade.module.certification.dto;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class CertificationResponse {
    private Long id;
    private String certNo;
    private Long userId;
    private Long companyId;
    private String companyName;
    private String creditCode;
    private String companyType;
    private String registeredCapital;
    private LocalDate foundDate;
    private String companyAddress;

    private String legalName;
    private String legalIdNumber;
    private String legalPhone;
    private String legalIdFront;
    private String legalIdBack;

    private String businessLicense;
    private String certType;
    private String otherCerts;

    private String contactName;
    private String contactTitle;
    private String contactPhone;
    private String contactEmail;

    private String materials;
    private String status;
    private String auditRemark;
    private String auditedBy;
    private LocalDateTime auditedAt;
    private LocalDateTime expireAt;
    private LocalDateTime createdAt;
}
