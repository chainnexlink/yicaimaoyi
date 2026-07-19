package com.yicai.trade.module.shop.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.shop.dto.*;
import com.yicai.trade.module.shop.service.ShopService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/shop")
@RequiredArgsConstructor
@Tag(name = "店铺管理", description = "供应商店铺创建、装修、数据看板")
public class ShopController {

    private final ShopService shopService;

    @PostMapping
    @Operation(summary = "创建店铺")
    public Result<ShopResponse> create(@RequestBody ShopCreateRequest request) {
        return Result.success(shopService.create(request));
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "按供应商获取店铺")
    public Result<ShopResponse> getBySupplierId(@PathVariable Long supplierId) {
        return Result.success(shopService.getBySupplierId(supplierId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取店铺详情")
    public Result<ShopResponse> getById(@PathVariable Long id) {
        return Result.success(shopService.getById(id));
    }

    @PutMapping("/supplier/{supplierId}/info")
    @Operation(summary = "更新店铺信息")
    public Result<ShopResponse> updateInfo(@PathVariable Long supplierId, @RequestBody ShopCreateRequest request) {
        return Result.success(shopService.updateInfo(supplierId, request));
    }

    @PutMapping("/supplier/{supplierId}/decoration")
    @Operation(summary = "更新店铺装修")
    public Result<ShopResponse> updateDecoration(@PathVariable Long supplierId, @RequestBody ShopDecorationRequest request) {
        return Result.success(shopService.updateDecoration(supplierId, request));
    }

    @PostMapping("/{id}/visit")
    @Operation(summary = "记录店铺访问")
    public Result<Void> visit(@PathVariable Long id) {
        shopService.incrementVisit(id);
        return Result.success(null);
    }

    @GetMapping
    @Operation(summary = "店铺列表（搜索/筛选）")
    public Result<PageResult<ShopResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String industry,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(shopService.list(status, industry, keyword, page, size));
    }

    @GetMapping("/supplier/{supplierId}/dashboard")
    @Operation(summary = "店铺数据看板")
    public Result<ShopDashboardResponse> dashboard(
            @PathVariable Long supplierId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return Result.success(shopService.getDashboard(supplierId, startDate, endDate));
    }
}
