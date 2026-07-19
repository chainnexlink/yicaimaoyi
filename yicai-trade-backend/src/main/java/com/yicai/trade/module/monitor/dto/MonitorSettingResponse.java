package com.yicai.trade.module.monitor.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 监控配置响应
 */
@Data
@Builder
public class MonitorSettingResponse {
    private Long id;
    private Long orderId;
    private String orderNo;
    private Long contractId;
    private String contractNo;
    private Long buyerId;
    private String buyerName;
    private Long supplierId;
    private String supplierName;

    private String uploadFrequency;
    private Integer minUploadsPerPeriod;
    private Boolean requirePhoto;
    private Boolean requireVideo;
    private Boolean requireDescription;

    private List<String> monitorStages;
    private String currentStage;

    private Boolean isActive;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer weightInScore;

    // 统计信息
    private Integer totalUploads;
    private Integer thisWeekUploads;
    private Integer overdueDays;
    private Integer currentScore;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
