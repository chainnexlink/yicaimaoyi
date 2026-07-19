package com.yicai.trade.module.seooutlink.publisher;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.seooutlink.entity.SeoBlogBinding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * Blogger API v3 发布器
 * 使用 API Key 认证（简易方案：将 appPassword 作为 API Key 使用）
 * 真实生产应使用 OAuth2 令牌
 * 端点: POST https://www.googleapis.com/blogger/v3/blogs/{blogId}/posts
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BloggerBlogPublisher implements BlogPublisher {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Override
    public String getPlatform() {
        return "BLOGGER";
    }

    @Override
    public BlogPublishResult testConnection(SeoBlogBinding binding) {
        try {
            String blogId = extractBlogId(binding.getBlogUrl());
            String url = "https://www.googleapis.com/blogger/v3/blogs/" + blogId
                    + "?key=" + binding.getAppPassword();

            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                return BlogPublishResult.ok(null);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("Blogger connection test failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    @Override
    public BlogPublishResult publish(SeoBlogBinding binding, String title, String htmlContent) {
        try {
            String blogId = extractBlogId(binding.getBlogUrl());
            String url = "https://www.googleapis.com/blogger/v3/blogs/" + blogId + "/posts";

            Map<String, Object> body = Map.of(
                    "kind", "blogger#post",
                    "title", title,
                    "content", htmlContent
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(binding.getAppPassword());

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String postUrl = root.path("url").asText("");
                return BlogPublishResult.ok(postUrl);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.error("Blogger publish failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    /**
     * 从blogUrl提取blogId（如果是数字直接返回，否则调用lookup API）
     */
    private String extractBlogId(String blogUrl) {
        if (blogUrl.matches("\\d+")) return blogUrl;
        // 如果是URL，取最后一段路径或使用lookup
        String cleaned = blogUrl.replaceAll("/$", "");
        String[] parts = cleaned.split("/");
        String last = parts[parts.length - 1];
        if (last.matches("\\d+")) return last;
        // 默认当作blogId使用
        return blogUrl;
    }
}
