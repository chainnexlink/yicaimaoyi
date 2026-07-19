package com.yicai.trade.module.certification.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.FactoryAuditRequest;
import com.yicai.trade.module.certification.dto.FactoryAuditResponse;
import com.yicai.trade.module.certification.service.FactoryAuditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/factory-audit")
@RequiredArgsConstructor
@Tag(name = "验厂管理", description = "供应商工厂验证全流程管理")
public class FactoryAuditController {

    private final FactoryAuditService factoryAuditService;

    @PostMapping
    @Operation(summary = "安排验厂")
    public Result<FactoryAuditResponse> schedule(@RequestBody FactoryAuditRequest request) {
        return Result.success(factoryAuditService.schedule(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取验厂详情")
    public Result<FactoryAuditResponse> get(@PathVariable Long id) {
        return Result.success(factoryAuditService.getById(id));
    }

    @GetMapping
    @Operation(summary = "验厂记录列表")
    public Result<PageResult<FactoryAuditResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(factoryAuditService.list(status, supplierId, page, size));
    }

    @PostMapping("/{id}/start")
    @Operation(summary = "开始验厂")
    public Result<Void> start(@PathVariable Long id) {
        factoryAuditService.startAudit(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/submit-result")
    @Operation(summary = "提交验厂结果")
    public Result<Void> submitResult(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String auditItems = (String) body.get("auditItems");
        String photos = (String) body.get("photos");
        Integer overallScore = body.get("overallScore") != null ? ((Number) body.get("overallScore")).intValue() : null;
        String conclusion = (String) body.get("conclusion");
        factoryAuditService.submitResult(id, auditItems, photos, overallScore, conclusion);
        return Result.success(null);
    }

    @PostMapping("/{id}/pass")
    @Operation(summary = "验厂通过")
    public Result<Void> pass(@PathVariable Long id) {
        factoryAuditService.pass(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/fail")
    @Operation(summary = "验厂不通过")
    public Result<Void> fail(@PathVariable Long id, @RequestBody Map<String, String> body) {
        factoryAuditService.fail(id, body.get("reason"));
        return Result.success(null);
    }
}
