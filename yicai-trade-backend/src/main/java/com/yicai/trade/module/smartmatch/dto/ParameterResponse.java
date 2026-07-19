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
public class ParameterResponse {
    
    private String sessionId;
    private String categoryCode;
    private String stage;
    private List<ProductParameter> parameters;
}
