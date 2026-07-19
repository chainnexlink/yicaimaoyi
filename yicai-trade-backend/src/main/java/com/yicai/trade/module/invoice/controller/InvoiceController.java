package com.yicai.trade.module.invoice.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.invoice.dto.InvoiceCreateRequest;
import com.yicai.trade.module.invoice.dto.InvoiceResponse;
import com.yicai.trade.module.invoice.service.InvoiceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/invoice")
@RequiredArgsConstructor
@Tag(name = "发票管理", description = "发票开具、寄送、确认全流程管理")
public class InvoiceController {

    private final InvoiceService invoiceService;

    @PostMapping
    @Operation(summary = "申请开票")
    public Result<InvoiceResponse> create(@RequestBody InvoiceCreateRequest request) {
        return Result.success(invoiceService.create(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取发票详情")
    public Result<InvoiceResponse> get(@PathVariable Long id) {
        return Result.success(invoiceService.getById(id));
    }

    @GetMapping("/no/{invoiceNo}")
    @Operation(summary = "按发票号查询")
    public Result<InvoiceResponse> getByNo(@PathVariable String invoiceNo) {
        return Result.success(invoiceService.getByInvoiceNo(invoiceNo));
    }

    @GetMapping
    @Operation(summary = "分页查询发票列表")
    public Result<PageResult<InvoiceResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long supplierId,
            @RequestParam(required = false) Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(invoiceService.list(status, supplierId, buyerId, page, size));
    }

    @GetMapping("/order/{orderId}")
    @Operation(summary = "查询订单关联发票")
    public Result<PageResult<InvoiceResponse>> listByOrder(
            @PathVariable Long orderId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(invoiceService.listByOrder(orderId, page, size));
    }

    @PostMapping("/{id}/issue")
    @Operation(summary = "开具发票")
    public Result<Void> issue(@PathVariable Long id, @RequestBody Map<String, String> body) {
        invoiceService.issue(id, body.get("fileUrl"));
        return Result.success(null);
    }

    @PostMapping("/{id}/send")
    @Operation(summary = "发送发票")
    public Result<Void> send(@PathVariable Long id) {
        invoiceService.send(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/confirm")
    @Operation(summary = "确认收到发票")
    public Result<Void> confirmReceived(@PathVariable Long id) {
        invoiceService.confirmReceived(id);
        return Result.success(null);
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "取消发票")
    public Result<Void> cancel(@PathVariable Long id, @RequestBody Map<String, String> body) {
        invoiceService.cancel(id, body.get("reason"));
        return Result.success(null);
    }

    @PostMapping("/{id}/void")
    @Operation(summary = "作废发票")
    public Result<Void> voidInvoice(@PathVariable Long id, @RequestBody Map<String, String> body) {
        invoiceService.voidInvoice(id, body.get("reason"));
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "发票统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(invoiceService.getStats());
    }
}
