package com.yicai.trade.common.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.ai.config.AIModelProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Component
public class ZhipuAIClient implements AIClient {

    private final AIModelProperties.ModelConfig config;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public ZhipuAIClient(AIModelProperties properties, RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.config = properties.getModels().get("zhipu");
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public AIResponse call(AIRequest request) {
        if (!isEnabled()) {
            return AIResponse.builder()
                    .success(false)
                    .errorMessage("Zhipu AI model is disabled")
                    .build();
        }

        try {
            Map<String, Object> body = new HashMap<>();
            body.put("model", config.getModelId());
            
            List<Map<String, String>> messages = request.getMessages().stream()
                    .map(msg -> {
                        Map<String, String> msgMap = new HashMap<>();
                        msgMap.put("role", msg.getRole());
                        msgMap.put("content", msg.getContent());
                        return msgMap;
                    })
                    .collect(Collectors.toList());
            
            body.put("messages", messages);
            
            if (request.getTemperature() != null) {
                body.put("temperature", request.getTemperature());
            }
            if (request.getMaxTokens() != null) {
                body.put("max_tokens", request.getMaxTokens());
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(config.getApiKey());

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

            String url = config.getEndpoint() + "/chat/completions";
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            String content = root.path("choices").get(0).path("message").path("content").asText();
            int tokensUsed = root.path("usage").path("total_tokens").asInt();

            return AIResponse.builder()
                    .content(content)
                    .model(config.getModelId())
                    .tokensUsed(tokensUsed)
                    .success(true)
                    .build();

        } catch (Exception e) {
            log.error("Error calling Zhipu AI API", e);
            return AIResponse.builder()
                    .success(false)
                    .errorMessage(e.getMessage())
                    .build();
        }
    }

    @Override
    public String getModelName() {
        return "zhipu";
    }

    @Override
    public boolean isEnabled() {
        return config != null && Boolean.TRUE.equals(config.getEnabled());
    }
}
