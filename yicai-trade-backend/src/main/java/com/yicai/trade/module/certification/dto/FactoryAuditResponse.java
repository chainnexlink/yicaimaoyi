package com.yicai.trade.module.certification.dto;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class FactoryAuditResponse {
    private Long id;
    private String auditNo;
    private Long supplierId;
    private String companyName;
    private String factoryAddress;
    private String auditType;
    private String auditItems;
    private String auditorName;
    private Long auditorId;
    private LocalDate auditDate;
    private String productionCapacity;
    private Integer employeeCount;
    private Integer factoryArea;
    private String equipmentList;
    private String qualitySystem;
    private String photos;
    private Integer overallScore;
    private String conclusion;
    private String status;
    private LocalDate nextAuditDate;
    private LocalDateTime createdAt;
}
