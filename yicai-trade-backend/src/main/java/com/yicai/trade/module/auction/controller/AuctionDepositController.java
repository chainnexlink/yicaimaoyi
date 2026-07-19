package com.yicai.trade.module.auction.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.auction.service.AuctionDepositService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Tag(name = "AuctionDeposit", description = "拍卖押金与抵用券API")
@RestController
@RequestMapping("/api/v1/auction/deposit")
@RequiredArgsConstructor
public class AuctionDepositController {

    private final AuctionDepositService depositService;

    // ========== 押金操作 ==========

    @Operation(summary = "采购商缴纳发布押金")
    @PostMapping("/buyer/pay")
    public Result<Map<String, Object>> payBuyerDeposit(
            @RequestParam(name = "auctionId") Long auctionId,
            @RequestParam(name = "voucherId", required = false) Long voucherId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(depositService.payBuyerDeposit(auctionId, userId, voucherId));
    }

    @Operation(summary = "供应商缴纳竞拍押金")
    @PostMapping("/supplier/pay")
    public Result<Map<String, Object>> paySupplierDeposit(
            @RequestParam(name = "auctionId") Long auctionId,
            @RequestParam(name = "voucherId", required = false) Long voucherId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(depositService.paySupplierDeposit(auctionId, userId, voucherId));
    }

    @Operation(summary = "检查是否已缴押金")
    @GetMapping("/check")
    public Result<Map<String, Object>> checkDeposit(
            @RequestParam(name = "auctionId") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        boolean hasPaid = depositService.hasValidDeposit(auctionId, userId);
        return Result.success(Map.of(
                "hasPaid", hasPaid,
                "buyerAmount", depositService.getBuyerDepositAmount(),
                "supplierAmount", depositService.getSupplierDepositAmount()
        ));
    }

    // ========== 抵用券操作 ==========

    @Operation(summary = "获取我的可用抵用券")
    @GetMapping("/vouchers/my")
    public Result<List<Map<String, Object>>> getMyVouchers(
            @RequestParam(name = "voucherType", required = false) String voucherType,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(depositService.getUserVouchers(userId, voucherType));
    }

    // ========== 管理员API ==========

    @Operation(summary = "管理员-获取押金配置")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/config")
    public Result<List<Map<String, Object>>> getDepositConfig() {
        return Result.success(depositService.getAllConfig());
    }

    @Operation(summary = "管理员-更新押金配置")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/config/update")
    public Result<Void> updateConfig(
            @RequestParam(name = "key") String key,
            @RequestParam(name = "value") String value,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long adminId = Long.parseLong(userDetails.getUsername());
        depositService.updateConfig(key, value, adminId);
        return Result.success(null);
    }

    @Operation(summary = "管理员-发放抵用券")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/voucher/issue")
    public Result<Void> issueVouchers(
            @RequestParam(name = "userId") Long userId,
            @RequestParam(name = "userType") String userType,
            @RequestParam(name = "count", defaultValue = "1") int count,
            @RequestParam(name = "faceValue") BigDecimal faceValue,
            @RequestParam(name = "remark", required = false) String remark,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long adminId = Long.parseLong(userDetails.getUsername());
        depositService.adminIssueVouchers(userId, userType, count, faceValue, adminId, remark);
        return Result.success(null);
    }

    @Operation(summary = "管理员-撤销抵用券")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/voucher/{id}/revoke")
    public Result<Void> revokeVoucher(
            @PathVariable("id") Long voucherId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long adminId = Long.parseLong(userDetails.getUsername());
        depositService.revokeVoucher(voucherId, adminId);
        return Result.success(null);
    }

    @Operation(summary = "管理员-退还押金")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{id}/refund")
    public Result<Void> refundDeposit(
            @PathVariable("id") Long depositId,
            @RequestParam(name = "reason", defaultValue = "管理员手动退还") String reason) {
        depositService.refundDeposit(depositId, reason);
        return Result.success(null);
    }

    @Operation(summary = "管理员-没收押金")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{id}/forfeit")
    public Result<Void> forfeitDeposit(
            @PathVariable("id") Long depositId,
            @RequestParam(name = "reason") String reason) {
        depositService.forfeitDeposit(depositId, reason);
        return Result.success(null);
    }

    @Operation(summary = "管理员-批量退还拍卖押金")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/auction/{auctionId}/refund-all")
    public Result<Void> refundAllDeposits(
            @PathVariable("auctionId") Long auctionId,
            @RequestParam(name = "reason", defaultValue = "拍卖结束,批量退还") String reason) {
        depositService.refundAllDeposits(auctionId, reason);
        return Result.success(null);
    }

    @Operation(summary = "管理员-查看用户抵用券")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/vouchers/{userId}")
    public Result<List<Map<String, Object>>> getUserVouchers(
            @PathVariable("userId") Long userId,
            @RequestParam(name = "voucherType", required = false) String voucherType) {
        return Result.success(depositService.getUserVouchers(userId, voucherType));
    }

    @Operation(summary = "管理员-押金统计")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/stats")
    public Result<Map<String, Object>> getDepositStats() {
        return Result.success(depositService.getDepositStats());
    }

    @Operation(summary = "管理员-押金记录列表")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/records")
    public Result<List<Map<String, Object>>> getDepositRecords(
            @RequestParam(name = "status", required = false) String status) {
        return Result.success(depositService.getDepositRecords(status));
    }
}
