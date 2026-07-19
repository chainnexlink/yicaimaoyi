package com.yicai.trade.module.seooutlink.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SeoBlogBindingResponse {
    private Long id;
    private Long supplierId;
    private String platform;
    private String blogUrl;
    private String username;
    private Boolean autoPublish;
    private Integer dailyLimit;
    private String status;
    private LocalDateTime lastTestAt;
    private Boolean lastTestOk;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
