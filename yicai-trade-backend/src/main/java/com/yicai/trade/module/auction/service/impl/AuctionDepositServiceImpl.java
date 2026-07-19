package com.yicai.trade.module.auction.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.module.auction.entity.*;
import com.yicai.trade.module.auction.repository.*;
import com.yicai.trade.module.auction.service.AuctionDepositService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuctionDepositServiceImpl implements AuctionDepositService {

    private final AuctionDepositRepository depositRepository;
    private final DepositVoucherRepository voucherRepository;
    private final AuctionDepositConfigRepository configRepository;
    private final AuctionRepository auctionRepository;

    @Override
    @Transactional
    public Map<String, Object> payBuyerDeposit(Long auctionId, Long buyerId, Long voucherId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new BusinessException(404, "竞价不存在"));
        if (!buyerId.equals(auction.getBuyerId())) {
            throw new BusinessException(403, "无权为该竞价缴纳发布押金");
        }
        rejectDuplicateDeposit(auctionId, buyerId);
        if (voucherId == null) {
            throw new BusinessException(503, "在线押金支付尚未接入，请使用有效抵用券或联系平台审核");
        }
        BigDecimal amount = getBuyerDepositAmount();
        AuctionDeposit deposit = new AuctionDeposit();
        deposit.setDepositNo(newDepositNo());
        deposit.setAuctionId(auctionId);
        deposit.setAuctionNo(auction.getAuctionNo());
        deposit.setUserId(buyerId);
        deposit.setUserType("BUYER");
        deposit.setAmount(amount);
        deposit.setCurrency("USD");
        deposit.setStatus("PAID");
        deposit.setPaidAt(LocalDateTime.now());
        DepositVoucher voucher = voucherRepository.findById(voucherId)
                .orElseThrow(() -> new BusinessException(404, "抵用券不存在"));
        validateVoucher(voucher, buyerId, "BUYER_DEPOSIT", amount);
        voucher.setStatus("USED");
        voucher.setUsedAt(LocalDateTime.now());
        voucherRepository.save(voucher);
        deposit.setVoucherId(voucherId);
        deposit.setPaymentMethod("VOUCHER");
        AuctionDeposit saved = depositRepository.save(deposit);
        return depositToMap(saved);
    }

    @Override
    @Transactional
    public Map<String, Object> paySupplierDeposit(Long auctionId, Long supplierId, Long voucherId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new BusinessException(404, "竞价不存在"));
        rejectDuplicateDeposit(auctionId, supplierId);
        if (voucherId == null) {
            throw new BusinessException(503, "在线押金支付尚未接入，请使用有效抵用券或联系平台审核");
        }
        BigDecimal amount = getSupplierDepositAmount();
        AuctionDeposit deposit = new AuctionDeposit();
        deposit.setDepositNo(newDepositNo());
        deposit.setAuctionId(auctionId);
        deposit.setAuctionNo(auction.getAuctionNo());
        deposit.setUserId(supplierId);
        deposit.setUserType("SUPPLIER");
        deposit.setAmount(amount);
        deposit.setCurrency("USD");
        deposit.setStatus("PAID");
        deposit.setPaidAt(LocalDateTime.now());
        DepositVoucher voucher = voucherRepository.findById(voucherId)
                .orElseThrow(() -> new BusinessException(404, "抵用券不存在"));
        validateVoucher(voucher, supplierId, "SUPPLIER_DEPOSIT", amount);
        voucher.setStatus("USED");
        voucher.setUsedAt(LocalDateTime.now());
        voucherRepository.save(voucher);
        deposit.setVoucherId(voucherId);
        deposit.setPaymentMethod("VOUCHER");
        AuctionDeposit saved = depositRepository.save(deposit);
        return depositToMap(saved);
    }

    @Override
    @Transactional
    public void refundDeposit(Long depositId, String reason) {
        AuctionDeposit deposit = depositRepository.findById(depositId)
                .orElseThrow(() -> new RuntimeException("\u62bc\u91d1\u8bb0\u5f55\u4e0d\u5b58\u5728"));
        if (!"PAID".equals(deposit.getStatus())) throw new RuntimeException("\u53ea\u80fd\u9000\u8fd8\u5df2\u7f34\u7eb3\u7684\u62bc\u91d1");
        deposit.setStatus("REFUNDED");
        deposit.setRefundedAt(LocalDateTime.now());
        deposit.setRefundReason(reason);
        depositRepository.save(deposit);
        if (deposit.getVoucherId() != null) {
            voucherRepository.findById(deposit.getVoucherId()).ifPresent(v -> {
                v.setStatus("ACTIVE");
                v.setUsedAt(null);
                voucherRepository.save(v);
            });
        }
        log.info("押金已退还: depositId={}, reason={}", depositId, reason);
    }

    @Override
    @Transactional
    public void refundAllDeposits(Long auctionId, String reason) {
        List<AuctionDeposit> paidDeposits = depositRepository.findByAuctionIdAndStatus(auctionId, "PAID");
        for (AuctionDeposit deposit : paidDeposits) {
            deposit.setStatus("REFUNDED");
            deposit.setRefundedAt(LocalDateTime.now());
            deposit.setRefundReason(reason);
            depositRepository.save(deposit);
        }
        log.info("批量退还拍卖[{}]押金{}笔, reason={}", auctionId, paidDeposits.size(), reason);
    }

    @Override
    @Transactional
    public void forfeitDeposit(Long depositId, String reason) {
        AuctionDeposit deposit = depositRepository.findById(depositId)
                .orElseThrow(() -> new RuntimeException("\u62bc\u91d1\u8bb0\u5f55\u4e0d\u5b58\u5728"));
        if (!"PAID".equals(deposit.getStatus())) throw new RuntimeException("\u53ea\u80fd\u6ca1\u6536\u5df2\u7f34\u7eb3\u7684\u62bc\u91d1");
        deposit.setStatus("FORFEITED");
        deposit.setRefundReason(reason);
        depositRepository.save(deposit);
        log.info("押金已没收: depositId={}, reason={}", depositId, reason);
    }

    @Override
    public boolean hasValidDeposit(Long auctionId, Long userId) {
        return depositRepository.existsByAuctionIdAndUserIdAndStatusIn(auctionId, userId, List.of("PAID"));
    }

    @Override
    @Transactional
    public void issueRegisterVouchers(Long userId, String userType) {
        int count;
        BigDecimal faceValue;
        String voucherType;
        if ("BUYER".equals(userType)) {
            count = Integer.parseInt(getConfigValue("BUYER_REGISTER_VOUCHERS", "3"));
            faceValue = getBuyerDepositAmount();
            voucherType = "BUYER_DEPOSIT";
        } else if ("SUPPLIER".equals(userType)) {
            count = Integer.parseInt(getConfigValue("SUPPLIER_REGISTER_VOUCHERS", "10"));
            faceValue = getSupplierDepositAmount();
            voucherType = "SUPPLIER_DEPOSIT";
        } else {
            return;
        }
        int validDays = Integer.parseInt(getConfigValue("VOUCHER_VALIDITY_DAYS", "365"));
        for (int i = 0; i < count; i++) {
            DepositVoucher v = new DepositVoucher();
            v.setVoucherNo("VCH" + System.currentTimeMillis() + String.format("%03d", i));
            v.setUserId(userId);
            v.setUserType(userType);
            v.setVoucherType(voucherType);
            v.setFaceValue(faceValue);
            v.setCurrency("USD");
            v.setStatus("ACTIVE");
            v.setSource("REGISTER");
            v.setExpiresAt(LocalDateTime.now().plusDays(validDays));
            v.setRemark("注册赠送押金抵用券");
            voucherRepository.save(v);
        }
        log.info("注册赠送抵用券: userId={}, userType={}, count={}", userId, userType, count);
    }

    @Override
    @Transactional
    public void adminIssueVouchers(Long userId, String userType, int count,
                                    BigDecimal faceValue, Long adminId, String remark) {
        String voucherType = "BUYER".equals(userType) ? "BUYER_DEPOSIT" : "SUPPLIER_DEPOSIT";
        int validDays = Integer.parseInt(getConfigValue("VOUCHER_VALIDITY_DAYS", "365"));
        for (int i = 0; i < count; i++) {
            DepositVoucher v = new DepositVoucher();
            v.setVoucherNo("VCH" + System.currentTimeMillis() + String.format("%03d", i));
            v.setUserId(userId);
            v.setUserType(userType);
            v.setVoucherType(voucherType);
            v.setFaceValue(faceValue);
            v.setCurrency("USD");
            v.setStatus("ACTIVE");
            v.setSource("ADMIN_ISSUE");
            v.setExpiresAt(LocalDateTime.now().plusDays(validDays));
            v.setIssuedBy(adminId);
            v.setRemark(remark != null ? remark : "管理员手动发放");
            voucherRepository.save(v);
        }
        log.info("管理员发放抵用券: userId={}, count={}, adminId={}", userId, count, adminId);
    }

    @Override
    public List<Map<String, Object>> getUserVouchers(Long userId, String voucherType) {
        List<DepositVoucher> vouchers;
        if (voucherType != null && !voucherType.isEmpty()) {
            vouchers = voucherRepository.findByUserIdAndVoucherTypeAndStatusOrderByExpiresAtAsc(userId, voucherType, "ACTIVE");
        } else {
            vouchers = voucherRepository.findByUserIdAndStatusOrderByExpiresAtAsc(userId, "ACTIVE");
        }
        return vouchers.stream().map(this::voucherToMap).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void revokeVoucher(Long voucherId, Long adminId) {
        DepositVoucher voucher = voucherRepository.findById(voucherId)
                .orElseThrow(() -> new RuntimeException("\u62b5\u7528\u5238\u4e0d\u5b58\u5728"));
        if (!"ACTIVE".equals(voucher.getStatus())) throw new RuntimeException("\u53ea\u80fd\u64a4\u9500\u53ef\u7528\u72b6\u6001\u7684\u62b5\u7528\u5238");
        voucher.setStatus("REVOKED");
        voucherRepository.save(voucher);
        log.info("抵用券已撤销: voucherId={}, adminId={}", voucherId, adminId);
    }

    @Override
    public List<Map<String, Object>> getAllConfig() {
        return configRepository.findAll().stream().map(c -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", c.getId());
            map.put("key", c.getConfigKey());
            map.put("value", c.getConfigValue());
            map.put("description", c.getDescription());
            return map;
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void updateConfig(String key, String value, Long adminId) {
        AuctionDepositConfig config = configRepository.findByConfigKey(key)
                .orElseThrow(() -> new RuntimeException("\u914d\u7f6e\u9879\u4e0d\u5b58\u5728: " + key));
        config.setConfigValue(value);
        config.setUpdatedBy(adminId);
        config.setUpdatedAt(LocalDateTime.now());
        configRepository.save(config);
    }

    @Override
    public BigDecimal getBuyerDepositAmount() {
        return new BigDecimal(getConfigValue("BUYER_DEPOSIT_AMOUNT", "50.00"));
    }

    @Override
    public BigDecimal getSupplierDepositAmount() {
        return new BigDecimal(getConfigValue("SUPPLIER_DEPOSIT_AMOUNT", "10.00"));
    }

    @Override
    public Map<String, Object> getDepositStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalPaid", depositRepository.countByStatus("PAID"));
        stats.put("totalRefunded", depositRepository.countByStatus("REFUNDED"));
        stats.put("totalForfeited", depositRepository.countByStatus("FORFEITED"));
        stats.put("paidAmount", depositRepository.sumPaidDeposits());
        stats.put("activeVouchers", voucherRepository.countByStatus("ACTIVE"));
        stats.put("usedVouchers", voucherRepository.countByStatus("USED"));
        stats.put("buyerDepositAmount", getBuyerDepositAmount());
        stats.put("supplierDepositAmount", getSupplierDepositAmount());
        return stats;
    }

    @Override
    public List<Map<String, Object>> getDepositRecords(String status) {
        List<AuctionDeposit> deposits;
        if (status != null && !status.isEmpty()) {
            deposits = depositRepository.findByStatus(status);
        } else {
            deposits = depositRepository.findAll();
        }
        return deposits.stream().map(this::depositToMap).collect(Collectors.toList());
    }

    @Override
    @Scheduled(fixedRate = 3600000)
    @Transactional
    public void autoRefundCompletedAuctions() {
        if (!"true".equals(getConfigValue("AUTO_REFUND_ON_COMPLETE", "true"))) return;
        List<String> completedStatuses = List.of("COMPLETED", "FAILED", "CANCELLED", "VOIDED");
        List<Auction> auctions = auctionRepository.findByStatusIn(completedStatuses);
        for (Auction auction : auctions) {
            List<AuctionDeposit> paidDeposits = depositRepository.findByAuctionIdAndStatus(auction.getId(), "PAID");
            for (AuctionDeposit deposit : paidDeposits) {
                deposit.setStatus("REFUNDED");
                deposit.setRefundedAt(LocalDateTime.now());
                deposit.setRefundReason("拍卖" + auction.getStatus() + ",系统自动退还押金");
                depositRepository.save(deposit);
            }
            if (!paidDeposits.isEmpty()) {
                log.info("自动退还拍卖[{}]押金{}笔", auction.getAuctionNo(), paidDeposits.size());
            }
        }
    }

    // ========== private helpers ==========

    private Map<String, Object> depositToMap(AuctionDeposit d) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", d.getId());
        map.put("depositNo", d.getDepositNo());
        map.put("auctionId", d.getAuctionId());
        map.put("auctionNo", d.getAuctionNo());
        map.put("userId", d.getUserId());
        map.put("userType", d.getUserType());
        map.put("amount", d.getAmount());
        map.put("paymentMethod", d.getPaymentMethod());
        map.put("status", d.getStatus());
        map.put("paidAt", d.getPaidAt());
        map.put("refundedAt", d.getRefundedAt());
        map.put("refundReason", d.getRefundReason());
        return map;
    }

    private Map<String, Object> voucherToMap(DepositVoucher v) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", v.getId());
        map.put("voucherNo", v.getVoucherNo());
        map.put("userType", v.getUserType());
        map.put("voucherType", v.getVoucherType());
        map.put("faceValue", v.getFaceValue());
        map.put("currency", v.getCurrency());
        map.put("status", v.getStatus());
        map.put("source", v.getSource());
        map.put("expiresAt", v.getExpiresAt());
        return map;
    }

    private void validateVoucher(DepositVoucher voucher, Long userId, String expectedType, BigDecimal requiredAmount) {
        if (!voucher.getUserId().equals(userId)) throw new RuntimeException("抵用券不属于当前用户");
        if (!"ACTIVE".equals(voucher.getStatus())) throw new RuntimeException("抵用券不可用(" + voucher.getStatus() + ")");
        if (voucher.getExpiresAt() != null && voucher.getExpiresAt().isBefore(LocalDateTime.now())) {
            voucher.setStatus("EXPIRED");
            voucherRepository.save(voucher);
            throw new RuntimeException("抵用券已过期");
        }
        if (!expectedType.equals(voucher.getVoucherType()) && !"AUCTION_DEPOSIT".equals(voucher.getVoucherType())) {
            throw new RuntimeException("抵用券类型不匹配");
        }
        if (!"USD".equalsIgnoreCase(voucher.getCurrency())
                || voucher.getFaceValue() == null
                || voucher.getFaceValue().compareTo(requiredAmount) < 0) {
            throw new BusinessException(400, "抵用券币种或面值不足以抵扣本次押金");
        }
    }

    private void rejectDuplicateDeposit(Long auctionId, Long userId) {
        if (depositRepository.existsByAuctionIdAndUserIdAndStatusIn(auctionId, userId, List.of("PAID"))) {
            throw new BusinessException(409, "该竞价押金已缴纳，请勿重复操作");
        }
    }

    private String newDepositNo() {
        return "DEP" + UUID.randomUUID().toString().replace("-", "").substring(0, 24).toUpperCase(Locale.ROOT);
    }

    private String getConfigValue(String key, String defaultValue) {
        return configRepository.findByConfigKey(key).map(AuctionDepositConfig::getConfigValue).orElse(defaultValue);
    }
}
