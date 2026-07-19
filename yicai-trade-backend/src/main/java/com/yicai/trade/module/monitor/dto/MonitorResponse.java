package com.yicai.trade.module.monitor.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 生产监控响应
 */
@Data
@Builder
public class MonitorResponse {
    private Long id;
    private Long orderId;
    private String orderNo;
    private Long supplierId;
    private String supplierName;
    private Long buyerId;
    private String buyerName;

    private String title;
    private String description;
    private String stage;
    private Integer progressPercent;

    private List<MediaFileInfo> photos;
    private List<MediaFileInfo> videos;
    private List<MediaFileInfo> attachments;

    private String uploadType;
    private Long uploaderId;
    private String uploaderName;

    // 审核状态
    private String reviewStatus;
    private Long reviewerId;
    private String reviewerName;
    private LocalDateTime reviewedAt;
    private String reviewNote;

    // 采购商查看状态
    private Boolean buyerViewed;
    private LocalDateTime buyerViewedAt;
    private String buyerFeedback;
    private Integer buyerRating;

    // 预警信息
    private Boolean isOverdue;
    private Integer overdueDays;
    private Boolean hasQualityIssue;
    private String qualityIssueNote;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @Builder
    public static class MediaFileInfo {
        private String url;
        private String thumbnail;
        private Long size;
        private Integer duration;
        private String fileName;
        private String fileType;
    }
}
