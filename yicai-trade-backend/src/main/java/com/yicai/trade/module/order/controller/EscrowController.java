package com.yicai.trade.module.order.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.order.dto.EscrowResponse;
import com.yicai.trade.module.order.service.EscrowService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/escrow")
@RequiredArgsConstructor
@Tag(name = "EscrowManagement", description = "订单资金托管（类淘宝担保交易）")
public class EscrowController {

    private final EscrowService escrowService;
    private final ResourceAuthorizationService authorization;

    @GetMapping("/order/{orderId}")
    @Operation(summary = "查询订单托管信息")
    public Result<EscrowResponse> getByOrderId(@PathVariable Long orderId) {
        authorization.assertOrderAccess(orderId);
        return Result.success(escrowService.getEscrowByOrderId(orderId));
    }

    @PostMapping("/order/{orderId}/early-release")
    @Operation(summary = "采购商申请提前释放", description = "FROZEN → RELEASING，等待管理员审批")
    public Result<EscrowResponse> requestEarlyRelease(
            @PathVariable Long orderId,
            @RequestParam Long buyerId,
            @RequestParam(required = false) String reason) {
        authorization.assertOrderBuyerAccess(orderId);
        authorization.assertBuyerAccess(buyerId);
        return Result.success(escrowService.requestEarlyRelease(orderId, buyerId, reason != null ? reason : "采购商申请提前释放"));
    }

    // ===== 管理员操作 =====

    @GetMapping("/admin/list")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "后台托管列表（按状态）")
    public Result<PageResult<EscrowResponse>> listByStatus(
            @RequestParam(defaultValue = "FROZEN") String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(escrowService.listEscrowsByStatus(status, page, size));
    }

    @GetMapping("/admin/pending")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "待审批的提前释放申请")
    public Result<PageResult<EscrowResponse>> listPending(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(escrowService.listEscrowsByStatus("RELEASING", page, size));
    }

    @PostMapping("/admin/{escrowId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "批准提前释放", description = "RELEASING → RELEASED")
    public Result<EscrowResponse> approve(
            @PathVariable Long escrowId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String remark) {
        Long adminId = Long.parseLong(userDetails.getUsername());
        return Result.success(escrowService.approveEarlyRelease(escrowId, adminId, remark != null ? remark : "管理员批准"));
    }

    @PostMapping("/admin/{escrowId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "拒绝提前释放", description = "RELEASING → FROZEN")
    public Result<EscrowResponse> reject(
            @PathVariable Long escrowId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String remark) {
        Long adminId = Long.parseLong(userDetails.getUsername());
        return Result.success(escrowService.rejectEarlyRelease(escrowId, adminId, remark != null ? remark : "管理员拒绝"));
    }

    @PostMapping("/admin/auto-release")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "手动触发自动释放检查", description = "释放所有已到期且订单已完成的托管")
    public Result<Map<String, Object>> triggerAutoRelease() {
        int count = escrowService.autoReleaseExpiredEscrows();
        return Result.success(Map.of("released", count));
    }

    @PostMapping("/admin/order/{orderId}/refund")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "管理员手动退款托管资金", description = "FROZEN → REFUNDED")
    public Result<EscrowResponse> refund(@PathVariable Long orderId) {
        return Result.success(escrowService.refundEscrow(orderId));
    }

    // ===== 用户侧查询 =====

    @GetMapping("/buyer/{buyerId}")
    @Operation(summary = "采购商托管列表")
    public Result<PageResult<EscrowResponse>> listBuyerEscrows(
            @PathVariable Long buyerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorization.assertBuyerAccess(buyerId);
        return Result.success(escrowService.listBuyerEscrows(buyerId, page, size));
    }

    @GetMapping("/supplier/{supplierId}")
    @Operation(summary = "供应商托管列表")
    public Result<PageResult<EscrowResponse>> listSupplierEscrows(
            @PathVariable Long supplierId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        authorization.assertSupplierAccess(supplierId);
        return Result.success(escrowService.listSupplierEscrows(supplierId, page, size));
    }
}
