package com.yicai.trade.module.monitor.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 监控预警响应
 */
@Data
@Builder
public class AlertResponse {
    private Long id;
    private Long orderId;
    private String orderNo;
    private Long supplierId;
    private String supplierName;
    private Long buyerId;
    private String buyerName;

    private String alertType;
    private String alertLevel;
    private String alertTitle;
    private String alertContent;

    private String status;
    private Long resolvedBy;
    private String resolverName;
    private LocalDateTime resolvedAt;
    private String resolutionNote;

    private Boolean buyerNotified;
    private Boolean supplierNotified;
    private Boolean platformNotified;

    private LocalDateTime createdAt;
}
