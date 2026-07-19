package com.yicai.trade.module.order.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.order.dto.EscrowResponse;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.entity.OrderEscrow;
import com.yicai.trade.module.order.repository.OrderEscrowRepository;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.order.service.EscrowService;
import com.yicai.trade.module.wallet.entity.Wallet;
import com.yicai.trade.module.wallet.entity.WalletTransaction;
import com.yicai.trade.module.wallet.repository.WalletRepository;
import com.yicai.trade.module.wallet.repository.WalletTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class EscrowServiceImpl implements EscrowService {

    private final OrderEscrowRepository escrowRepository;
    private final OrderRepository orderRepository;
    private final WalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;

    /** 平台固定佣金比例 2% */
    private static final BigDecimal PLATFORM_RATE = new BigDecimal("0.02");

    /** 默认返佣比例（如无佣金记录时的兜底） */
    private static final BigDecimal DEFAULT_REBATE_RATE = new BigDecimal("0.01");

    /** 默认托管释放天数 */
    private static final int DEFAULT_RELEASE_DAYS = 7;

    private static final Map<String, String> STATUS_DISPLAY = Map.of(
            "FROZEN", "资金托管中",
            "RELEASING", "释放审批中",
            "RELEASED", "已释放",
            "REFUNDED", "已退款"
    );

    @Override
    @Transactional
    @SuppressWarnings("null")
    public EscrowResponse createEscrow(Long orderId) {
        // 幂等：已存在则直接返回
        var existing = escrowRepository.findByOrderId(orderId);
        if (existing.isPresent()) {
            return toResponse(existing.get());
        }

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ORDER_NOT_FOUND));

        BigDecimal orderAmount = order.getTotalAmount();

        // 计算平台佣金 + 默认返佣（不纳入托管）
        BigDecimal commissionAmount = orderAmount.multiply(PLATFORM_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal rebateAmount = orderAmount.multiply(DEFAULT_REBATE_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal escrowAmount = orderAmount.subtract(commissionAmount).subtract(rebateAmount);

        // 确保托管金额不为负
        if (escrowAmount.compareTo(BigDecimal.ZERO) < 0) {
            escrowAmount = BigDecimal.ZERO;
        }

        LocalDateTime autoReleaseAt = LocalDateTime.now().plusDays(DEFAULT_RELEASE_DAYS);

        @lombok.NonNull OrderEscrow escrow = OrderEscrow.builder()
                .escrowNo(generateEscrowNo())
                .orderId(orderId)
                .orderNo(order.getOrderNo())
                .buyerId(order.getBuyerId())
                .supplierId(order.getSupplierId())
                .orderAmount(orderAmount)
                .escrowAmount(escrowAmount)
                .commissionAmount(commissionAmount)
                .rebateAmount(rebateAmount)
                .status("FROZEN")
                .releaseDays(DEFAULT_RELEASE_DAYS)
                .autoReleaseAt(autoReleaseAt)
                .build();
        escrowRepository.save(escrow);

        // 冻结平台钱包中的资金（FREEZE交易）
        freezePlatformFunds(escrow);

        log.info("创建订单托管: escrowNo={}, orderId={}, escrowAmount={}", escrow.getEscrowNo(), orderId, escrowAmount);
        return toResponse(escrow);
    }

    @Override
    public EscrowResponse getEscrowByOrderId(Long orderId) {
        OrderEscrow escrow = escrowRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "该订单无托管记录"));
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public EscrowResponse releaseEscrow(Long orderId) {
        OrderEscrow escrow = escrowRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "该订单无托管记录"));

        if (!"FROZEN".equals(escrow.getStatus()) && !"RELEASING".equals(escrow.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "当前托管状态不允许释放: " + escrow.getStatus());
        }

        // 释放资金到供应商钱包
        releaseToSupplier(escrow);

        escrow.setStatus("RELEASED");
        escrow.setReleasedAt(LocalDateTime.now());
        escrowRepository.save(escrow);

        log.info("托管资金释放: escrowNo={}, supplierId={}, amount={}", escrow.getEscrowNo(), escrow.getSupplierId(), escrow.getEscrowAmount());
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public EscrowResponse requestEarlyRelease(Long orderId, Long buyerId, String reason) {
        OrderEscrow escrow = escrowRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "该订单无托管记录"));

        if (!escrow.getBuyerId().equals(buyerId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "只有采购商可以申请提前释放");
        }
        if (!"FROZEN".equals(escrow.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "当前托管状态不允许申请提前释放");
        }

        escrow.setStatus("RELEASING");
        escrow.setEarlyReleaseReason(reason);
        escrow.setEarlyReleaseRequestedAt(LocalDateTime.now());
        escrowRepository.save(escrow);

        log.info("采购商申请提前释放托管: escrowNo={}, buyerId={}, reason={}", escrow.getEscrowNo(), buyerId, reason);
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public EscrowResponse approveEarlyRelease(Long escrowId, Long adminId, String remark) {
        OrderEscrow escrow = escrowRepository.findById(escrowId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "托管记录不存在"));

        if (!"RELEASING".equals(escrow.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "该托管记录不在审批状态");
        }

        // 释放资金到供应商
        releaseToSupplier(escrow);

        escrow.setStatus("RELEASED");
        escrow.setReleasedAt(LocalDateTime.now());
        escrow.setApprovedBy(adminId);
        escrow.setApprovalRemark(remark);
        escrowRepository.save(escrow);

        log.info("管理员批准提前释放: escrowNo={}, adminId={}", escrow.getEscrowNo(), adminId);
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public EscrowResponse rejectEarlyRelease(Long escrowId, Long adminId, String remark) {
        OrderEscrow escrow = escrowRepository.findById(escrowId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "托管记录不存在"));

        if (!"RELEASING".equals(escrow.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "该托管记录不在审批状态");
        }

        // 拒绝后恢复为 FROZEN
        escrow.setStatus("FROZEN");
        escrow.setApprovedBy(adminId);
        escrow.setApprovalRemark(remark);
        escrowRepository.save(escrow);

        log.info("管理员拒绝提前释放: escrowNo={}, adminId={}, reason={}", escrow.getEscrowNo(), adminId, remark);
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public EscrowResponse refundEscrow(Long orderId) {
        OrderEscrow escrow = escrowRepository.findByOrderId(orderId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "该订单无托管记录"));

        if (!"FROZEN".equals(escrow.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_OPERATION, "当前托管状态不允许退款");
        }

        // 解冻平台钱包，资金退回采购商
        refundToBuyer(escrow);

        escrow.setStatus("REFUNDED");
        escrow.setReleasedAt(LocalDateTime.now());
        escrowRepository.save(escrow);

        log.info("托管资金退款: escrowNo={}, buyerId={}, amount={}", escrow.getEscrowNo(), escrow.getBuyerId(), escrow.getEscrowAmount());
        return toResponse(escrow);
    }

    @Override
    @Transactional
    public int autoReleaseExpiredEscrows() {
        List<OrderEscrow> expired = escrowRepository.findByStatusAndAutoReleaseAtBefore("FROZEN", LocalDateTime.now());
        int count = 0;
        for (OrderEscrow escrow : expired) {
            try {
                // 检查订单是否已完成
                Order order = orderRepository.findById(escrow.getOrderId()).orElse(null);
                if (order != null && "COMPLETED".equals(order.getStatus())) {
                    releaseToSupplier(escrow);
                    escrow.setStatus("RELEASED");
                    escrow.setReleasedAt(LocalDateTime.now());
                    escrow.setApprovalRemark("系统自动释放（订单已完成且已过托管期）");
                    escrowRepository.save(escrow);
                    count++;
                    log.info("自动释放托管资金: escrowNo={}, orderId={}", escrow.getEscrowNo(), escrow.getOrderId());
                }
            } catch (Exception e) {
                log.error("自动释放托管失败: escrowNo={}, error={}", escrow.getEscrowNo(), e.getMessage());
            }
        }
        return count;
    }

    @Override
    public PageResult<EscrowResponse> listEscrowsByStatus(String status, int page, int size) {
        Page<OrderEscrow> p = escrowRepository.findByStatus(status,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<EscrowResponse> listBuyerEscrows(Long buyerId, int page, int size) {
        Page<OrderEscrow> p = escrowRepository.findByBuyerId(buyerId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<EscrowResponse> listSupplierEscrows(Long supplierId, int page, int size) {
        Page<OrderEscrow> p = escrowRepository.findBySupplierId(supplierId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResult.of(p.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    // ===== 资金操作 =====

    private void freezePlatformFunds(OrderEscrow escrow) {
        // 在平台钱包上记录冻结
        Wallet platformWallet = getOrCreateWallet(0L, "PLATFORM");
        BigDecimal before = platformWallet.getBalance();
        // 托管金额入平台余额并同时冻结
        platformWallet.setBalance(before.add(escrow.getEscrowAmount()));
        platformWallet.setFrozenAmount(platformWallet.getFrozenAmount().add(escrow.getEscrowAmount()));
        platformWallet.setTotalIncome(platformWallet.getTotalIncome().add(escrow.getEscrowAmount()));
        walletRepository.save(platformWallet);

        recordTx(platformWallet, "FREEZE", escrow.getEscrowAmount(), before, platformWallet.getBalance(),
                "订单托管冻结 [" + escrow.getOrderNo() + "] 金额 ¥" + escrow.getEscrowAmount());
    }

    private void releaseToSupplier(OrderEscrow escrow) {
        // 1. 平台钱包解冻并扣减
        Wallet platformWallet = getOrCreateWallet(0L, "PLATFORM");
        BigDecimal pBefore = platformWallet.getBalance();
        platformWallet.setBalance(pBefore.subtract(escrow.getEscrowAmount()));
        platformWallet.setFrozenAmount(platformWallet.getFrozenAmount().subtract(escrow.getEscrowAmount()));
        platformWallet.setTotalExpense(platformWallet.getTotalExpense().add(escrow.getEscrowAmount()));
        walletRepository.save(platformWallet);

        recordTx(platformWallet, "UNFREEZE", escrow.getEscrowAmount().negate(), pBefore, platformWallet.getBalance(),
                "订单托管释放 [" + escrow.getOrderNo() + "] → 供应商");

        // 2. 供应商钱包入账
        Wallet supplierWallet = getOrCreateWallet(escrow.getSupplierId(), "SUPPLIER");
        BigDecimal sBefore = supplierWallet.getBalance();
        supplierWallet.setBalance(sBefore.add(escrow.getEscrowAmount()));
        supplierWallet.setTotalIncome(supplierWallet.getTotalIncome().add(escrow.getEscrowAmount()));
        walletRepository.save(supplierWallet);

        recordTx(supplierWallet, "RECHARGE", escrow.getEscrowAmount(), sBefore, supplierWallet.getBalance(),
                "订单托管到账 [" + escrow.getOrderNo() + "]");
    }

    private void refundToBuyer(OrderEscrow escrow) {
        // 1. 平台钱包解冻并扣减
        Wallet platformWallet = getOrCreateWallet(0L, "PLATFORM");
        BigDecimal pBefore = platformWallet.getBalance();
        platformWallet.setBalance(pBefore.subtract(escrow.getEscrowAmount()));
        platformWallet.setFrozenAmount(platformWallet.getFrozenAmount().subtract(escrow.getEscrowAmount()));
        platformWallet.setTotalExpense(platformWallet.getTotalExpense().add(escrow.getEscrowAmount()));
        walletRepository.save(platformWallet);

        recordTx(platformWallet, "UNFREEZE", escrow.getEscrowAmount().negate(), pBefore, platformWallet.getBalance(),
                "订单托管退款 [" + escrow.getOrderNo() + "] → 采购商");

        // 2. 采购商钱包入账
        Wallet buyerWallet = getOrCreateWallet(escrow.getBuyerId(), "BUYER");
        BigDecimal bBefore = buyerWallet.getBalance();
        buyerWallet.setBalance(bBefore.add(escrow.getEscrowAmount()));
        buyerWallet.setTotalIncome(buyerWallet.getTotalIncome().add(escrow.getEscrowAmount()));
        walletRepository.save(buyerWallet);

        recordTx(buyerWallet, "RECHARGE", escrow.getEscrowAmount(), bBefore, buyerWallet.getBalance(),
                "订单托管退款到账 [" + escrow.getOrderNo() + "]");
    }

    // ===== helpers =====

    private Wallet getOrCreateWallet(Long ownerId, String ownerType) {
        return walletRepository.findByOwnerIdAndOwnerType(ownerId, ownerType)
                .orElseGet(() -> {
                    @lombok.NonNull Wallet w = Wallet.builder()
                            .ownerId(ownerId)
                            .ownerType(ownerType)
                            .build();
                    return walletRepository.save(w);
                });
    }

    private void recordTx(Wallet wallet, String type, BigDecimal amount,
                           BigDecimal before, BigDecimal after, String description) {
        @lombok.NonNull WalletTransaction tx = WalletTransaction.builder()
                .transactionNo(generateTxNo())
                .walletId(wallet.getId())
                .ownerId(wallet.getOwnerId())
                .ownerType(wallet.getOwnerType())
                .transactionType(type)
                .amount(amount)
                .balanceBefore(before)
                .balanceAfter(after)
                .description(description)
                .build();
        transactionRepository.save(tx);
    }

    private String generateEscrowNo() {
        return "ES" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private String generateTxNo() {
        return "TX" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + ThreadLocalRandom.current().nextInt(1000, 9999);
    }

    private EscrowResponse toResponse(OrderEscrow e) {
        return EscrowResponse.builder()
                .id(e.getId())
                .escrowNo(e.getEscrowNo())
                .orderId(e.getOrderId())
                .orderNo(e.getOrderNo())
                .buyerId(e.getBuyerId())
                .supplierId(e.getSupplierId())
                .orderAmount(e.getOrderAmount())
                .escrowAmount(e.getEscrowAmount())
                .commissionAmount(e.getCommissionAmount())
                .rebateAmount(e.getRebateAmount())
                .status(e.getStatus())
                .statusText(STATUS_DISPLAY.getOrDefault(e.getStatus(), e.getStatus()))
                .releaseDays(e.getReleaseDays())
                .autoReleaseAt(e.getAutoReleaseAt())
                .releasedAt(e.getReleasedAt())
                .earlyReleaseReason(e.getEarlyReleaseReason())
                .earlyReleaseRequestedAt(e.getEarlyReleaseRequestedAt())
                .approvedBy(e.getApprovedBy())
                .approvalRemark(e.getApprovalRemark())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }
}
