package com.yicai.trade.module.wallet.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.wallet.dto.*;
import com.yicai.trade.module.wallet.service.WalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
@Tag(name = "WalletManagement", description = "零钱钱包与佣金管理")
public class WalletController {

    private final WalletService walletService;
    private final ResourceAuthorizationService authorization;

    // ===== 零钱钱包 =====

    @GetMapping("/{ownerType}/{ownerId}")
    @Operation(summary = "查询零钱钱包", description = "获取或创建指定角色的零钱钱包")
    public Result<WalletResponse> getWallet(@PathVariable String ownerType, @PathVariable Long ownerId) {
        authorization.assertPartyAccess(ownerType, ownerId);
        return Result.success(walletService.getOrCreateWallet(ownerId, ownerType.toUpperCase()));
    }

    @GetMapping("/{ownerType}/{ownerId}/transactions")
    @Operation(summary = "查询零钱流水")
    public Result<PageResult<WalletTransactionResponse>> getTransactions(
            @PathVariable String ownerType,
            @PathVariable Long ownerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        authorization.assertPartyAccess(ownerType, ownerId);
        return Result.success(walletService.getTransactions(ownerId, ownerType.toUpperCase(), page, size));
    }

    @PostMapping("/{ownerType}/{ownerId}/recharge")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "充值", description = "向零钱账户充值")
    public Result<WalletResponse> recharge(
            @PathVariable String ownerType,
            @PathVariable Long ownerId,
            @RequestParam BigDecimal amount,
            @RequestParam(required = false) String description) {
        return Result.success(walletService.recharge(ownerId, ownerType.toUpperCase(), amount, description));
    }

    @PostMapping("/{ownerType}/{ownerId}/withdraw")
    @Operation(summary = "提现", description = "从零钱账户提现")
    public Result<WalletResponse> withdraw(
            @PathVariable String ownerType,
            @PathVariable Long ownerId,
            @RequestParam BigDecimal amount,
            @RequestParam(required = false) String description) {
        authorization.assertPartyAccess(ownerType, ownerId);
        return Result.success(walletService.withdraw(ownerId, ownerType.toUpperCase(), amount, description));
    }

    // ===== 平台佣金 =====

    @PostMapping("/commission")
    @Operation(summary = "创建佣金记录", description = "客户在合同确认时设置返佣比例(1%-10%)")
    public Result<CommissionResponse> createCommission(
            @RequestParam Long buyerId,
            @RequestBody @Valid CommissionCreateRequest request) {
        authorization.assertBuyerAccess(buyerId);
        authorization.assertContractPartyAccess(request.getContractId(), buyerId);
        return Result.success(walletService.createCommission(buyerId, request));
    }

    @GetMapping("/commission/contract/{contractId}")
    @Operation(summary = "查询合同佣金信息")
    public Result<CommissionResponse> getCommissionByContract(@PathVariable Long contractId) {
        authorization.assertContractAccess(contractId);
        return Result.success(walletService.getCommissionByContract(contractId));
    }

    @GetMapping("/commission/buyer/{buyerId}")
    @Operation(summary = "查询客户所有佣金记录")
    public Result<List<CommissionResponse>> listBuyerCommissions(@PathVariable Long buyerId) {
        authorization.assertBuyerAccess(buyerId);
        return Result.success(walletService.listBuyerCommissions(buyerId));
    }

    // ===== 平台管理 =====

    @PostMapping("/commission/{contractId}/collect")
    @Operation(summary = "收取服务费", description = "平台管理员确认收取服务费")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<CommissionResponse> collectServiceFee(@PathVariable Long contractId) {
        return Result.success(walletService.collectServiceFee(contractId));
    }

    @PostMapping("/commission/{contractId}/rebate")
    @Operation(summary = "执行返佣", description = "合同完成后将返佣金额入客户零钱")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<CommissionResponse> executeRebate(@PathVariable Long contractId) {
        return Result.success(walletService.executeRebate(contractId));
    }

    @GetMapping("/commission/all")
    @Operation(summary = "后台查询所有佣金记录")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<PageResult<CommissionResponse>> listAllCommissions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(walletService.listAllCommissions(page, size));
    }

    @PostMapping("/{ownerType}/{ownerId}/adjust")
    @Operation(summary = "平台调整余额", description = "管理员手动调整用户零钱余额")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<WalletResponse> adjustBalance(
            @PathVariable String ownerType,
            @PathVariable Long ownerId,
            @RequestParam BigDecimal amount,
            @RequestParam String reason,
            @RequestParam Long operatorId) {
        return Result.success(walletService.adjustBalance(ownerId, ownerType.toUpperCase(), amount, reason, operatorId));
    }

    // ===== 后台管理 =====

    @GetMapping("/admin/wallets/{ownerType}")
    @Operation(summary = "按角色列出所有钱包", description = "管理员查看指定角色的所有钱包账户")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<List<WalletResponse>> listWalletsByType(@PathVariable String ownerType) {
        return Result.success(walletService.listWalletsByType(ownerType.toUpperCase()));
    }

    @GetMapping("/admin/transactions")
    @Operation(summary = "全部零钱流水", description = "管理员查看所有角色的流水记录")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<PageResult<WalletTransactionResponse>> getAllTransactions(
            @RequestParam(required = false) String ownerType,
            @RequestParam(required = false) String transactionType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return Result.success(walletService.getAllTransactions(
                ownerType != null ? ownerType.toUpperCase() : null, transactionType, page, size));
    }

    @GetMapping("/admin/stats")
    @Operation(summary = "钱包统计汇总", description = "三角色钱包余额与佣金统计")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<Map<String, Object>> getWalletStats() {
        return Result.success(walletService.getWalletStats());
    }

    @GetMapping("/commission/status/{status}")
    @Operation(summary = "按状态查询佣金记录")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<PageResult<CommissionResponse>> listCommissionsByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return Result.success(walletService.listCommissionsByStatus(status.toUpperCase(), page, size));
    }

    @PutMapping("/{ownerType}/{ownerId}/status")
    @Operation(summary = "更新钱包状态", description = "管理员冻结/解冻/关闭钱包账户")
    @PreAuthorize("hasRole('ADMIN')")
    public Result<WalletResponse> updateWalletStatus(
            @PathVariable String ownerType,
            @PathVariable Long ownerId,
            @RequestParam String status,
            @RequestParam(required = false) String reason,
            @RequestParam(required = false) Long operatorId) {
        return Result.success(walletService.updateWalletStatus(ownerId, ownerType.toUpperCase(), status.toUpperCase(), reason, operatorId));
    }
}
