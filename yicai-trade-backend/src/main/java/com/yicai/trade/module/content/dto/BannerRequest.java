package com.yicai.trade.module.content.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class BannerRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String imageUrl;
    private String linkUrl;
    private String position = "HOME";
    private Integer sortOrder = 0;
    private String status = "ACTIVE";
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}
