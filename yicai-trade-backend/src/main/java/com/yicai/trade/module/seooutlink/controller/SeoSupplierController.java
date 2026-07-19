package com.yicai.trade.module.seooutlink.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.seooutlink.dto.*;
import com.yicai.trade.module.seooutlink.service.SeoOutlinkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 供应商端 - AI SEO 外链管理
 * 仅供应商角色可访问，通过 supplierId 路径参数隔离数据
 */
@RestController
@RequestMapping("/api/supplier/{supplierId}/seo-outlink")
@RequiredArgsConstructor
@Tag(name = "SEO外链-供应商端", description = "供应商AI SEO外链智能发布管理")
public class SeoSupplierController {

    private final SeoOutlinkService seoOutlinkService;

    // ===== 绑定管理 =====

    @GetMapping("/bindings")
    @Operation(summary = "获取我的博客绑定列表")
    public Result<List<SeoBlogBindingResponse>> getBindings(@PathVariable Long supplierId) {
        return Result.success(seoOutlinkService.getSupplierBindings(supplierId));
    }

    @PostMapping("/bindings")
    @Operation(summary = "创建或更新博客绑定")
    public Result<SeoBlogBindingResponse> saveBinding(
            @PathVariable Long supplierId,
            @RequestBody @Valid SeoBlogBindingRequest request) {
        return Result.success(seoOutlinkService.createOrUpdateBinding(supplierId, request));
    }

    @DeleteMapping("/bindings/{bindingId}")
    @Operation(summary = "删除博客绑定")
    public Result<Void> deleteBinding(@PathVariable Long supplierId, @PathVariable Long bindingId) {
        seoOutlinkService.deleteBinding(supplierId, bindingId);
        return Result.success(null);
    }

    @PostMapping("/bindings/{bindingId}/test")
    @Operation(summary = "测试博客连接")
    public Result<Map<String, Object>> testBinding(
            @PathVariable Long supplierId, @PathVariable Long bindingId) {
        return Result.success(seoOutlinkService.testBinding(supplierId, bindingId));
    }

    @PostMapping("/bindings/{bindingId}/toggle")
    @Operation(summary = "切换自动发布开关")
    public Result<Void> toggleAutoPublish(
            @PathVariable Long supplierId,
            @PathVariable Long bindingId,
            @RequestParam boolean enabled) {
        seoOutlinkService.toggleAutoPublish(supplierId, bindingId, enabled);
        return Result.success(null);
    }

    // ===== 发布 =====

    @PostMapping("/bindings/{bindingId}/publish-test")
    @Operation(summary = "立即发布测试文章")
    public Result<SeoBlogPublishLogResponse> publishTestArticle(
            @PathVariable Long supplierId, @PathVariable Long bindingId) {
        return Result.success(seoOutlinkService.publishTestArticle(supplierId, bindingId));
    }

    // ===== 日志 =====

    @GetMapping("/logs")
    @Operation(summary = "查看发布日志")
    public Result<PageResult<SeoBlogPublishLogResponse>> getLogs(
            @PathVariable Long supplierId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(seoOutlinkService.getSupplierLogs(supplierId, status, page, size));
    }
}
