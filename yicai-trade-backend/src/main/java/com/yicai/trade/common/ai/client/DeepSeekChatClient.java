package com.yicai.trade.common.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.ai.config.AIModelProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Component
public class DeepSeekChatClient implements AIClient {

    private final AIModelProperties.ModelConfig config;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public DeepSeekChatClient(AIModelProperties properties, RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.config = properties.getModels().get("deepseek");
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public AIResponse call(AIRequest request) {
        if (!isEnabled()) {
            return AIResponse.builder()
                    .success(false)
                    .errorMessage("DeepSeek model is disabled")
                    .build();
        }
        try {
            Map<String, Object> body = buildRequestBody(request, null);
            return doCall(body);
        } catch (Exception e) {
            log.error("Error calling DeepSeek API", e);
            return AIResponse.builder().success(false).errorMessage(e.getMessage()).build();
        }
    }

    /**
     * Call with function/tool definitions for function calling support.
     */
    public AIResponse callWithTools(AIRequest request, List<Map<String, Object>> tools) {
        if (!isEnabled()) {
            return AIResponse.builder()
                    .success(false)
                    .errorMessage("DeepSeek model is disabled")
                    .build();
        }
        try {
            Map<String, Object> body = buildRequestBody(request, tools);
            return doCallWithToolSupport(body);
        } catch (Exception e) {
            log.error("Error calling DeepSeek API with tools", e);
            return AIResponse.builder().success(false).errorMessage(e.getMessage()).build();
        }
    }

    private Map<String, Object> buildRequestBody(AIRequest request, List<Map<String, Object>> tools) {
        Map<String, Object> body = new HashMap<>();
        body.put("model", config.getModelId());

        List<Map<String, String>> messages = request.getMessages().stream()
                .map(msg -> {
                    Map<String, String> m = new HashMap<>();
                    m.put("role", msg.getRole());
                    m.put("content", msg.getContent());
                    return m;
                })
                .collect(Collectors.toList());
        body.put("messages", messages);

        if (request.getTemperature() != null) {
            body.put("temperature", request.getTemperature());
        }
        if (request.getMaxTokens() != null) {
            body.put("max_tokens", request.getMaxTokens());
        }
        if (tools != null && !tools.isEmpty()) {
            body.put("tools", tools);
            body.put("tool_choice", "auto");
        }
        return body;
    }

    private AIResponse doCall(Map<String, Object> body) throws Exception {
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
    }

    private AIResponse doCallWithToolSupport(Map<String, Object> body) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(config.getApiKey());

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        String url = config.getEndpoint() + "/chat/completions";

        ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
        JsonNode root = objectMapper.readTree(response.getBody());
        JsonNode message = root.path("choices").get(0).path("message");
        int tokensUsed = root.path("usage").path("total_tokens").asInt();

        // Check for tool_calls in response
        JsonNode toolCalls = message.path("tool_calls");
        if (toolCalls.isArray() && toolCalls.size() > 0) {
            // Return raw tool_calls JSON as content, with metadata flag
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("has_tool_calls", true);
            metadata.put("tool_calls", objectMapper.writeValueAsString(toolCalls));
            metadata.put("full_message", objectMapper.writeValueAsString(message));
            return AIResponse.builder()
                    .content(null)
                    .metadata(metadata)
                    .model(config.getModelId())
                    .tokensUsed(tokensUsed)
                    .success(true)
                    .build();
        }

        String content = message.path("content").asText();
        return AIResponse.builder()
                .content(content)
                .model(config.getModelId())
                .tokensUsed(tokensUsed)
                .success(true)
                .build();
    }

    @Override
    public String getModelName() {
        return "deepseek";
    }

    @Override
    public boolean isEnabled() {
        return config != null && Boolean.TRUE.equals(config.getEnabled());
    }
}
