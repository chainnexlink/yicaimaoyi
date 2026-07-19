package com.yicai.trade.module.monitor.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.monitor.dto.*;

import java.util.List;

/**
 * 生产监控服务接口
 * 三方闭环：供应商上传、采购商查看、平台管理
 */
public interface MonitorService {

    // ==================== 监控配置（采购商/平台） ====================

    /**
     * 创建/更新监控配置
     */
    MonitorSettingResponse createOrUpdateSetting(Long buyerId, MonitorSettingRequest request);

    /**
     * 获取订单的监控配置
     */
    MonitorSettingResponse getSettingByOrder(Long orderId);

    /**
     * 启用/禁用监控
     */
    void toggleMonitor(Long orderId, Boolean active);

    /**
     * 采购商的所有监控配置
     */
    List<MonitorSettingResponse> listBuyerSettings(Long buyerId);

    /**
     * 供应商的所有监控配置
     */
    List<MonitorSettingResponse> listSupplierSettings(Long supplierId);

    // ==================== 生产监控上传（供应商） ====================

    /**
     * 供应商上传监控记录
     */
    MonitorResponse uploadMonitor(Long supplierId, MonitorUploadRequest request);

    /**
     * 获取监控详情
     */
    MonitorResponse getMonitor(Long monitorId);

    /**
     * 更新监控阶段
     */
    void updateStage(Long orderId, String stage);

    /**
     * 供应商的监控记录列表
     */
    PageResult<MonitorResponse> listSupplierMonitors(Long supplierId, int page, int size);

    /**
     * 订单的监控记录列表
     */
    PageResult<MonitorResponse> listOrderMonitors(Long orderId, int page, int size);

    // ==================== 采购商查看 ====================

    /**
     * 采购商查看监控
     */
    MonitorResponse viewMonitor(Long monitorId, Long buyerId);

    /**
     * 采购商提交反馈和评分
     */
    void submitFeedback(Long monitorId, Long buyerId, String feedback, Integer rating);

    /**
     * 采购商的监控记录列表
     */
    PageResult<MonitorResponse> listBuyerMonitors(Long buyerId, int page, int size);

    /**
     * 采购商未读监控数量
     */
    long countUnviewedMonitors(Long buyerId);

    // ==================== 平台审核 ====================

    /**
     * 平台审核监控
     */
    MonitorResponse reviewMonitor(Long monitorId, Long reviewerId, String reviewerName, 
                                  boolean approved, String note);

    /**
     * 待审核监控列表
     */
    PageResult<MonitorResponse> listPendingReviews(int page, int size);

    /**
     * 标记质量问题
     */
    void markQualityIssue(Long monitorId, String note);

    // ==================== 质检报告 ====================

    /**
     * 供应商提交质检报告
     */
    QualityReportResponse submitQualityReport(Long supplierId, QualityReportRequest request);

    /**
     * 获取质检报告
     */
    QualityReportResponse getQualityReport(Long reportId);

    /**
     * 订单的质检报告列表
     */
    List<QualityReportResponse> listOrderReports(Long orderId);

    /**
     * 平台审核质检报告
     */
    QualityReportResponse reviewQualityReport(Long reportId, Long reviewerId, boolean approved);

    // ==================== 预警中心 ====================

    /**
     * 获取预警列表
     */
    PageResult<AlertResponse> listAlerts(Long buyerId, String status, int page, int size);

    /**
     * 解决预警
     */
    void resolveAlert(Long alertId, Long resolverId, String note);

    /**
     * 活跃预警数量
     */
    long countActiveAlerts(Long buyerId);

    /**
     * 供应商预警数量
     */
    long countSupplierAlerts(Long supplierId);
}
