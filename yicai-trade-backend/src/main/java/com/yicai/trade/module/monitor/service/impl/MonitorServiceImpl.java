package com.yicai.trade.module.monitor.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.monitor.dto.*;
import com.yicai.trade.module.monitor.entity.*;
import com.yicai.trade.module.monitor.repository.*;
import com.yicai.trade.module.monitor.service.MonitorService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MonitorServiceImpl implements MonitorService {

    private final MonitorSettingRepository settingRepository;
    private final ProductionMonitorRepository monitorRepository;
    private final QualityReportRepository reportRepository;
    private final MonitorAlertRepository alertRepository;
    private final OrderRepository orderRepository;
    private final ObjectMapper objectMapper;

    // ==================== 监控配置 ====================

    @Override
    @Transactional
    public MonitorSettingResponse createOrUpdateSetting(Long buyerId, MonitorSettingRequest request) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));

        MonitorSetting setting = settingRepository.findByOrderId(request.getOrderId())
                .orElse(MonitorSetting.builder()
                        .orderId(request.getOrderId())
                        .buyerId(buyerId)
                        .supplierId(order.getSupplierId())
                        .build());

        setting.setContractId(request.getContractId());
        setting.setUploadFrequency(request.getUploadFrequency() != null ? request.getUploadFrequency() : "WEEKLY");
        setting.setMinUploadsPerPeriod(request.getMinUploadsPerPeriod() != null ? request.getMinUploadsPerPeriod() : 1);
        setting.setRequirePhoto(request.getRequirePhoto() != null ? request.getRequirePhoto() : true);
        setting.setRequireVideo(request.getRequireVideo() != null ? request.getRequireVideo() : false);
        setting.setRequireDescription(request.getRequireDescription() != null ? request.getRequireDescription() : true);

        if (request.getMonitorStages() != null && !request.getMonitorStages().isEmpty()) {
            try {
                setting.setMonitorStages(objectMapper.writeValueAsString(request.getMonitorStages()));
                setting.setCurrentStage(request.getMonitorStages().get(0));
            } catch (JsonProcessingException e) {
                throw new BusinessException(ErrorCode.SYSTEM_ERROR, "监控阶段格式错误");
            }
        }

        setting.setStartDate(request.getStartDate() != null ? request.getStartDate() : LocalDate.now());
        setting.setEndDate(request.getEndDate());
        setting.setWeightInScore(request.getWeightInScore() != null ? request.getWeightInScore() : 20);
        setting.setIsActive(true);

        settingRepository.save(setting);
        return toSettingResponse(setting, order.getOrderNo());
    }

    @Override
    public MonitorSettingResponse getSettingByOrder(Long orderId) {
        MonitorSetting setting = settingRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控配置不存在"));
        Order order = orderRepository.findById(orderId).orElse(null);
        return toSettingResponse(setting, order != null ? order.getOrderNo() : null);
    }

    @Override
    @Transactional
    public void toggleMonitor(Long orderId, Boolean active) {
        MonitorSetting setting = settingRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控配置不存在"));
        setting.setIsActive(active);
        settingRepository.save(setting);
    }

    @Override
    public List<MonitorSettingResponse> listBuyerSettings(Long buyerId) {
        return settingRepository.findByBuyerIdAndIsActiveTrue(buyerId).stream()
                .map(s -> {
                    Order order = orderRepository.findById(s.getOrderId()).orElse(null);
                    return toSettingResponse(s, order != null ? order.getOrderNo() : null);
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<MonitorSettingResponse> listSupplierSettings(Long supplierId) {
        return settingRepository.findBySupplierIdAndIsActiveTrue(supplierId).stream()
                .map(s -> {
                    Order order = orderRepository.findById(s.getOrderId()).orElse(null);
                    return toSettingResponse(s, order != null ? order.getOrderNo() : null);
                })
                .collect(Collectors.toList());
    }

    // ==================== 生产监控上传 ====================

    @Override
    @Transactional
    public MonitorResponse uploadMonitor(Long supplierId, MonitorUploadRequest request) {
        MonitorSetting setting = settingRepository.findByOrderId(request.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "请先启用生产监控"));

        if (!setting.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.ACCESS_DENIED, "无权上传此订单的监控");
        }

        if (!Boolean.TRUE.equals(setting.getIsActive())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "监控已关闭");
        }

        ProductionMonitor monitor = ProductionMonitor.builder()
                .monitorSettingId(setting.getId())
                .orderId(request.getOrderId())
                .supplierId(supplierId)
                .buyerId(setting.getBuyerId())
                .title(request.getTitle())
                .description(request.getDescription())
                .stage(request.getStage() != null ? request.getStage() : setting.getCurrentStage())
                .progressPercent(request.getProgressPercent())
                .uploadType(request.getUploadType() != null ? request.getUploadType() : "SCHEDULED")
                .uploaderId(supplierId)
                .uploaderName(request.getUploaderName())
                .build();

        try {
            if (request.getPhotos() != null) {
                monitor.setPhotos(objectMapper.writeValueAsString(request.getPhotos()));
            }
            if (request.getVideos() != null) {
                monitor.setVideos(objectMapper.writeValueAsString(request.getVideos()));
            }
            if (request.getAttachments() != null) {
                monitor.setAttachments(objectMapper.writeValueAsString(request.getAttachments()));
            }
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "媒体文件格式错误");
        }

        // 更新当前阶段
        if (request.getStage() != null) {
            setting.setCurrentStage(request.getStage());
            settingRepository.save(setting);
        }

        monitorRepository.save(monitor);
        return toMonitorResponse(monitor);
    }

    @Override
    public MonitorResponse getMonitor(Long monitorId) {
        ProductionMonitor monitor = monitorRepository.findById(monitorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控记录不存在"));
        return toMonitorResponse(monitor);
    }

    @Override
    @Transactional
    public void updateStage(Long orderId, String stage) {
        MonitorSetting setting = settingRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控配置不存在"));
        setting.setCurrentStage(stage);
        settingRepository.save(setting);
    }

    @Override
    public PageResult<MonitorResponse> listSupplierMonitors(Long supplierId, int page, int size) {
        Page<ProductionMonitor> monitors = monitorRepository.findBySupplierIdOrderByCreatedAtDesc(
                supplierId, PageRequest.of(page, size));
        return toMonitorPageResult(monitors);
    }

    @Override
    public PageResult<MonitorResponse> listOrderMonitors(Long orderId, int page, int size) {
        Page<ProductionMonitor> monitors = monitorRepository.findByOrderIdOrderByCreatedAtDesc(
                orderId, PageRequest.of(page, size));
        return toMonitorPageResult(monitors);
    }

    // ==================== 采购商查看 ====================

    @Override
    @Transactional
    public MonitorResponse viewMonitor(Long monitorId, Long buyerId) {
        ProductionMonitor monitor = monitorRepository.findById(monitorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控记录不存在"));

        if (!monitor.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.ACCESS_DENIED, "无权查看此监控");
        }

        if (!Boolean.TRUE.equals(monitor.getBuyerViewed())) {
            monitor.setBuyerViewed(true);
            monitor.setBuyerViewedAt(LocalDateTime.now());
            monitorRepository.save(monitor);
        }

        return toMonitorResponse(monitor);
    }

    @Override
    @Transactional
    public void submitFeedback(Long monitorId, Long buyerId, String feedback, Integer rating) {
        ProductionMonitor monitor = monitorRepository.findById(monitorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控记录不存在"));

        if (!monitor.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.ACCESS_DENIED, "无权评价此监控");
        }

        monitor.setBuyerFeedback(feedback);
        monitor.setBuyerRating(rating);
        monitorRepository.save(monitor);
    }

    @Override
    public PageResult<MonitorResponse> listBuyerMonitors(Long buyerId, int page, int size) {
        Page<ProductionMonitor> monitors = monitorRepository.findByBuyerIdOrderByCreatedAtDesc(
                buyerId, PageRequest.of(page, size));
        return toMonitorPageResult(monitors);
    }

    @Override
    public long countUnviewedMonitors(Long buyerId) {
        return monitorRepository.findByBuyerIdAndBuyerViewedFalseOrderByCreatedAtDesc(buyerId).size();
    }

    // ==================== 平台审核 ====================

    @Override
    @Transactional
    public MonitorResponse reviewMonitor(Long monitorId, Long reviewerId, String reviewerName, 
                                         boolean approved, String note) {
        ProductionMonitor monitor = monitorRepository.findById(monitorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控记录不存在"));

        monitor.setReviewStatus(approved ? "APPROVED" : "REJECTED");
        monitor.setReviewerId(reviewerId);
        monitor.setReviewerName(reviewerName);
        monitor.setReviewedAt(LocalDateTime.now());
        monitor.setReviewNote(note);

        monitorRepository.save(monitor);
        return toMonitorResponse(monitor);
    }

    @Override
    public PageResult<MonitorResponse> listPendingReviews(int page, int size) {
        Page<ProductionMonitor> monitors = monitorRepository.findByReviewStatusOrderByCreatedAtDesc(
                "PENDING", PageRequest.of(page, size));
        return toMonitorPageResult(monitors);
    }

    @Override
    @Transactional
    public void markQualityIssue(Long monitorId, String note) {
        ProductionMonitor monitor = monitorRepository.findById(monitorId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "监控记录不存在"));

        monitor.setHasQualityIssue(true);
        monitor.setQualityIssueNote(note);
        monitorRepository.save(monitor);

        // 创建预警
        MonitorAlert alert = MonitorAlert.builder()
                .orderId(monitor.getOrderId())
                .monitorSettingId(monitor.getMonitorSettingId())
                .supplierId(monitor.getSupplierId())
                .buyerId(monitor.getBuyerId())
                .alertType("QUALITY_ISSUE")
                .alertLevel("WARNING")
                .alertTitle("质量问题预警")
                .alertContent(note)
                .build();
        alertRepository.save(alert);
    }

    // ==================== 质检报告 ====================

    @Override
    @Transactional
    public QualityReportResponse submitQualityReport(Long supplierId, QualityReportRequest request) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));

        if (!order.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.ACCESS_DENIED, "无权提交此订单的质检报告");
        }

        String reportNo = "QR" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));

        BigDecimal passRate = null;
        if (request.getSampleCount() != null && request.getSampleCount() > 0) {
            int passCount = request.getPassCount() != null ? request.getPassCount() : 0;
            passRate = BigDecimal.valueOf(passCount * 100.0 / request.getSampleCount())
                    .setScale(2, RoundingMode.HALF_UP);
        }

        QualityReport report = QualityReport.builder()
                .orderId(request.getOrderId())
                .monitorId(request.getMonitorId())
                .supplierId(supplierId)
                .buyerId(order.getBuyerId())
                .reportNo(reportNo)
                .reportType(request.getReportType() != null ? request.getReportType() : "INTERIM")
                .reportTitle(request.getReportTitle())
                .inspectionDate(request.getInspectionDate())
                .inspectorName(request.getInspectorName())
                .sampleCount(request.getSampleCount())
                .passCount(request.getPassCount())
                .failCount(request.getFailCount())
                .passRate(passRate)
                .conclusion(request.getConclusion() != null ? request.getConclusion() : "PENDING")
                .conclusionNote(request.getConclusionNote())
                .reportPdfUrl(request.getReportPdfUrl())
                .status("SUBMITTED")
                .build();

        try {
            if (request.getInspectionItems() != null) {
                report.setInspectionItems(objectMapper.writeValueAsString(request.getInspectionItems()));
            }
            if (request.getPhotos() != null) {
                report.setPhotos(objectMapper.writeValueAsString(request.getPhotos()));
            }
        } catch (JsonProcessingException e) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "数据格式错误");
        }

        reportRepository.save(report);
        return toReportResponse(report);
    }

    @Override
    public QualityReportResponse getQualityReport(Long reportId) {
        QualityReport report = reportRepository.findById(reportId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "质检报告不存在"));
        return toReportResponse(report);
    }

    @Override
    public List<QualityReportResponse> listOrderReports(Long orderId) {
        return reportRepository.findByOrderIdOrderByCreatedAtDesc(orderId).stream()
                .map(this::toReportResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public QualityReportResponse reviewQualityReport(Long reportId, Long reviewerId, boolean approved) {
        QualityReport report = reportRepository.findById(reportId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "质检报告不存在"));

        report.setStatus("REVIEWED");
        report.setReviewedBy(reviewerId);
        report.setReviewedAt(LocalDateTime.now());

        reportRepository.save(report);
        return toReportResponse(report);
    }

    // ==================== 预警中心 ====================

    @Override
    public PageResult<AlertResponse> listAlerts(Long buyerId, String status, int page, int size) {
        Page<MonitorAlert> alerts;
        if (status != null && !status.isBlank()) {
            alerts = alertRepository.findByBuyerIdAndStatusOrderByCreatedAtDesc(
                    buyerId, status, PageRequest.of(page, size));
        } else {
            alerts = alertRepository.findByBuyerIdAndStatusOrderByCreatedAtDesc(
                    buyerId, "ACTIVE", PageRequest.of(page, size));
        }
        return toAlertPageResult(alerts);
    }

    @Override
    @Transactional
    public void resolveAlert(Long alertId, Long resolverId, String note) {
        MonitorAlert alert = alertRepository.findById(alertId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "预警不存在"));

        alert.setStatus("RESOLVED");
        alert.setResolvedBy(resolverId);
        alert.setResolvedAt(LocalDateTime.now());
        alert.setResolutionNote(note);

        alertRepository.save(alert);
    }

    @Override
    public long countActiveAlerts(Long buyerId) {
        return alertRepository.countByBuyerIdAndStatus(buyerId, "ACTIVE");
    }

    @Override
    public long countSupplierAlerts(Long supplierId) {
        return alertRepository.countBySupplierIdAndStatus(supplierId, "ACTIVE");
    }

    // ==================== 私有方法：转换 ====================

    private MonitorSettingResponse toSettingResponse(MonitorSetting setting, String orderNo) {
        List<String> stages = new ArrayList<>();
        if (setting.getMonitorStages() != null) {
            try {
                stages = objectMapper.readValue(setting.getMonitorStages(), new TypeReference<>() {});
            } catch (JsonProcessingException ignored) {}
        }

        long totalUploads = monitorRepository.countByOrderId(setting.getOrderId());

        return MonitorSettingResponse.builder()
                .id(setting.getId())
                .orderId(setting.getOrderId())
                .orderNo(orderNo)
                .contractId(setting.getContractId())
                .buyerId(setting.getBuyerId())
                .supplierId(setting.getSupplierId())
                .uploadFrequency(setting.getUploadFrequency())
                .minUploadsPerPeriod(setting.getMinUploadsPerPeriod())
                .requirePhoto(setting.getRequirePhoto())
                .requireVideo(setting.getRequireVideo())
                .requireDescription(setting.getRequireDescription())
                .monitorStages(stages)
                .currentStage(setting.getCurrentStage())
                .isActive(setting.getIsActive())
                .startDate(setting.getStartDate())
                .endDate(setting.getEndDate())
                .weightInScore(setting.getWeightInScore())
                .totalUploads((int) totalUploads)
                .createdAt(setting.getCreatedAt())
                .updatedAt(setting.getUpdatedAt())
                .build();
    }

    private MonitorResponse toMonitorResponse(ProductionMonitor monitor) {
        List<MonitorResponse.MediaFileInfo> photos = parseMediaFiles(monitor.getPhotos());
        List<MonitorResponse.MediaFileInfo> videos = parseMediaFiles(monitor.getVideos());
        List<MonitorResponse.MediaFileInfo> attachments = parseMediaFiles(monitor.getAttachments());

        return MonitorResponse.builder()
                .id(monitor.getId())
                .orderId(monitor.getOrderId())
                .supplierId(monitor.getSupplierId())
                .buyerId(monitor.getBuyerId())
                .title(monitor.getTitle())
                .description(monitor.getDescription())
                .stage(monitor.getStage())
                .progressPercent(monitor.getProgressPercent())
                .photos(photos)
                .videos(videos)
                .attachments(attachments)
                .uploadType(monitor.getUploadType())
                .uploaderId(monitor.getUploaderId())
                .uploaderName(monitor.getUploaderName())
                .reviewStatus(monitor.getReviewStatus())
                .reviewerId(monitor.getReviewerId())
                .reviewerName(monitor.getReviewerName())
                .reviewedAt(monitor.getReviewedAt())
                .reviewNote(monitor.getReviewNote())
                .buyerViewed(monitor.getBuyerViewed())
                .buyerViewedAt(monitor.getBuyerViewedAt())
                .buyerFeedback(monitor.getBuyerFeedback())
                .buyerRating(monitor.getBuyerRating())
                .isOverdue(monitor.getIsOverdue())
                .overdueDays(monitor.getOverdueDays())
                .hasQualityIssue(monitor.getHasQualityIssue())
                .qualityIssueNote(monitor.getQualityIssueNote())
                .createdAt(monitor.getCreatedAt())
                .updatedAt(monitor.getUpdatedAt())
                .build();
    }

    private List<MonitorResponse.MediaFileInfo> parseMediaFiles(String json) {
        if (json == null || json.isBlank()) return new ArrayList<>();
        try {
            List<MonitorUploadRequest.MediaFile> files = objectMapper.readValue(
                    json, new TypeReference<>() {});
            return files.stream()
                    .map(f -> MonitorResponse.MediaFileInfo.builder()
                            .url(f.getUrl())
                            .thumbnail(f.getThumbnail())
                            .size(f.getSize())
                            .duration(f.getDuration())
                            .fileName(f.getFileName())
                            .fileType(f.getFileType())
                            .build())
                    .collect(Collectors.toList());
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }

    private PageResult<MonitorResponse> toMonitorPageResult(Page<ProductionMonitor> page) {
        return PageResult.<MonitorResponse>builder()
                .content(page.getContent().stream().map(this::toMonitorResponse).collect(Collectors.toList()))
                .pageNumber(page.getNumber())
                .pageSize(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .build();
    }

    private QualityReportResponse toReportResponse(QualityReport report) {
        List<QualityReportResponse.InspectionItemInfo> items = new ArrayList<>();
        if (report.getInspectionItems() != null) {
            try {
                List<QualityReportRequest.InspectionItem> reqItems = objectMapper.readValue(
                        report.getInspectionItems(), new TypeReference<>() {});
                items = reqItems.stream()
                        .map(i -> QualityReportResponse.InspectionItemInfo.builder()
                                .item(i.getItem())
                                .standard(i.getStandard())
                                .actualValue(i.getActualValue())
                                .result(i.getResult())
                                .note(i.getNote())
                                .build())
                        .collect(Collectors.toList());
            } catch (JsonProcessingException ignored) {}
        }

        List<String> photos = new ArrayList<>();
        if (report.getPhotos() != null) {
            try {
                photos = objectMapper.readValue(report.getPhotos(), new TypeReference<>() {});
            } catch (JsonProcessingException ignored) {}
        }

        return QualityReportResponse.builder()
                .id(report.getId())
                .orderId(report.getOrderId())
                .monitorId(report.getMonitorId())
                .supplierId(report.getSupplierId())
                .buyerId(report.getBuyerId())
                .reportNo(report.getReportNo())
                .reportType(report.getReportType())
                .reportTitle(report.getReportTitle())
                .inspectionDate(report.getInspectionDate())
                .inspectorName(report.getInspectorName())
                .sampleCount(report.getSampleCount())
                .passCount(report.getPassCount())
                .failCount(report.getFailCount())
                .passRate(report.getPassRate())
                .inspectionItems(items)
                .conclusion(report.getConclusion())
                .conclusionNote(report.getConclusionNote())
                .reportPdfUrl(report.getReportPdfUrl())
                .photos(photos)
                .status(report.getStatus())
                .reviewedBy(report.getReviewedBy())
                .reviewedAt(report.getReviewedAt())
                .createdAt(report.getCreatedAt())
                .updatedAt(report.getUpdatedAt())
                .build();
    }

    private PageResult<AlertResponse> toAlertPageResult(Page<MonitorAlert> page) {
        return PageResult.<AlertResponse>builder()
                .content(page.getContent().stream().map(this::toAlertResponse).collect(Collectors.toList()))
                .pageNumber(page.getNumber())
                .pageSize(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .build();
    }

    private AlertResponse toAlertResponse(MonitorAlert alert) {
        return AlertResponse.builder()
                .id(alert.getId())
                .orderId(alert.getOrderId())
                .supplierId(alert.getSupplierId())
                .buyerId(alert.getBuyerId())
                .alertType(alert.getAlertType())
                .alertLevel(alert.getAlertLevel())
                .alertTitle(alert.getAlertTitle())
                .alertContent(alert.getAlertContent())
                .status(alert.getStatus())
                .resolvedBy(alert.getResolvedBy())
                .resolvedAt(alert.getResolvedAt())
                .resolutionNote(alert.getResolutionNote())
                .buyerNotified(alert.getBuyerNotified())
                .supplierNotified(alert.getSupplierNotified())
                .platformNotified(alert.getPlatformNotified())
                .createdAt(alert.getCreatedAt())
                .build();
    }
}
