package com.yicai.trade.common.ai.client;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIResponse {
    
    private String content;
    private Map<String, Object> metadata;
    private String model;
    private Integer tokensUsed;
    private Boolean success;
    private String errorMessage;
}
