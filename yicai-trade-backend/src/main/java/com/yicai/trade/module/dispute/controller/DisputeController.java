package com.yicai.trade.module.dispute.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.dispute.dto.DisputeCreateRequest;
import com.yicai.trade.module.dispute.dto.DisputeResponse;
import com.yicai.trade.module.dispute.service.DisputeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/dispute")
@RequiredArgsConstructor
@Tag(name = "纠纷处理", description = "纠纷受理、调解、裁决、执行全流程")
public class DisputeController {

    private final DisputeService disputeService;

    @PostMapping
    @Operation(summary = "发起纠纷")
    public Result<DisputeResponse> create(@RequestBody DisputeCreateRequest request) {
        return Result.success(disputeService.create(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取纠纷详情（含沟通记录）")
    public Result<DisputeResponse> get(@PathVariable Long id) {
        return Result.success(disputeService.getById(id));
    }

    @GetMapping
    @Operation(summary = "分页查询纠纷列表")
    public Result<PageResult<DisputeResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String disputeType,
            @RequestParam(required = false) Long assignedTo,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(disputeService.list(status, disputeType, assignedTo, page, size));
    }

    @PostMapping("/{id}/assign")
    @Operation(summary = "分配处理人")
    public Result<Void> assign(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long staffId = ((Number) body.get("staffId")).longValue();
        disputeService.assignTo(id, staffId);
        return Result.success(null);
    }

    @PostMapping("/{id}/review")
    @Operation(summary = "开始审核")
    public Result<Void> review(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        disputeService.startReview(id, operatorId);
        return Result.success(null);
    }

    @PostMapping("/{id}/mediate")
    @Operation(summary = "发起调解")
    public Result<Void> mediate(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String message = (String) body.get("message");
        disputeService.startMediation(id, operatorId, message);
        return Result.success(null);
    }

    @PostMapping("/{id}/ruling")
    @Operation(summary = "做出裁决")
    public Result<Void> ruling(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String rulingType = (String) body.get("rulingType");
        BigDecimal awardedAmount = body.get("awardedAmount") != null
                ? new BigDecimal(body.get("awardedAmount").toString()) : BigDecimal.ZERO;
        String reason = (String) body.get("reason");
        disputeService.makeRuling(id, operatorId, rulingType, awardedAmount, reason);
        return Result.success(null);
    }

    @PostMapping("/{id}/enforce")
    @Operation(summary = "执行裁决")
    public Result<Void> enforce(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        disputeService.enforce(id, operatorId);
        return Result.success(null);
    }

    @PostMapping("/{id}/close")
    @Operation(summary = "关闭纠纷")
    public Result<Void> close(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String remark = (String) body.getOrDefault("remark", "");
        disputeService.close(id, operatorId, remark);
        return Result.success(null);
    }

    @PostMapping("/{id}/withdraw")
    @Operation(summary = "撤回纠纷")
    public Result<Void> withdraw(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long operatorId = ((Number) body.get("operatorId")).longValue();
        String reason = (String) body.getOrDefault("reason", "");
        disputeService.withdraw(id, operatorId, reason);
        return Result.success(null);
    }

    @PostMapping("/{id}/message")
    @Operation(summary = "发送纠纷沟通消息")
    public Result<Void> sendMessage(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Long senderId = ((Number) body.get("senderId")).longValue();
        String senderRole = (String) body.get("senderRole");
        String content = (String) body.get("content");
        String attachmentUrls = (String) body.get("attachmentUrls");
        disputeService.addMessage(id, senderId, senderRole, content, attachmentUrls);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "纠纷统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(disputeService.getStats());
    }
}
