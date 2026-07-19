package com.yicai.trade.module.smartmatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CostEstimateRequest {
    
    private String sessionId;
    private String categoryCode;
    private Map<String, String> parameters;
    private String imageUrl;
    private String lang;
}
