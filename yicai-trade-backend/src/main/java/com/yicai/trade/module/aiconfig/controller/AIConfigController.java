package com.yicai.trade.module.aiconfig.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.aiconfig.dto.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/ai-config")
@Tag(name = "AI配置", description = "AI模型配置管理接口")
public class AIConfigController {

    // In-memory config store (in production, use database or config service)
    private static String activeModel = "doubao-seed";
    private static double temperature = 0.7;
    private static int maxTokens = 2048;
    private static boolean cacheEnabled = true;
    private static int cacheTtlMinutes = 30;

    @GetMapping
    @Operation(summary = "获取AI配置")
    public Result<AIConfigResponse> getConfig() {
        AIConfigResponse config = new AIConfigResponse();
        config.setActiveModel(activeModel);
        config.setTemperature(temperature);
        config.setMaxTokens(maxTokens);
        config.setCacheEnabled(cacheEnabled);
        config.setCacheTtlMinutes(cacheTtlMinutes);
        config.setTimeout(30000);
        config.setMaxRetries(3);
        return Result.success(config);
    }

    @PutMapping
    @Operation(summary = "更新AI配置")
    public Result<AIConfigResponse> updateConfig(@RequestBody AIConfigRequest request) {
        if (request.getActiveModel() != null) activeModel = request.getActiveModel();
        if (request.getTemperature() != null) temperature = request.getTemperature();
        if (request.getMaxTokens() != null) maxTokens = request.getMaxTokens();
        if (request.getCacheEnabled() != null) cacheEnabled = request.getCacheEnabled();
        if (request.getCacheTtlMinutes() != null) cacheTtlMinutes = request.getCacheTtlMinutes();

        AIConfigResponse config = new AIConfigResponse();
        config.setActiveModel(activeModel);
        config.setTemperature(temperature);
        config.setMaxTokens(maxTokens);
        config.setCacheEnabled(cacheEnabled);
        config.setCacheTtlMinutes(cacheTtlMinutes);
        config.setTimeout(30000);
        config.setMaxRetries(3);
        return Result.success(config);
    }

    @GetMapping("/models")
    @Operation(summary = "获取可用模型列表")
    public Result<Map<String, Object>> getModels() {
        Map<String, Object> models = new HashMap<>();

        Map<String, String> doubaoVision = new HashMap<>();
        doubaoVision.put("id", "doubao-seed-vision");
        doubaoVision.put("modelId", "idep-20260215104814-x5t6l");
        doubaoVision.put("name", "Doubao-Seed-1.6-vision");
        doubaoVision.put("provider", "ByteDance");
        doubaoVision.put("role", "视觉理解");
        models.put("doubao-seed-vision", doubaoVision);

        Map<String, String> doubaoText = new HashMap<>();
        doubaoText.put("id", "doubao-seed-text");
        doubaoText.put("modelId", "ep-20260217114227-lm9vr");
        doubaoText.put("name", "Doubao-Seed-1.8");
        doubaoText.put("provider", "ByteDance");
        doubaoText.put("role", "文本生成与理解");
        models.put("doubao-seed-text", doubaoText);

        Map<String, String> glm = new HashMap<>();
        glm.put("id", "glm-4");
        glm.put("modelId", "ep-20260217114008-h7cxp");
        glm.put("name", "GLM-4.7");
        glm.put("provider", "Zhipu AI");
        glm.put("role", "总调控与计算引擎");
        models.put("glm-4", glm);

        return Result.success(models);
    }
}
