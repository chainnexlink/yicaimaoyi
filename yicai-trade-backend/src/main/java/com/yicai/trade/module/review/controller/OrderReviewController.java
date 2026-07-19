package com.yicai.trade.module.review.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.review.dto.*;
import com.yicai.trade.module.review.service.OrderReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/review")
@RequiredArgsConstructor
@Tag(name = "订单评价", description = "买家评价、供应商回复、评价申诉管理")
public class OrderReviewController {

    private final OrderReviewService reviewService;

    @PostMapping
    @Operation(summary = "提交订单评价")
    public Result<ReviewResponse> create(@RequestBody ReviewCreateRequest request) {
        return Result.success(reviewService.create(request));
    }

    @GetMapping("/order/{orderId}")
    @Operation(summary = "获取订单评价")
    public Result<ReviewResponse> getByOrder(@PathVariable Long orderId) {
        return Result.success(reviewService.getByOrderId(orderId));
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "获取供应商的所有评价")
    public Result<PageResult<ReviewResponse>> listBySupplierId(
            @PathVariable Long supplierId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(reviewService.listBySupplierId(supplierId, status, page, size));
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "获取买家的所有评价")
    public Result<PageResult<ReviewResponse>> listByBuyerId(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(reviewService.listByBuyerId(buyerId, page, size));
    }

    @GetMapping
    @Operation(summary = "所有评价列表（管理端）")
    public Result<PageResult<ReviewResponse>> listAll(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(reviewService.listAll(status, page, size));
    }

    @PostMapping("/{id}/reply")
    @Operation(summary = "供应商回复评价")
    public Result<Void> reply(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long supplierId = ((Number) body.get("supplierId")).longValue();
        String reply = (String) body.get("reply");
        reviewService.supplierReply(id, supplierId, reply);
        return Result.success(null);
    }

    @PostMapping("/{id}/hide")
    @Operation(summary = "隐藏评价（管理员）")
    public Result<Void> hide(@PathVariable Long id) {
        reviewService.hide(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/appeal")
    @Operation(summary = "评价申诉")
    public Result<Void> appeal(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long buyerId = ((Number) body.get("buyerId")).longValue();
        String reason = (String) body.get("reason");
        reviewService.appeal(id, buyerId, reason);
        return Result.success(null);
    }

    @GetMapping("/supplier/{supplierId}/summary")
    @Operation(summary = "供应商评价汇总")
    public Result<ReviewSummaryResponse> summary(@PathVariable Long supplierId) {
        return Result.success(reviewService.getSummary(supplierId));
    }
}
