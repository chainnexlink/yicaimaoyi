package com.yicai.trade.module.seooutlink.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SeoBlogBindingRequest {

    @NotBlank(message = "博客平台不能为空")
    private String platform;    // WORDPRESS / BLOGGER / TUMBLR

    @NotBlank(message = "博客地址不能为空")
    private String blogUrl;

    private String username;

    private String appPassword;

    private Boolean autoPublish = true;

    @Min(value = 1, message = "每日发布篇数最少1篇")
    @Max(value = 3, message = "每日发布篇数最多3篇")
    private Integer dailyLimit = 1;
}
