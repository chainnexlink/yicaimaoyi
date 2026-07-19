package com.yicai.trade.module.promotion.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.promotion.dto.*;
import com.yicai.trade.module.promotion.service.PromotionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/promotion")
@RequiredArgsConstructor
@Tag(name = "营销推广", description = "关键词竞价、广告投放、活动报名管理")
public class PromotionController {

    private final PromotionService promotionService;

    @PostMapping
    @Operation(summary = "创建推广计划")
    public Result<PromotionResponse> create(@RequestBody PromotionCreateRequest request) {
        return Result.success(promotionService.createPromotion(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取推广详情")
    public Result<PromotionResponse> get(@PathVariable Long id) {
        return Result.success(promotionService.getById(id));
    }

    @GetMapping
    @Operation(summary = "推广列表")
    public Result<PageResult<PromotionResponse>> list(
            @RequestParam(required = false) Long supplierId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String promoType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(promotionService.list(supplierId, status, promoType, page, size));
    }

    @PostMapping("/{id}/submit")
    @Operation(summary = "提交审核")
    public Result<Void> submit(@PathVariable Long id) {
        promotionService.submitForReview(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "审核通过")
    public Result<Void> approve(@PathVariable Long id) {
        promotionService.approve(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "审核拒绝")
    public Result<Void> reject(@PathVariable Long id, @RequestBody Map<String, String> body) {
        promotionService.reject(id, body.get("reason"));
        return Result.success(null);
    }

    @PostMapping("/{id}/pause")
    @Operation(summary = "暂停推广")
    public Result<Void> pause(@PathVariable Long id) {
        promotionService.pause(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/resume")
    @Operation(summary = "恢复推广")
    public Result<Void> resume(@PathVariable Long id) {
        promotionService.resume(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/impression")
    @Operation(summary = "记录展示")
    public Result<Void> impression(@PathVariable Long id) {
        promotionService.recordImpression(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/click")
    @Operation(summary = "记录点击")
    public Result<Void> click(@PathVariable Long id) {
        promotionService.recordClick(id);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "推广统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(promotionService.getStats());
    }

    // === Platform Events ===

    @PostMapping("/event")
    @Operation(summary = "创建平台活动")
    public Result<PlatformEventResponse> createEvent(@RequestBody Map<String, Object> body) {
        return Result.success(promotionService.createEvent(
                (String) body.get("eventName"),
                (String) body.get("eventType"),
                (String) body.get("description"),
                (String) body.get("bannerUrl"),
                (String) body.get("rules"),
                body.get("maxParticipants") != null ? ((Number) body.get("maxParticipants")).intValue() : null
        ));
    }

    @GetMapping("/event")
    @Operation(summary = "活动列表")
    public Result<PageResult<PlatformEventResponse>> listEvents(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(promotionService.listEvents(status, page, size));
    }

    @PostMapping("/event/{eventId}/open-signup")
    @Operation(summary = "开放活动报名")
    public Result<Void> openSignup(@PathVariable Long eventId) {
        promotionService.openSignup(eventId);
        return Result.success(null);
    }

    @PostMapping("/event/{eventId}/signup")
    @Operation(summary = "供应商报名活动")
    public Result<Void> signup(@PathVariable Long eventId, @RequestBody Map<String, Object> body) {
        Long supplierId = ((Number) body.get("supplierId")).longValue();
        String productIds = (String) body.get("productIds");
        String note = (String) body.getOrDefault("note", "");
        promotionService.signup(eventId, supplierId, productIds, note);
        return Result.success(null);
    }

    @PostMapping("/signup/{signupId}/approve")
    @Operation(summary = "审核通过报名")
    public Result<Void> approveSignup(@PathVariable Long signupId) {
        promotionService.approveSignup(signupId);
        return Result.success(null);
    }

    @PostMapping("/signup/{signupId}/reject")
    @Operation(summary = "审核拒绝报名")
    public Result<Void> rejectSignup(@PathVariable Long signupId, @RequestBody Map<String, String> body) {
        promotionService.rejectSignup(signupId, body.get("reason"));
        return Result.success(null);
    }
}
