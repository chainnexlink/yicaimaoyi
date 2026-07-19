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
public class FOBEstimateRequest {
    
    private String sessionId;
    private String supplierCode;
    private Map<String, String> fobParameters;
    private String lang;
}
