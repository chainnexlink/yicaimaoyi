package com.yicai.trade.module.monitor.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;
import java.util.List;

/**
 * 监控配置请求（采购商/平台设置）
 */
@Data
public class MonitorSettingRequest {
    @NotNull(message = "订单ID不能为空")
    private Long orderId;

    private Long contractId;

    /**
     * 上传频率: DAILY/TWICE_WEEKLY/WEEKLY/BIWEEKLY
     */
    private String uploadFrequency;

    /**
     * 每周期最少上传次数
     */
    private Integer minUploadsPerPeriod;

    private Boolean requirePhoto;
    private Boolean requireVideo;
    private Boolean requireDescription;

    /**
     * 监控阶段列表: ["备料","加工","组装","测试","包装"]
     */
    private List<String> monitorStages;

    private LocalDate startDate;
    private LocalDate endDate;

    /**
     * 在供应商评分中的权重(百分比)
     */
    private Integer weightInScore;
}
