package com.yicai.trade.module.aiconfig.dto;

import lombok.Data;

@Data
public class AIConfigRequest {
    private String activeModel; // doubao-seed, glm-4
    private Double temperature;
    private Integer maxTokens;
    private Boolean cacheEnabled;
    private Integer cacheTtlMinutes;
}
