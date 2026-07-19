package com.yicai.trade.module.payment.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.dto.RefundResponse;
import com.yicai.trade.module.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/payments")
@RequiredArgsConstructor
@Tag(name = "支付管理后台", description = "管理员支付管理接口")
public class PaymentAdminController {

    private final PaymentService paymentService;

    @GetMapping
    @Operation(summary = "支付列表", description = "管理员查看所有支付记录，可按状态筛选")
    public Result<Page<PaymentResponse>> listPayments(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(paymentService.getAllPayments(status,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))));
    }

    @GetMapping("/{id}")
    @Operation(summary = "支付详情", description = "管理员查看支付详情")
    public Result<PaymentResponse> getPayment(@PathVariable Long id) {
        return Result.success(paymentService.getPaymentById(id));
    }

    @GetMapping("/statistics")
    @Operation(summary = "支付统计", description = "获取支付统计数据（总量、成功率、金额等）")
    public Result<Map<String, Object>> getStatistics() {
        return Result.success(paymentService.getPaymentStatistics());
    }

    // ==================== 退款管理 ====================

    @GetMapping("/refunds")
    @Operation(summary = "退款列表", description = "管理员查看所有退款记录，可按状态筛选")
    public Result<Page<RefundResponse>> listRefunds(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(paymentService.getAllRefunds(status,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))));
    }

    @GetMapping("/refunds/{id}")
    @Operation(summary = "退款详情", description = "管理员查看退款详情")
    public Result<RefundResponse> getRefund(@PathVariable Long id) {
        return Result.success(paymentService.getRefundById(id));
    }

    @PostMapping("/refunds/{id}/approve")
    @Operation(summary = "审核通过退款", description = "管理员审核通过退款申请")
    public Result<RefundResponse> approveRefund(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "管理员审核通过") String remark,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long auditorId = getUserId(userDetails);
        return Result.success(paymentService.approveRefund(id, auditorId, remark));
    }

    @PostMapping("/refunds/{id}/reject")
    @Operation(summary = "拒绝退款", description = "管理员拒绝退款申请")
    public Result<RefundResponse> rejectRefund(
            @PathVariable Long id,
            @RequestParam String remark,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long auditorId = getUserId(userDetails);
        return Result.success(paymentService.rejectRefund(id, auditorId, remark));
    }

    @PostMapping("/refunds/{id}/process")
    @Operation(summary = "执行退款", description = "管理员执行退款操作")
    public Result<RefundResponse> processRefund(
            @PathVariable Long id,
            @RequestParam(required = false) String transactionId) {
        return Result.success(paymentService.processRefund(id, transactionId));
    }

    private Long getUserId(UserDetails userDetails) {
        return Long.parseLong(userDetails.getUsername());
    }
}
