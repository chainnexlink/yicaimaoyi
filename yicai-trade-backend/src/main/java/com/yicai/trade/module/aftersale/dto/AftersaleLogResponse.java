package com.yicai.trade.module.aftersale.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AftersaleLogResponse {
    private Long id;
    private Long operatorId;
    private String operatorName;
    private String operatorRole;
    private String action;
    private String fromStatus;
    private String toStatus;
    private String remark;
    private LocalDateTime createdAt;
}
