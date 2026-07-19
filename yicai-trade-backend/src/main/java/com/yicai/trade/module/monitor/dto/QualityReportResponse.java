package com.yicai.trade.module.monitor.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 质检报告响应
 */
@Data
@Builder
public class QualityReportResponse {
    private Long id;
    private Long orderId;
    private String orderNo;
    private Long monitorId;
    private Long supplierId;
    private String supplierName;
    private Long buyerId;
    private String buyerName;

    private String reportNo;
    private String reportType;
    private String reportTitle;

    private LocalDate inspectionDate;
    private String inspectorName;
    private Integer sampleCount;
    private Integer passCount;
    private Integer failCount;
    private BigDecimal passRate;

    private List<InspectionItemInfo> inspectionItems;

    private String conclusion;
    private String conclusionNote;

    private String reportPdfUrl;
    private List<String> photos;

    private String status;
    private Long reviewedBy;
    private LocalDateTime reviewedAt;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @Builder
    public static class InspectionItemInfo {
        private String item;
        private String standard;
        private String actualValue;
        private String result;
        private String note;
    }
}
