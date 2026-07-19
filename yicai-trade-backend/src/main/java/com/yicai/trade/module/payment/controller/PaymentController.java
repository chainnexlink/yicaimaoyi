package com.yicai.trade.module.payment.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.payment.dto.*;
import com.yicai.trade.module.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
@Tag(name = "支付管理", description = "支付与退款相关接口")
public class PaymentController {

    private final PaymentService paymentService;
    private final ResourceAuthorizationService authorization;

    // ==================== 支付相关 ====================

    @PostMapping
    @Operation(summary = "创建支付", description = "创建订单支付记录")
    public Result<PaymentResponse> createPayment(
            @Valid @RequestBody PaymentCreateRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = getUserId(userDetails);
        authorization.assertOrderBuyerAccess(request.getOrderId());
        return Result.success(paymentService.createPayment(request, userId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取支付详情", description = "根据ID获取支付记录详情")
    public Result<PaymentResponse> getPayment(@PathVariable Long id) {
        authorization.assertPaymentAccess(id);
        return Result.success(paymentService.getPaymentById(id));
    }

    @GetMapping("/no/{paymentNo}")
    @Operation(summary = "根据流水号获取支付", description = "根据支付流水号获取支付记录")
    public Result<PaymentResponse> getPaymentByNo(@PathVariable String paymentNo) {
        authorization.assertPaymentNumberAccess(paymentNo);
        return Result.success(paymentService.getPaymentByNo(paymentNo));
    }

    @GetMapping("/order/{orderId}")
    @Operation(summary = "获取订单支付记录", description = "获取指定订单的所有支付记录")
    public Result<List<PaymentResponse>> getPaymentsByOrder(@PathVariable Long orderId) {
        authorization.assertOrderAccess(orderId);
        return Result.success(paymentService.getPaymentsByOrderId(orderId));
    }

    @GetMapping("/my")
    @Operation(summary = "我的支付记录", description = "获取当前用户的支付记录")
    public Result<Page<PaymentResponse>> getMyPayments(
            @AuthenticationPrincipal UserDetails userDetails,
            Pageable pageable) {
        Long userId = getUserId(userDetails);
        return Result.success(paymentService.getPaymentsByPayer(userId, pageable));
    }

    @GetMapping("/received")
    @Operation(summary = "收款记录", description = "获取供应商的收款记录")
    public Result<Page<PaymentResponse>> getReceivedPayments(
            @AuthenticationPrincipal UserDetails userDetails,
            Pageable pageable) {
        Long userId = getUserId(userDetails);
        return Result.success(paymentService.getPaymentsByPayee(userId, pageable));
    }

    @PostMapping("/{id}/confirm")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "确认支付", description = "确认支付成功（模拟第三方回调）")
    public Result<PaymentResponse> confirmPayment(
            @PathVariable Long id,
            @RequestParam(required = false) String transactionId) {
        String txId = transactionId != null ? transactionId : "TX" + System.currentTimeMillis();
        return Result.success(paymentService.confirmPayment(id, txId));
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "取消支付", description = "取消待支付的支付记录")
    public Result<PaymentResponse> cancelPayment(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "用户取消") String reason) {
        authorization.assertPaymentPayerAccess(id);
        return Result.success(paymentService.cancelPayment(id, reason));
    }

    // ==================== 退款相关 ====================

    @PostMapping("/refunds")
    @Operation(summary = "申请退款", description = "创建退款申请")
    public Result<RefundResponse> createRefund(
            @Valid @RequestBody RefundCreateRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = getUserId(userDetails);
        authorization.assertOrderBuyerAccess(request.getOrderId());
        return Result.success(paymentService.createRefund(request, userId));
    }

    @GetMapping("/refunds/{id}")
    @Operation(summary = "获取退款详情", description = "根据ID获取退款记录详情")
    public Result<RefundResponse> getRefund(@PathVariable Long id) {
        authorization.assertRefundAccess(id);
        return Result.success(paymentService.getRefundById(id));
    }

    @GetMapping("/refunds/no/{refundNo}")
    @Operation(summary = "根据退款单号获取", description = "根据退款单号获取退款记录")
    public Result<RefundResponse> getRefundByNo(@PathVariable String refundNo) {
        authorization.assertRefundNumberAccess(refundNo);
        return Result.success(paymentService.getRefundByNo(refundNo));
    }

    @GetMapping("/refunds/order/{orderId}")
    @Operation(summary = "获取订单退款记录", description = "获取指定订单的所有退款记录")
    public Result<List<RefundResponse>> getRefundsByOrder(@PathVariable Long orderId) {
        authorization.assertOrderAccess(orderId);
        return Result.success(paymentService.getRefundsByOrderId(orderId));
    }

    @GetMapping("/refunds/my")
    @Operation(summary = "我的退款记录", description = "获取当前用户的退款申请记录")
    public Result<Page<RefundResponse>> getMyRefunds(
            @AuthenticationPrincipal UserDetails userDetails,
            Pageable pageable) {
        Long userId = getUserId(userDetails);
        return Result.success(paymentService.getRefundsByApplicant(userId, pageable));
    }

    @GetMapping("/refunds/pending")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "待审核退款", description = "获取待审核的退款申请列表（管理员）")
    public Result<Page<RefundResponse>> getPendingRefunds(Pageable pageable) {
        return Result.success(paymentService.getPendingRefunds(pageable));
    }

    @PostMapping("/refunds/{id}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "审核通过退款", description = "审核通过退款申请")
    public Result<RefundResponse> approveRefund(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "审核通过") String remark,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long auditorId = getUserId(userDetails);
        return Result.success(paymentService.approveRefund(id, auditorId, remark));
    }

    @PostMapping("/refunds/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "拒绝退款", description = "拒绝退款申请")
    public Result<RefundResponse> rejectRefund(
            @PathVariable Long id,
            @RequestParam String remark,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long auditorId = getUserId(userDetails);
        return Result.success(paymentService.rejectRefund(id, auditorId, remark));
    }

    @PostMapping("/refunds/{id}/process")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "处理退款", description = "执行退款操作（模拟）")
    public Result<RefundResponse> processRefund(
            @PathVariable Long id,
            @RequestParam(required = false) String transactionId) {
        String txId = transactionId != null ? transactionId : "REFTX" + System.currentTimeMillis();
        return Result.success(paymentService.processRefund(id, txId));
    }

    private Long getUserId(UserDetails userDetails) {
        return Long.parseLong(userDetails.getUsername());
    }
}
