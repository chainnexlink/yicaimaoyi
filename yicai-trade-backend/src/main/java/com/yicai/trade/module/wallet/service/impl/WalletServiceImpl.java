package com.yicai.trade.module.wallet.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.contract.entity.Contract;
import com.yicai.trade.module.contract.repository.ContractRepository;
import com.yicai.trade.module.wallet.dto.*;
import com.yicai.trade.module.wallet.entity.PlatformCommission;
import com.yicai.trade.module.wallet.entity.Wallet;
import com.yicai.trade.module.wallet.entity.WalletTransaction;
import com.yicai.trade.module.wallet.repository.PlatformCommissionRepository;
import com.yicai.trade.module.wallet.repository.WalletRepository;
import com.yicai.trade.module.wallet.repository.WalletTransactionRepository;
import com.yicai.trade.module.wallet.service.WalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WalletServiceImpl implements WalletService {

    private final WalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;
    private final PlatformCommissionRepository commissionRepository;
    private final ContractRepository contractRepository;

    /** 平台固定佣金比例 2% */
    private static final BigDecimal PLATFORM_FIXED_RATE = new BigDecimal("0.02");

    private static final Map<String, String> TX_TYPE_DISPLAY = Map.of(
            "COMMISSION_REBATE", "佣金返佣",
            "COMMISSION_INCOME", "平台佣金收入",
            "CONTRACT_INCOME", "合同收款",
            "WITHDRAW", "提现",
            "RECHARGE", "充值",
            "FREEZE", "冻结",
            "UNFREEZE", "解冻",
            "ADJUST", "平台调整"
    );

    private static final Map<String, String> COMMISSION_STATUS_DISPLAY = Map.of(
            "PENDING", "待收取",
            "COLLECTED", "已收取",
            "REBATED", "已返佣",
            "CANCELLED", "已取消"
    );

    // ===== 零钱钱包 =====

    @Override
    @Transactional
    public WalletResponse getOrCreateWallet(Long ownerId, String ownerType) {
        Wallet wallet = walletRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .orElseGet(() -> {
                    @lombok.NonNull Wallet w = Wallet.builder()
                            .ownerId(ownerId)
                            .ownerType(ownerType)
                            .build();
                    return walletRepository.save(w);
                });
        return toWalletResponse(wallet);
    }

    @Override
    public WalletResponse getWallet(Long ownerId, String ownerType) {
        Wallet wallet = walletRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "钱包不存在"));
        return toWalletResponse(wallet);
    }

    @Override
    public PageResult<WalletTransactionResponse> getTransactions(Long ownerId, String ownerType, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<WalletTransaction> p = transactionRepository.findByOwnerIdAndOwnerType(ownerId, ownerType, pr);
        return PageResult.of(
                p.getContent().stream().map(this::toTransactionResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public WalletResponse recharge(Long ownerId, String ownerType, BigDecimal amount, String description) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "充值金额必须大于0");
        }
        Wallet wallet = getOrCreateWalletEntity(ownerId, ownerType);
        BigDecimal before = wallet.getBalance();
        wallet.setBalance(before.add(amount));
        wallet.setTotalIncome(wallet.getTotalIncome().add(amount));
        walletRepository.save(wallet);

        recordTransaction(wallet, "RECHARGE", amount, before, wallet.getBalance(),
                null, null, null, description != null ? description : "账户充值");

        return toWalletResponse(wallet);
    }

    @Override
    @Transactional
    public WalletResponse withdraw(Long ownerId, String ownerType, BigDecimal amount, String description) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "提现金额必须大于0");
        }
        Wallet wallet = getOrCreateWalletEntity(ownerId, ownerType);
        BigDecimal available = wallet.getBalance().subtract(wallet.getFrozenAmount());
        if (amount.compareTo(available) > 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "可用余额不足，当前可用: " + available);
        }
        BigDecimal before = wallet.getBalance();
        wallet.setBalance(before.subtract(amount));
        wallet.setTotalExpense(wallet.getTotalExpense().add(amount));
        walletRepository.save(wallet);

        recordTransaction(wallet, "WITHDRAW", amount.negate(), before, wallet.getBalance(),
                null, null, null, description != null ? description : "账户提现");

        return toWalletResponse(wallet);
    }

    // ===== 平台佣金 =====

    @Override
    @Transactional
    @SuppressWarnings("null")
    public CommissionResponse createCommission(Long buyerId, CommissionCreateRequest request) {
        if (commissionRepository.existsByContractId(request.getContractId())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "该合同已存在佣金记录");
        }

        Contract contract = contractRepository.findById(request.getContractId())
                .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));

        if (!contract.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无权为该合同设置佣金");
        }

        return doCreateCommission(contract, request.getRebateRate());
    }

    @Override
    @Transactional
    public CommissionResponse ensureCommission(Long contractId, BigDecimal defaultRebateRate) {
        // 已存在则直接返回
        return commissionRepository.findByContractId(contractId)
                .map(this::toCommissionResponse)
                .orElseGet(() -> {
                    Contract contract = contractRepository.findById(contractId)
                            .orElseThrow(() -> new BusinessException(ErrorCode.CONTRACT_NOT_FOUND));
                    return doCreateCommission(contract, defaultRebateRate);
                });
    }

    @SuppressWarnings("null")
    private CommissionResponse doCreateCommission(Contract contract, BigDecimal rebateRate) {
        BigDecimal contractAmount = contract.getTotalAmount();
        BigDecimal platformFee = contractAmount.multiply(PLATFORM_FIXED_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal rebateAmount = contractAmount.multiply(rebateRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal totalServiceFee = platformFee.add(rebateAmount);

        @lombok.NonNull PlatformCommission commission = PlatformCommission.builder()
                .commissionNo(generateCommissionNo())
                .contractId(contract.getId())
                .contractNo(contract.getContractNo())
                .buyerId(contract.getBuyerId())
                .supplierId(contract.getSupplierId())
                .contractAmount(contractAmount)
                .platformRate(PLATFORM_FIXED_RATE)
                .platformFee(platformFee)
                .rebateRate(rebateRate)
                .rebateAmount(rebateAmount)
                .totalServiceFee(totalServiceFee)
                .build();

        return toCommissionResponse(commissionRepository.save(commission));
    }

    @Override
    @Transactional
    public CommissionResponse collectServiceFee(Long contractId) {
        PlatformCommission commission = commissionRepository.findByContractId(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "佣金记录不存在"));

        if (!"PENDING".equals(commission.getStatus())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "佣金状态不允许收取");
        }

        // 平台钱包入账（平台固定佣金部分）
        Wallet platformWallet = getOrCreateWalletEntity(0L, "PLATFORM");
        BigDecimal beforeBalance = platformWallet.getBalance();
        platformWallet.setBalance(beforeBalance.add(commission.getPlatformFee()));
        platformWallet.setTotalIncome(platformWallet.getTotalIncome().add(commission.getPlatformFee()));
        walletRepository.save(platformWallet);

        // 记录平台收入流水
        recordTransaction(platformWallet, "COMMISSION_INCOME", commission.getPlatformFee(),
                beforeBalance, platformWallet.getBalance(),
                commission.getContractId(), commission.getContractNo(), commission.getId(),
                "合同 " + commission.getContractNo() + " 平台佣金收入(2%)");

        // 更新佣金状态
        commission.setStatus("COLLECTED");
        commission.setCollectedAt(LocalDateTime.now());
        return toCommissionResponse(commissionRepository.save(commission));
    }

    @Override
    @Transactional
    public CommissionResponse executeRebate(Long contractId) {
        PlatformCommission commission = commissionRepository.findByContractId(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "佣金记录不存在"));

        if (!"COLLECTED".equals(commission.getStatus())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "佣金未收取或已返佣");
        }

        // 买方(客户)钱包入账返佣金额
        Wallet buyerWallet = getOrCreateWalletEntity(commission.getBuyerId(), "BUYER");
        BigDecimal beforeBalance = buyerWallet.getBalance();
        buyerWallet.setBalance(beforeBalance.add(commission.getRebateAmount()));
        buyerWallet.setTotalIncome(buyerWallet.getTotalIncome().add(commission.getRebateAmount()));
        walletRepository.save(buyerWallet);

        // 记录买方返佣流水
        recordTransaction(buyerWallet, "COMMISSION_REBATE", commission.getRebateAmount(),
                beforeBalance, buyerWallet.getBalance(),
                commission.getContractId(), commission.getContractNo(), commission.getId(),
                "合同 " + commission.getContractNo() + " 完成，返佣 " + commission.getRebateRate()
                        .multiply(new BigDecimal("100")).setScale(1, RoundingMode.HALF_UP) + "% 入零钱");

        // 更新佣金状态
        commission.setStatus("REBATED");
        commission.setRebatedAt(LocalDateTime.now());
        return toCommissionResponse(commissionRepository.save(commission));
    }

    @Override
    public CommissionResponse getCommissionByContract(Long contractId) {
        PlatformCommission commission = commissionRepository.findByContractId(contractId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "佣金记录不存在"));
        return toCommissionResponse(commission);
    }

    @Override
    public List<CommissionResponse> listBuyerCommissions(Long buyerId) {
        return commissionRepository.findByBuyerId(buyerId).stream()
                .map(this::toCommissionResponse)
                .collect(Collectors.toList());
    }

    @Override
    public PageResult<CommissionResponse> listAllCommissions(int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<PlatformCommission> p = commissionRepository.findAllBy(pr);
        return PageResult.of(
                p.getContent().stream().map(this::toCommissionResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public WalletResponse adjustBalance(Long ownerId, String ownerType, BigDecimal amount, String reason, Long operatorId) {
        Wallet wallet = getOrCreateWalletEntity(ownerId, ownerType);
        BigDecimal beforeBalance = wallet.getBalance();
        BigDecimal afterBalance = beforeBalance.add(amount);
        if (afterBalance.compareTo(BigDecimal.ZERO) < 0) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "调整后余额不能为负");
        }
        wallet.setBalance(afterBalance);
        if (amount.compareTo(BigDecimal.ZERO) > 0) {
            wallet.setTotalIncome(wallet.getTotalIncome().add(amount));
        } else {
            wallet.setTotalExpense(wallet.getTotalExpense().add(amount.abs()));
        }
        walletRepository.save(wallet);

        recordTransaction(wallet, "ADJUST", amount, beforeBalance, afterBalance,
                null, null, null, "平台调整: " + reason);

        return toWalletResponse(wallet);
    }

    // ===== 后台管理 =====

    @Override
    public List<WalletResponse> listWalletsByType(String ownerType) {
        return walletRepository.findByOwnerType(ownerType).stream()
                .map(this::toWalletResponse)
                .collect(Collectors.toList());
    }

    @Override
    public PageResult<WalletTransactionResponse> getAllTransactions(String ownerType, String transactionType, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<WalletTransaction> p;
        if (ownerType != null && !ownerType.isEmpty() && transactionType != null && !transactionType.isEmpty()) {
            p = transactionRepository.findByOwnerTypeAndTransactionType(ownerType, transactionType, pr);
        } else if (ownerType != null && !ownerType.isEmpty()) {
            p = transactionRepository.findByOwnerType(ownerType, pr);
        } else if (transactionType != null && !transactionType.isEmpty()) {
            p = transactionRepository.findByTransactionType(transactionType, pr);
        } else {
            p = transactionRepository.findAll(pr);
        }
        return PageResult.of(
                p.getContent().stream().map(this::toTransactionResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    public Map<String, Object> getWalletStats() {
        Map<String, Object> stats = new HashMap<>();

        // 三角色钱包统计
        List<Wallet> buyerWallets = walletRepository.findByOwnerType("BUYER");
        List<Wallet> supplierWallets = walletRepository.findByOwnerType("SUPPLIER");
        Wallet platformWallet = walletRepository.findByOwnerIdAndOwnerType(0L, "PLATFORM").orElse(null);

        BigDecimal buyerTotal = buyerWallets.stream().map(Wallet::getBalance).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal supplierTotal = supplierWallets.stream().map(Wallet::getBalance).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal platformBalance = platformWallet != null ? platformWallet.getBalance() : BigDecimal.ZERO;
        BigDecimal platformIncome = platformWallet != null ? platformWallet.getTotalIncome() : BigDecimal.ZERO;

        stats.put("buyerTotal", buyerTotal);
        stats.put("buyerCount", buyerWallets.size());
        stats.put("supplierTotal", supplierTotal);
        stats.put("supplierCount", supplierWallets.size());
        stats.put("platformBalance", platformBalance);
        stats.put("platformTotalIncome", platformIncome);
        stats.put("allTotal", buyerTotal.add(supplierTotal).add(platformBalance));

        // 佣金统计
        List<PlatformCommission> allCommissions = commissionRepository.findAll();
        BigDecimal totalPlatformFee = BigDecimal.ZERO;
        BigDecimal totalRebated = BigDecimal.ZERO;
        BigDecimal pendingRebate = BigDecimal.ZERO;
        int pendingCount = 0;
        for (PlatformCommission c : allCommissions) {
            totalPlatformFee = totalPlatformFee.add(c.getPlatformFee());
            if ("REBATED".equals(c.getStatus())) {
                totalRebated = totalRebated.add(c.getRebateAmount());
            }
            if ("PENDING".equals(c.getStatus()) || "COLLECTED".equals(c.getStatus())) {
                pendingRebate = pendingRebate.add(c.getRebateAmount());
                pendingCount++;
            }
        }
        stats.put("totalPlatformFee", totalPlatformFee);
        stats.put("totalRebated", totalRebated);
        stats.put("pendingRebate", pendingRebate);
        stats.put("pendingCount", pendingCount);

        return stats;
    }

    @Override
    public PageResult<CommissionResponse> listCommissionsByStatus(String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<PlatformCommission> p = commissionRepository.findByStatus(status, pr);
        return PageResult.of(
                p.getContent().stream().map(this::toCommissionResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public WalletResponse updateWalletStatus(Long ownerId, String ownerType, String status, String reason, Long operatorId) {
        Wallet wallet = walletRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "钱包不存在"));

        String oldStatus = wallet.getStatus();
        if (oldStatus.equals(status)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "钱包已处于 " + status + " 状态");
        }

        wallet.setStatus(status);
        walletRepository.save(wallet);

        String txType = "FROZEN".equals(status) ? "FREEZE" : "UNFREEZE";
        String desc = "管理员" + (operatorId != null ? "(ID:" + operatorId + ")" : "") + " 将账户状态从 "
                + oldStatus + " 变更为 " + status + (reason != null ? "，原因: " + reason : "");
        recordTransaction(wallet, txType, BigDecimal.ZERO, wallet.getBalance(), wallet.getBalance(),
                null, null, null, desc);

        return toWalletResponse(wallet);
    }

    // ===== 私有方法 =====

    private Wallet getOrCreateWalletEntity(Long ownerId, String ownerType) {
        return walletRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .orElseGet(() -> {
                    @lombok.NonNull Wallet w = Wallet.builder()
                            .ownerId(ownerId)
                            .ownerType(ownerType)
                            .build();
                    return walletRepository.save(w);
                });
    }

    private void recordTransaction(Wallet wallet, String type, BigDecimal amount,
                                   BigDecimal before, BigDecimal after,
                                   Long contractId, String contractNo, Long commissionId,
                                   String description) {
        @lombok.NonNull WalletTransaction tx = WalletTransaction.builder()
                .transactionNo(generateTxNo())
                .walletId(wallet.getId())
                .ownerId(wallet.getOwnerId())
                .ownerType(wallet.getOwnerType())
                .transactionType(type)
                .amount(amount)
                .balanceBefore(before)
                .balanceAfter(after)
                .contractId(contractId)
                .contractNo(contractNo)
                .commissionId(commissionId)
                .description(description)
                .build();
        transactionRepository.save(tx);
    }

    private String generateCommissionNo() {
        return "CM" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private String generateTxNo() {
        return "TX" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private WalletResponse toWalletResponse(Wallet w) {
        return WalletResponse.builder()
                .id(w.getId())
                .ownerId(w.getOwnerId())
                .ownerType(w.getOwnerType())
                .balance(w.getBalance())
                .frozenAmount(w.getFrozenAmount())
                .availableBalance(w.getBalance().subtract(w.getFrozenAmount()))
                .totalIncome(w.getTotalIncome())
                .totalExpense(w.getTotalExpense())
                .status(w.getStatus())
                .createdAt(w.getCreatedAt())
                .updatedAt(w.getUpdatedAt())
                .build();
    }

    private WalletTransactionResponse toTransactionResponse(WalletTransaction tx) {
        return WalletTransactionResponse.builder()
                .id(tx.getId())
                .transactionNo(tx.getTransactionNo())
                .walletId(tx.getWalletId())
                .ownerId(tx.getOwnerId())
                .ownerType(tx.getOwnerType())
                .transactionType(tx.getTransactionType())
                .transactionTypeDisplay(TX_TYPE_DISPLAY.getOrDefault(tx.getTransactionType(), tx.getTransactionType()))
                .amount(tx.getAmount())
                .balanceBefore(tx.getBalanceBefore())
                .balanceAfter(tx.getBalanceAfter())
                .contractId(tx.getContractId())
                .contractNo(tx.getContractNo())
                .commissionId(tx.getCommissionId())
                .description(tx.getDescription())
                .createdAt(tx.getCreatedAt())
                .build();
    }

    private CommissionResponse toCommissionResponse(PlatformCommission c) {
        return CommissionResponse.builder()
                .id(c.getId())
                .commissionNo(c.getCommissionNo())
                .contractId(c.getContractId())
                .contractNo(c.getContractNo())
                .buyerId(c.getBuyerId())
                .supplierId(c.getSupplierId())
                .contractAmount(c.getContractAmount())
                .platformRate(c.getPlatformRate())
                .platformFee(c.getPlatformFee())
                .rebateRate(c.getRebateRate())
                .rebateAmount(c.getRebateAmount())
                .totalServiceFee(c.getTotalServiceFee())
                .status(c.getStatus())
                .statusDisplay(COMMISSION_STATUS_DISPLAY.getOrDefault(c.getStatus(), c.getStatus()))
                .collectedAt(c.getCollectedAt())
                .rebatedAt(c.getRebatedAt())
                .remark(c.getRemark())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
