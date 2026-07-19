package com.yicai.trade.module.logistics.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.logistics.dto.*;
import com.yicai.trade.module.logistics.service.LogisticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/logistics")
@RequiredArgsConstructor
@Tag(name = "物流管理", description = "物流跟踪与管理接口")
public class LogisticsController {

    private final LogisticsService logisticsService;

    @PostMapping
    @Operation(summary = "创建物流单")
    public Result<LogisticsResponse> create(@RequestBody LogisticsRequest request) {
        return Result.success(logisticsService.create(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取物流详情")
    public Result<LogisticsResponse> get(@PathVariable Long id) {
        return Result.success(logisticsService.getById(id));
    }

    @GetMapping("/tracking/{trackingNo}")
    @Operation(summary = "根据物流单号查询")
    public Result<LogisticsResponse> getByTracking(@PathVariable String trackingNo) {
        return Result.success(logisticsService.getByTrackingNo(trackingNo));
    }

    @GetMapping
    @Operation(summary = "分页查询物流列表")
    public Result<PageResult<LogisticsResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(logisticsService.list(status, page, size));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "更新物流状态")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        logisticsService.updateStatus(id, body.get("status"));
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "物流统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(logisticsService.getStats());
    }

    @GetMapping("/track")
    @Operation(summary = "实时查询快递物流轨迹（调用第三方API）")
    public Result<TrackingQueryResponse> queryTracking(
            @RequestParam String trackingNo,
            @RequestParam(required = false) String carrierCode) {
        return Result.success(logisticsService.queryTracking(trackingNo, carrierCode));
    }
}
