package com.yicai.trade.module.monitor.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.monitor.dto.*;
import com.yicai.trade.module.monitor.service.MonitorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 生产监控控制器
 * 三方闭环：供应商上传、采购商查看、平台管理
 */
@RestController
@RequestMapping("/api/monitors")
@RequiredArgsConstructor
@Tag(name = "ProductionMonitor", description = "生产监控（三方闭环）")
public class MonitorController {

    private final MonitorService monitorService;

    // ==================== 监控配置（采购商） ====================

    @PostMapping("/settings")
    @Operation(summary = "创建/更新监控配置", description = "采购商为订单设置监控要求")
    public Result<MonitorSettingResponse> createOrUpdateSetting(
            @RequestParam Long buyerId,
            @RequestBody @Valid MonitorSettingRequest request) {
        return Result.success(monitorService.createOrUpdateSetting(buyerId, request));
    }

    @GetMapping("/settings/order/{orderId}")
    @Operation(summary = "获取订单监控配置")
    public Result<MonitorSettingResponse> getSettingByOrder(@PathVariable Long orderId) {
        return Result.success(monitorService.getSettingByOrder(orderId));
    }

    @PutMapping("/settings/order/{orderId}/toggle")
    @Operation(summary = "启用/禁用监控")
    public Result<Void> toggleMonitor(@PathVariable Long orderId, @RequestParam Boolean active) {
        monitorService.toggleMonitor(orderId, active);
        return Result.success();
    }

    @GetMapping("/settings/buyer/{buyerId}")
    @Operation(summary = "采购商的监控配置列表")
    public Result<List<MonitorSettingResponse>> listBuyerSettings(@PathVariable Long buyerId) {
        return Result.success(monitorService.listBuyerSettings(buyerId));
    }

    @GetMapping("/settings/supplier/{supplierId}")
    @Operation(summary = "供应商的监控配置列表")
    public Result<List<MonitorSettingResponse>> listSupplierSettings(@PathVariable Long supplierId) {
        return Result.success(monitorService.listSupplierSettings(supplierId));
    }

    // ==================== 监控上传（供应商） ====================

    @PostMapping("/upload")
    @Operation(summary = "上传生产监控", description = "供应商上传图片/视频/进度")
    public Result<MonitorResponse> uploadMonitor(
            @RequestParam Long supplierId,
            @RequestBody @Valid MonitorUploadRequest request) {
        return Result.success(monitorService.uploadMonitor(supplierId, request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取监控详情")
    public Result<MonitorResponse> getMonitor(@PathVariable Long id) {
        return Result.success(monitorService.getMonitor(id));
    }

    @PutMapping("/order/{orderId}/stage")
    @Operation(summary = "更新生产阶段")
    public Result<Void> updateStage(@PathVariable Long orderId, @RequestParam String stage) {
        monitorService.updateStage(orderId, stage);
        return Result.success();
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "供应商监控列表")
    public Result<PageResult<MonitorResponse>> listSupplierMonitors(
            @PathVariable Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(monitorService.listSupplierMonitors(supplierId, page, size));
    }

    @GetMapping("/order/{orderId}")
    @Operation(summary = "订单监控列表", description = "查看某订单的所有监控记录")
    public Result<PageResult<MonitorResponse>> listOrderMonitors(
            @PathVariable Long orderId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(monitorService.listOrderMonitors(orderId, page, size));
    }

    // ==================== 采购商查看 ====================

    @PostMapping("/{id}/view")
    @Operation(summary = "采购商查看监控", description = "标记为已查看")
    public Result<MonitorResponse> viewMonitor(@PathVariable Long id, @RequestParam Long buyerId) {
        return Result.success(monitorService.viewMonitor(id, buyerId));
    }

    @PostMapping("/{id}/feedback")
    @Operation(summary = "采购商提交反馈", description = "反馈和评分")
    public Result<Void> submitFeedback(
            @PathVariable Long id,
            @RequestParam Long buyerId,
            @RequestParam(required = false) String feedback,
            @RequestParam(required = false) Integer rating) {
        monitorService.submitFeedback(id, buyerId, feedback, rating);
        return Result.success();
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "采购商监控列表")
    public Result<PageResult<MonitorResponse>> listBuyerMonitors(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(monitorService.listBuyerMonitors(buyerId, page, size));
    }

    @GetMapping("/buyer/{buyerId}/unviewed-count")
    @Operation(summary = "未查看监控数量")
    public Result<Long> countUnviewedMonitors(@PathVariable Long buyerId) {
        return Result.success(monitorService.countUnviewedMonitors(buyerId));
    }

    // ==================== 平台审核 ====================

    @PostMapping("/{id}/review")
    @Operation(summary = "平台审核监控")
    public Result<MonitorResponse> reviewMonitor(
            @PathVariable Long id,
            @RequestParam Long reviewerId,
            @RequestParam String reviewerName,
            @RequestParam boolean approved,
            @RequestParam(required = false) String note) {
        return Result.success(monitorService.reviewMonitor(id, reviewerId, reviewerName, approved, note));
    }

    @GetMapping("/pending-reviews")
    @Operation(summary = "待审核监控列表")
    public Result<PageResult<MonitorResponse>> listPendingReviews(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(monitorService.listPendingReviews(page, size));
    }

    @PostMapping("/{id}/quality-issue")
    @Operation(summary = "标记质量问题")
    public Result<Void> markQualityIssue(@PathVariable Long id, @RequestParam String note) {
        monitorService.markQualityIssue(id, note);
        return Result.success();
    }

    // ==================== 质检报告 ====================

    @PostMapping("/quality-reports")
    @Operation(summary = "提交质检报告", description = "供应商上传质检报告")
    public Result<QualityReportResponse> submitQualityReport(
            @RequestParam Long supplierId,
            @RequestBody @Valid QualityReportRequest request) {
        return Result.success(monitorService.submitQualityReport(supplierId, request));
    }

    @GetMapping("/quality-reports/{id}")
    @Operation(summary = "获取质检报告")
    public Result<QualityReportResponse> getQualityReport(@PathVariable Long id) {
        return Result.success(monitorService.getQualityReport(id));
    }

    @GetMapping("/quality-reports/order/{orderId}")
    @Operation(summary = "订单质检报告列表")
    public Result<List<QualityReportResponse>> listOrderReports(@PathVariable Long orderId) {
        return Result.success(monitorService.listOrderReports(orderId));
    }

    @PostMapping("/quality-reports/{id}/review")
    @Operation(summary = "审核质检报告")
    public Result<QualityReportResponse> reviewQualityReport(
            @PathVariable Long id,
            @RequestParam Long reviewerId,
            @RequestParam boolean approved) {
        return Result.success(monitorService.reviewQualityReport(id, reviewerId, approved));
    }

    // ==================== 预警中心 ====================

    @GetMapping("/alerts/buyer/{buyerId}")
    @Operation(summary = "采购商预警列表")
    public Result<PageResult<AlertResponse>> listAlerts(
            @PathVariable Long buyerId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(monitorService.listAlerts(buyerId, status, page, size));
    }

    @PostMapping("/alerts/{id}/resolve")
    @Operation(summary = "解决预警")
    public Result<Void> resolveAlert(
            @PathVariable Long id,
            @RequestParam Long resolverId,
            @RequestParam(required = false) String note) {
        monitorService.resolveAlert(id, resolverId, note);
        return Result.success();
    }

    @GetMapping("/alerts/buyer/{buyerId}/active-count")
    @Operation(summary = "活跃预警数量")
    public Result<Long> countActiveAlerts(@PathVariable Long buyerId) {
        return Result.success(monitorService.countActiveAlerts(buyerId));
    }

    @GetMapping("/alerts/supplier/{supplierId}/count")
    @Operation(summary = "供应商预警数量")
    public Result<Long> countSupplierAlerts(@PathVariable Long supplierId) {
        return Result.success(monitorService.countSupplierAlerts(supplierId));
    }
}
