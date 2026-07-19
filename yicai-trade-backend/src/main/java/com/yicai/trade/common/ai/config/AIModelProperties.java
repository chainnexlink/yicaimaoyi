package com.yicai.trade.common.ai.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Data
@Configuration
@ConfigurationProperties(prefix = "ai")
public class AIModelProperties {

    private Map<String, ModelConfig> models;
    private Integer timeout = 30000;
    private Integer maxRetries = 3;

    @Data
    public static class ModelConfig {
        private String modelId;
        private String apiKey;
        private String endpoint;
        private Boolean enabled = true;
    }
}
