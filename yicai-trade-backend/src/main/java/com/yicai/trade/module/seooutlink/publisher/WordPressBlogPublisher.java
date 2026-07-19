package com.yicai.trade.module.seooutlink.publisher;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.seooutlink.entity.SeoBlogBinding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

/**
 * WordPress REST API 发布器
 * 使用 Application Passwords 认证 (WordPress 5.6+)
 * 端点: POST {blog_url}/wp-json/wp/v2/posts
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WordPressBlogPublisher implements BlogPublisher {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Override
    public String getPlatform() {
        return "WORDPRESS";
    }

    @Override
    public BlogPublishResult testConnection(SeoBlogBinding binding) {
        try {
            String url = normalizeUrl(binding.getBlogUrl()) + "/wp-json/wp/v2/posts?per_page=1&status=any";
            HttpEntity<Void> entity = new HttpEntity<>(buildAuthHeaders(binding));
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                return BlogPublishResult.ok(null);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.warn("WordPress connection test failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    @Override
    public BlogPublishResult publish(SeoBlogBinding binding, String title, String htmlContent) {
        try {
            String url = normalizeUrl(binding.getBlogUrl()) + "/wp-json/wp/v2/posts";

            Map<String, Object> body = Map.of(
                    "title", title,
                    "content", htmlContent,
                    "status", "publish"
            );

            HttpHeaders headers = buildAuthHeaders(binding);
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String postUrl = root.path("link").asText("");
                return BlogPublishResult.ok(postUrl);
            }
            return BlogPublishResult.fail("HTTP " + response.getStatusCode());
        } catch (Exception e) {
            log.error("WordPress publish failed: {}", e.getMessage());
            return BlogPublishResult.fail(e.getMessage());
        }
    }

    private HttpHeaders buildAuthHeaders(SeoBlogBinding binding) {
        HttpHeaders headers = new HttpHeaders();
        String credentials = binding.getUsername() + ":" + binding.getAppPassword();
        String encoded = Base64.getEncoder().encodeToString(credentials.getBytes(StandardCharsets.UTF_8));
        headers.set(HttpHeaders.AUTHORIZATION, "Basic " + encoded);
        return headers;
    }

    private String normalizeUrl(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
