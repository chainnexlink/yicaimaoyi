package com.yicai.trade.module.smartmatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductParameter {
    
    private String parameterName;
    private String parameterCode;
    private String parameterType;
    private List<String> options;
    private String defaultValue;
    private Boolean allowAIEstimate;
    private String aiEstimateOption;
    private Boolean required;
    private String unit;
    private String description;
}
