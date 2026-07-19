package com.yicai.trade.module.smartmatch.service;

import com.yicai.trade.module.smartmatch.dto.*;

public interface SmartMatchService {
    
    CategoryMatchResponse matchCategories(String productName, String imageUrl, String lang);
    
    ParameterResponse getCostParameters(ParameterRequest request, String lang);
    
    ParameterResponse getFOBParameters(ParameterRequest request, String lang);
    
    CostEstimateResponse estimateCost(CostEstimateRequest request, String lang);
    
    FOBEstimateResponse estimateFOB(FOBEstimateRequest request, String lang);

    FactoryQuoteResponse estimateFactoryQuote(String sessionId, String categoryCode, String lang);
}
