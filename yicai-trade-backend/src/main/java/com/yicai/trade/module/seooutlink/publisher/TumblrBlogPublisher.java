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
 * Tumblr API v2 发布器
 * 使用 OAuth 认证（简易方案：appPassword 作为 OAuth token）
 * 端点: POST https://api.tumblr.com/v2/blog/{blog-identifier}/post
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TumblrBlogPublisher implements BlogPublisher {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Override
    public String getPlatform() {
        return "TUMBLR";
    }

    @Override
    public BlogPublishResult testConnection(SeoBlogBinding binding) {
        try {
            String blogId = extractBlogIdentifier(binding.getBlogUrl());
            String url = "https://api.tumblr.com/v2/blog/" + blogId + "/info";

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(binding.getAppPassword());
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                return BlogPublishResult.ok(null);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("Tumblr connection test failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    @Override
    public BlogPublishResult publish(SeoBlogBinding binding, String title, String htmlContent) {
        try {
            String blogId = extractBlogIdentifier(binding.getBlogUrl());
            String url = "https://api.tumblr.com/v2/blog/" + blogId + "/post";

            Map<String, Object> body = Map.of(
                    "type", "text",
                    "title", title,
                    "body", htmlContent
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(binding.getAppPassword());

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                long postId = root.path("response").path("id").asLong();
                String postUrl = "https://" + blogId + ".tumblr.com/post/" + postId;
                return BlogPublishResult.ok(postUrl);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.error("Tumblr publish failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    /**
     * 从 URL 中提取 Tumblr blog identifier (如 myblog.tumblr.com)
     */
    private String extractBlogIdentifier(String blogUrl) {
        String cleaned = blogUrl.replaceAll("https?://", "").replaceAll("/$", "");
        if (cleaned.contains(".tumblr.com")) {
            return cleaned.split("/")[0];
        }
        return cleaned;
    }
}
