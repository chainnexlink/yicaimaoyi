package com.yicai.trade.module.smartmatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParameterRequest {
    
    private String sessionId;
    private String categoryCode;
    private String parameterStage;
    private String lang;
}
