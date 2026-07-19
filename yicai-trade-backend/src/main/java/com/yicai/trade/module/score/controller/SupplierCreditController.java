package com.yicai.trade.module.score.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.score.dto.CreditChangeLogResponse;
import com.yicai.trade.module.score.dto.SupplierCreditResponse;
import com.yicai.trade.module.score.service.SupplierCreditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/supplier-credit")
@RequiredArgsConstructor
@Tag(name = "供应商信用评级", description = "信用评分、等级评定、变更记录管理")
public class SupplierCreditController {

    private final SupplierCreditService creditService;

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "获取供应商信用详情")
    public Result<SupplierCreditResponse> get(@PathVariable Long supplierId) {
        return Result.success(creditService.getOrCreate(supplierId));
    }

    @GetMapping("/ranking")
    @Operation(summary = "信用排行榜")
    public Result<PageResult<SupplierCreditResponse>> ranking(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(creditService.ranking(page, size));
    }

    @GetMapping("/supplier/{supplierId}/changelog")
    @Operation(summary = "信用变更记录")
    public Result<PageResult<CreditChangeLogResponse>> changeLog(
            @PathVariable Long supplierId,
            @RequestParam(required = false) String dimension,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(creditService.getChangeLog(supplierId, dimension, page, size));
    }

    @PostMapping("/supplier/{supplierId}/adjust")
    @Operation(summary = "手动调整信用分（管理员）")
    public Result<Void> adjust(@PathVariable Long supplierId, @RequestBody Map<String, Object> body) {
        String dimension = (String) body.get("dimension");
        BigDecimal adjustment = new BigDecimal(body.get("adjustment").toString());
        String reason = (String) body.get("reason");
        creditService.manualAdjust(supplierId, dimension, adjustment, reason);
        return Result.success(null);
    }

    @PostMapping("/supplier/{supplierId}/recalculate")
    @Operation(summary = "重新计算信用分")
    public Result<Void> recalculate(@PathVariable Long supplierId) {
        creditService.recalculate(supplierId);
        return Result.success(null);
    }
}
