package com.yicai.trade.module.certification.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class FactoryAuditRequest {
    private Long supplierId;
    private String companyName;
    private String factoryAddress;
    private String auditType;
    private String auditorName;
    private Long auditorId;
    private LocalDate auditDate;
    private String productionCapacity;
    private Integer employeeCount;
    private Integer factoryArea;
    private String equipmentList;
    private String qualitySystem;
}
