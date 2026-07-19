package com.yicai.trade.module.contract.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContractTemplateResponse {
    private Long id;
    private String templateName;
    private String templateCode;
    private String templateType;
    private String templateContent;
    private String templateVariables;
    private String category;
    private String industry;
    private Boolean isActive;
    private Boolean isDefault;
    private String version;
    private String description;
    private String submitterType;
    private Long submitterId;
    private String submitterName;
    private String fileUrl;
    private String fileName;
    private Long fileSize;
    private String auditStatus;
    private Long auditBy;
    private String auditName;
    private LocalDateTime auditAt;
    private String auditNote;
    private Integer usageCount;
    private LocalDateTime createdAt;
}
