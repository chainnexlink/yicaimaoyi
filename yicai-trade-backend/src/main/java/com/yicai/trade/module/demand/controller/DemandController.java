package com.yicai.trade.module.demand.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.demand.dto.*;
import com.yicai.trade.module.demand.service.DemandService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/demands")
@RequiredArgsConstructor
@Tag(name = "需求管理", description = "需求论坛管理接口")
public class DemandController {

    private final DemandService demandService;

    @PostMapping
    @Operation(summary = "创建需求")
    public Result<DemandResponse> createDemand(@Valid @RequestBody DemandRequest request) {
        return Result.success(demandService.createDemand(1L, request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "更新需求")
    public Result<DemandResponse> updateDemand(@PathVariable Long id, @Valid @RequestBody DemandRequest request) {
        return Result.success(demandService.updateDemand(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "删除需求")
    public Result<Void> deleteDemand(@PathVariable Long id) {
        demandService.deleteDemand(id);
        return Result.success(null);
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取需求详情")
    public Result<DemandResponse> getDemand(@PathVariable Long id) {
        return Result.success(demandService.getDemand(id));
    }

    @GetMapping("/no/{demandNo}")
    @Operation(summary = "根据编号获取需求")
    public Result<DemandResponse> getDemandByNo(@PathVariable String demandNo) {
        return Result.success(demandService.getDemandByNo(demandNo));
    }

    @GetMapping
    @Operation(summary = "分页查询需求列表")
    public Result<PageResult<DemandResponse>> listDemands(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(demandService.listDemands(status, category, page, size));
    }

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "查询采购商的需求")
    public Result<PageResult<DemandResponse>> listBuyerDemands(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(demandService.listBuyerDemands(buyerId, page, size));
    }

    @GetMapping("/pending-audit")
    @Operation(summary = "查询待审核需求")
    public Result<PageResult<DemandResponse>> listPendingAudit(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(demandService.listPendingAudit(page, size));
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "审批通过需求")
    public Result<Void> approveDemand(@PathVariable Long id) {
        demandService.approveDemand(id, 1L);
        return Result.success(null);
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "驳回需求")
    public Result<Void> rejectDemand(@PathVariable Long id, @RequestBody Map<String, String> body) {
        demandService.rejectDemand(id, 1L, body.get("reason"));
        return Result.success(null);
    }

    @PostMapping("/{id}/close")
    @Operation(summary = "关闭需求")
    public Result<Void> closeDemand(@PathVariable Long id) {
        demandService.closeDemand(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/response")
    @Operation(summary = "增加响应数")
    public Result<Void> incrementResponseCount(@PathVariable Long id) {
        demandService.incrementResponseCount(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/view")
    @Operation(summary = "增加浏览量")
    public Result<Void> incrementViewCount(@PathVariable Long id) {
        demandService.incrementViewCount(id);
        return Result.success(null);
    }
}
