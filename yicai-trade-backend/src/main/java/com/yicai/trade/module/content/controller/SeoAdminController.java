package com.yicai.trade.module.content.controller;

import com.yicai.trade.common.ai.client.AIRequest;
import com.yicai.trade.common.ai.client.AIResponse;
import com.yicai.trade.common.ai.client.DoubaoTextClient;
import com.yicai.trade.common.ai.config.AIModelProperties;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.content.dto.IndustryResponse;
import com.yicai.trade.module.content.entity.Industry;
import com.yicai.trade.module.content.repository.IndustryRepository;
import com.yicai.trade.module.content.service.SeoContentGeneratorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 管理后台 - 行业品类管理 + SEO自动发布控制
 */
@RestController
@RequestMapping("/api/admin/seo")
@RequiredArgsConstructor
@Tag(name = "SEO管理", description = "行业品类管理与SEO自动发布")
public class SeoAdminController {

    private final IndustryRepository industryRepository;
    private final SeoContentGeneratorService seoService;
    private final DoubaoTextClient doubaoTextClient;
    private final AIModelProperties aiModelProperties;

    // ===== 行业品类 CRUD =====

    @GetMapping("/industries")
    @Operation(summary = "获取所有行业品类")
    public Result<List<IndustryResponse>> listIndustries() {
        return Result.success(industryRepository.findAll().stream()
                .map(this::toResponse).collect(Collectors.toList()));
    }

    @PostMapping("/industries")
    @Operation(summary = "新增行业品类")
    public Result<IndustryResponse> addIndustry(@RequestBody Map<String, String> body) {
        Industry industry = Industry.builder()
                .name(body.getOrDefault("name", ""))
                .nameEn(body.getOrDefault("nameEn", ""))
                .sortOrder(Integer.parseInt(body.getOrDefault("sortOrder", "0")))
                .status("ACTIVE")
                .build();
        return Result.success(toResponse(industryRepository.save(industry)));
    }

    @PutMapping("/industries/{id}")
    @Operation(summary = "更新行业品类")
    public Result<IndustryResponse> updateIndustry(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Industry industry = industryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("行业不存在: " + id));
        if (body.containsKey("name")) industry.setName(body.get("name"));
        if (body.containsKey("nameEn")) industry.setNameEn(body.get("nameEn"));
        if (body.containsKey("sortOrder")) industry.setSortOrder(Integer.parseInt(body.get("sortOrder")));
        if (body.containsKey("status")) industry.setStatus(body.get("status"));
        return Result.success(toResponse(industryRepository.save(industry)));
    }

    @DeleteMapping("/industries/{id}")
    @Operation(summary = "删除行业品类")
    public Result<Void> deleteIndustry(@PathVariable Long id) {
        industryRepository.deleteById(id);
        return Result.success(null);
    }

    // ===== SEO 自动发布控制 =====

    @GetMapping("/config")
    @Operation(summary = "获取SEO自动发布配置")
    public Result<Map<String, Object>> getConfig() {
        return Result.success(Map.of(
                "autoPublishEnabled", seoService.isAutoPublishEnabled(),
                "industryCount", industryRepository.countByStatus("ACTIVE")
        ));
    }

    @PostMapping("/config")
    @Operation(summary = "更新SEO自动发布配置")
    public Result<Void> updateConfig(@RequestBody Map<String, Object> body) {
        if (body.containsKey("autoPublishEnabled")) {
            seoService.setAutoPublishEnabled(Boolean.TRUE.equals(body.get("autoPublishEnabled")));
        }
        return Result.success(null);
    }

    @PostMapping("/generate")
    @Operation(summary = "手动触发SEO文案生成")
    public Result<Map<String, Object>> manualGenerate(
            @RequestParam(name = "industryId", required = false) Long industryId,
            @RequestParam(name = "count", defaultValue = "2") int count) {
        try {
            int saved = seoService.manualGenerate(industryId, count);
            return Result.success(Map.of("generated", saved));
        } catch (Exception e) {
            return Result.error(500, "SEO文案生成失败: " + e.getMessage());
        }
    }

    @PostMapping("/trigger-scheduled")
    @Operation(summary = "立即触发定时任务（模拟凌晨2点的定时生成）")
    public Result<Map<String, Object>> triggerScheduled() {
        try {
            seoService.scheduledGenerate();
            return Result.success(Map.of("triggered", true, "message", "定时任务已触发"));
        } catch (Exception e) {
            return Result.error(500, "定时任务执行失败: " + e.getMessage());
        }
    }

    // ===== 豆包AI模型管理 =====

    @GetMapping("/ai-info")
    @Operation(summary = "获取豆包AI模型配置信息")
    public Result<Map<String, Object>> getAiInfo() {
        AIModelProperties.ModelConfig textConfig = aiModelProperties.getModels() != null
                ? aiModelProperties.getModels().get("doubao-text") : null;

        Map<String, Object> info = new LinkedHashMap<>();
        if (textConfig != null) {
            info.put("modelId", textConfig.getModelId());
            info.put("endpoint", textConfig.getEndpoint());
            info.put("enabled", Boolean.TRUE.equals(textConfig.getEnabled()));
            // API key只显示末4位
            String key = textConfig.getApiKey();
            info.put("apiKeyMask", key != null && key.length() > 4
                    ? "****" + key.substring(key.length() - 4) : "未配置");
        } else {
            info.put("modelId", "未配置");
            info.put("endpoint", "未配置");
            info.put("enabled", false);
            info.put("apiKeyMask", "未配置");
        }
        info.put("timeout", aiModelProperties.getTimeout());
        info.put("maxRetries", aiModelProperties.getMaxRetries());
        return Result.success(info);
    }

    @PostMapping("/ai-test")
    @Operation(summary = "测试豆包AI连接")
    public Result<Map<String, Object>> testAiConnection() {
        Map<String, Object> result = new LinkedHashMap<>();
        if (!doubaoTextClient.isEnabled()) {
            result.put("status", "DISABLED");
            result.put("message", "豆包文本模型未启用");
            return Result.success(result);
        }

        try {
            AIRequest request = AIRequest.builder()
                    .messages(List.of(
                            AIRequest.Message.builder().role("user").content("Hello, respond with: OK").build()
                    ))
                    .temperature(0.1)
                    .maxTokens(20)
                    .build();

            long start = System.currentTimeMillis();
            AIResponse response = doubaoTextClient.call(request);
            long elapsed = System.currentTimeMillis() - start;

            if (Boolean.TRUE.equals(response.getSuccess())) {
                result.put("status", "OK");
                result.put("message", "连接成功");
                result.put("responseTime", elapsed + "ms");
                result.put("model", response.getModel());
                result.put("tokensUsed", response.getTokensUsed());
                result.put("preview", response.getContent() != null
                        ? response.getContent().substring(0, Math.min(50, response.getContent().length())) : "");
            } else {
                result.put("status", "ERROR");
                result.put("message", response.getErrorMessage());
                result.put("responseTime", elapsed + "ms");
            }
        } catch (Exception e) {
            result.put("status", "ERROR");
            result.put("message", "连接异常: " + e.getMessage());
        }
        return Result.success(result);
    }

    private IndustryResponse toResponse(Industry i) {
        return IndustryResponse.builder()
                .id(i.getId())
                .name(i.getName())
                .nameEn(i.getNameEn())
                .sortOrder(i.getSortOrder())
                .status(i.getStatus())
                .createdAt(i.getCreatedAt())
                .build();
    }
}
