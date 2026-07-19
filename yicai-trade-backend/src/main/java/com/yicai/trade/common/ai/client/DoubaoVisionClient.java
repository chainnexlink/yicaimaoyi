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
public class DoubaoVisionClient implements AIClient {

    private final AIModelProperties.ModelConfig config;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public DoubaoVisionClient(AIModelProperties properties, RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.config = properties.getModels().get("doubao-vision");
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public AIResponse call(AIRequest request) {
        if (!isEnabled()) {
            return AIResponse.builder()
                    .success(false)
                    .errorMessage("Doubao Vision model is disabled")
                    .build();
        }

        try {
            Map<String, Object> body = new HashMap<>();
            body.put("model", config.getModelId());
            
            List<Map<String, Object>> messages = request.getMessages().stream()
                    .map(msg -> {
                        Map<String, Object> msgMap = new HashMap<>();
                        msgMap.put("role", msg.getRole());
                        
                        if (msg.getContentParts() != null && !msg.getContentParts().isEmpty()) {
                            List<Map<String, Object>> contentParts = msg.getContentParts().stream()
                                    .map(part -> {
                                        Map<String, Object> partMap = new HashMap<>();
                                        partMap.put("type", part.getType());
                                        if ("text".equals(part.getType())) {
                                            partMap.put("text", part.getText());
                                        } else if ("image_url".equals(part.getType())) {
                                            partMap.put("image_url", Map.of("url", part.getImageUrl().getUrl()));
                                        }
                                        return partMap;
                                    })
                                    .collect(Collectors.toList());
                            msgMap.put("content", contentParts);
                        } else {
                            msgMap.put("content", msg.getContent());
                        }
                        
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
            log.error("Error calling Doubao Vision API", e);
            return AIResponse.builder()
                    .success(false)
                    .errorMessage(e.getMessage())
                    .build();
        }
    }

    @Override
    public String getModelName() {
        return "doubao-vision";
    }

    @Override
    public boolean isEnabled() {
        return config != null && Boolean.TRUE.equals(config.getEnabled());
    }
}
