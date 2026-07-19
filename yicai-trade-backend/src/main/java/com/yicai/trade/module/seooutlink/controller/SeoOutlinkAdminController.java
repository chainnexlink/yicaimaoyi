package com.yicai.trade.module.seooutlink.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.seooutlink.dto.*;
import com.yicai.trade.module.seooutlink.service.SeoOutlinkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 管理后台 - AI SEO 外链管理
 * 查看所有供应商绑定、发布日志、全局开关
 */
@RestController
@RequestMapping("/api/admin/seo-outlink")
@RequiredArgsConstructor
@Tag(name = "SEO外链-管理后台", description = "平台管理SEO外链功能")
public class SeoOutlinkAdminController {

    private final SeoOutlinkService seoOutlinkService;

    @GetMapping("/stats")
    @Operation(summary = "外链功能统计")
    public Result<Map<String, Object>> getStats() {
        return Result.success(seoOutlinkService.getOutlinkStats());
    }

    @GetMapping("/config")
    @Operation(summary = "获取外链功能配置")
    public Result<Map<String, Object>> getConfig() {
        return Result.success(Map.of(
                "outlinkEnabled", seoOutlinkService.isOutlinkEnabled(),
                "globalDailyLimit", seoOutlinkService.getGlobalDailyLimit()
        ));
    }

    @PostMapping("/config")
    @Operation(summary = "更新外链功能配置")
    public Result<Void> updateConfig(@RequestBody Map<String, Object> body) {
        if (body.containsKey("outlinkEnabled")) {
            seoOutlinkService.setOutlinkEnabled(Boolean.TRUE.equals(body.get("outlinkEnabled")));
        }
        if (body.containsKey("globalDailyLimit")) {
            seoOutlinkService.setGlobalDailyLimit(((Number) body.get("globalDailyLimit")).intValue());
        }
        return Result.success(null);
    }

    @GetMapping("/bindings")
    @Operation(summary = "查看所有供应商绑定")
    public Result<List<SeoBlogBindingResponse>> getAllBindings() {
        return Result.success(seoOutlinkService.getAllBindings());
    }

    @GetMapping("/logs")
    @Operation(summary = "查看所有发布日志")
    public Result<PageResult<SeoBlogPublishLogResponse>> getAllLogs(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return Result.success(seoOutlinkService.getAllLogs(status, page, size));
    }

    @PostMapping("/trigger")
    @Operation(summary = "手动触发定时外链发布任务")
    public Result<Map<String, Object>> triggerScheduled() {
        try {
            seoOutlinkService.scheduledOutlinkPublish();
            return Result.success(Map.of("triggered", true, "message", "外链定时任务已触发"));
        } catch (Exception e) {
            return Result.error(500, "触发失败: " + e.getMessage());
        }
    }
}
