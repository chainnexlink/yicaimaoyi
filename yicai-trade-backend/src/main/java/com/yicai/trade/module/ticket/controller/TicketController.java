package com.yicai.trade.module.ticket.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.ticket.dto.*;
import com.yicai.trade.module.ticket.service.TicketService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/tickets")
@RequiredArgsConstructor
@Tag(name = "工单管理", description = "工单处理与管理接口")
public class TicketController {

    private final TicketService ticketService;

    @PostMapping
    @Operation(summary = "创建工单")
    public Result<TicketResponse> create(@Valid @RequestBody TicketRequest request) {
        return Result.success(ticketService.create(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取工单详情")
    public Result<TicketResponse> get(@PathVariable Long id) {
        return Result.success(ticketService.getById(id));
    }

    @GetMapping
    @Operation(summary = "分页查询工单列表")
    public Result<PageResult<TicketResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String ticketType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(ticketService.list(status, ticketType, page, size));
    }

    @PostMapping("/{id}/reply")
    @Operation(summary = "回复工单")
    public Result<Void> reply(@PathVariable Long id, @RequestBody Map<String, String> body) {
        ticketService.reply(id, body.get("replyContent"));
        return Result.success(null);
    }

    @PostMapping("/{id}/close")
    @Operation(summary = "关闭工单")
    public Result<Void> close(@PathVariable Long id) {
        ticketService.close(id);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "工单统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(ticketService.getStats());
    }
}
