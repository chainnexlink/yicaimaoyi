package com.yicai.trade.module.aftersale.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.aftersale.dto.AftersaleCreateRequest;
import com.yicai.trade.module.aftersale.dto.AftersaleResponse;
import com.yicai.trade.module.aftersale.service.AftersaleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/aftersale")
@RequiredArgsConstructor
@Tag(name = "售后管理", description = "退换货、维修、仅退款全流程管理")
public class AftersaleController {

    private final AftersaleService aftersaleService;

    @PostMapping
    @Operation(summary = "提交售后申请")
    public Result<AftersaleResponse> create(@RequestBody AftersaleCreateRequest request) {
        return Result.success(aftersaleService.create(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取售后详情（含操作日志）")
    public Result<AftersaleResponse> get(@PathVariable Long id) {
        return Result.success(aftersaleService.getById(id));
    }

    @GetMapping
    @Operation(summary = "分页查询售后列表")
    public Result<PageResult<AftersaleResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Long buyerId,
            @RequestParam(required = false) Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(aftersaleService.list(status, type, buyerId, supplierId, page, size));
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "供应商同意售后")
    public Result<Void> approve(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String remark = (String) body.getOrDefault("remark", "");
        aftersaleService.supplierApprove(id, operatorId, remark);
        return Result.success(null);
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "供应商拒绝售后")
    public Result<Void> reject(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String remark = (String) body.get("remark");
        aftersaleService.supplierReject(id, operatorId, remark);
        return Result.success(null);
    }

    @PostMapping("/{id}/ship-return")
    @Operation(summary = "买家寄回退货")
    public Result<Void> shipReturn(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String trackingNo = (String) body.get("trackingNo");
        String carrier = (String) body.get("carrier");
        aftersaleService.buyerShipReturn(id, operatorId, trackingNo, carrier);
        return Result.success(null);
    }

    @PostMapping("/{id}/confirm-receive")
    @Operation(summary = "供应商确认收到退回商品")
    public Result<Void> confirmReceive(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        aftersaleService.supplierConfirmReceive(id, operatorId);
        return Result.success(null);
    }

    @PostMapping("/{id}/refund")
    @Operation(summary = "执行退款")
    public Result<Void> refund(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        aftersaleService.executeRefund(id, operatorId);
        return Result.success(null);
    }

    @PostMapping("/{id}/exchange")
    @Operation(summary = "执行换货发货")
    public Result<Void> exchange(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String trackingNo = (String) body.get("trackingNo");
        String carrier = (String) body.get("carrier");
        aftersaleService.executeExchange(id, operatorId, trackingNo, carrier);
        return Result.success(null);
    }

    @PostMapping("/{id}/complete")
    @Operation(summary = "买家确认售后完成")
    public Result<Void> complete(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        aftersaleService.complete(id, operatorId);
        return Result.success(null);
    }

    @PostMapping("/{id}/appeal")
    @Operation(summary = "买家申诉")
    public Result<Void> appeal(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String reason = (String) body.get("reason");
        aftersaleService.buyerAppeal(id, operatorId, reason);
        return Result.success(null);
    }

    @PostMapping("/{id}/intervene")
    @Operation(summary = "平台介入裁决")
    public Result<Void> intervene(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String decision = (String) body.get("decision");
        String remark = (String) body.get("remark");
        aftersaleService.platformIntervene(id, operatorId, decision, remark);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "售后统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(aftersaleService.getStats());
    }
}
