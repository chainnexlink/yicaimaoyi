package com.yicai.trade.module.aiconfig.dto;

import lombok.Data;

@Data
public class AIConfigResponse {
    private String activeModel;
    private Double temperature;
    private Integer maxTokens;
    private Boolean cacheEnabled;
    private Integer cacheTtlMinutes;
    private Integer timeout;
    private Integer maxRetries;
}
