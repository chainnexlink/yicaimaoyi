package com.yicai.trade.module.monitor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;
import java.util.List;

/**
 * 质检报告请求
 */
@Data
public class QualityReportRequest {
    @NotNull(message = "订单ID不能为空")
    private Long orderId;

    private Long monitorId;

    @NotBlank(message = "报告标题不能为空")
    private String reportTitle;

    /**
     * 报告类型: INTERIM(中期)/FINAL(终期)/SPECIAL(专项)
     */
    private String reportType;

    @NotNull(message = "检验日期不能为空")
    private LocalDate inspectionDate;

    private String inspectorName;
    private Integer sampleCount;
    private Integer passCount;
    private Integer failCount;

    /**
     * 检验项目: [{item, standard, result, note}]
     */
    private List<InspectionItem> inspectionItems;

    /**
     * 结论: PASS/CONDITIONAL_PASS/FAIL/PENDING
     */
    private String conclusion;
    private String conclusionNote;

    private String reportPdfUrl;
    private List<String> photos;

    @Data
    public static class InspectionItem {
        private String item;
        private String standard;
        private String actualValue;
        private String result; // PASS/FAIL
        private String note;
    }
}
