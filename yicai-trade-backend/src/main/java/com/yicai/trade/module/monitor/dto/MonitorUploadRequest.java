package com.yicai.trade.module.monitor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;

/**
 * 供应商上传生产监控请求
 */
@Data
public class MonitorUploadRequest {
    @NotNull(message = "订单ID不能为空")
    private Long orderId;

    @NotBlank(message = "监控标题不能为空")
    private String title;

    private String description;

    private String stage;

    private Integer progressPercent;

    /**
     * 图片URL列表 [{url, thumbnail, size}]
     */
    private List<MediaFile> photos;

    /**
     * 视频URL列表 [{url, thumbnail, duration}]
     */
    private List<MediaFile> videos;

    /**
     * 附件列表
     */
    private List<MediaFile> attachments;

    /**
     * 上传类型：SCHEDULED(定期)、EXTRA(额外)、URGENT(紧急)
     */
    private String uploadType;

    private String uploaderName;

    @Data
    public static class MediaFile {
        private String url;
        private String thumbnail;
        private Long size;
        private Integer duration;
        private String fileName;
        private String fileType;
    }
}
