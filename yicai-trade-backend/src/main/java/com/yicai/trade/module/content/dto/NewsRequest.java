package com.yicai.trade.module.content.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class NewsRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String summary;
    private String content;
    private String coverImage;
    private String category = "NEWS";
    private Boolean isTop = false;
    private Boolean isRecommend = false;
    private String status = "DRAFT";
}
