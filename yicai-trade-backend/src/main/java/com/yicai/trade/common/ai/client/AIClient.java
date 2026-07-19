package com.yicai.trade.common.ai.client;

public interface AIClient {
    
    AIResponse call(AIRequest request);
    
    String getModelName();
    
    boolean isEnabled();
}
