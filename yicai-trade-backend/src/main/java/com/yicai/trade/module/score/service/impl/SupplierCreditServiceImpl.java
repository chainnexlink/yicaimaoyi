package com.yicai.trade.module.score.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.score.dto.CreditChangeLogResponse;
import com.yicai.trade.module.score.dto.SupplierCreditResponse;
import com.yicai.trade.module.score.entity.CreditChangeLog;
import com.yicai.trade.module.score.entity.SupplierCredit;
import com.yicai.trade.module.score.repository.CreditChangeLogRepository;
import com.yicai.trade.module.score.repository.SupplierCreditRepository;
import com.yicai.trade.module.score.service.SupplierCreditService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SupplierCreditServiceImpl implements SupplierCreditService {

    private final SupplierCreditRepository creditRepository;
    private final CreditChangeLogRepository changeLogRepository;

    @Override
    @Transactional
    public SupplierCreditResponse getOrCreate(Long supplierId) {
        SupplierCredit credit = creditRepository.findBySupplierId(supplierId)
                .orElseGet(() -> {
                    SupplierCredit newCredit = SupplierCredit.builder()
                            .supplierId(supplierId)
                            .build();
                    return creditRepository.save(newCredit);
                });
        return toResponse(credit);
    }

    @Override
    public SupplierCreditResponse getBySupplierId(Long supplierId) {
        return creditRepository.findBySupplierId(supplierId)
                .map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("供应商信用记录不存在: " + supplierId));
    }

    @Override
    public PageResult<SupplierCreditResponse> ranking(int page, int size) {
        var pageable = PageRequest.of(page, size);
        Page<SupplierCredit> p = creditRepository.findAllByOrderByCreditScoreDesc(pageable);
        List<SupplierCreditResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<CreditChangeLogResponse> getChangeLog(Long supplierId, String dimension, int page, int size) {
        var pageable = PageRequest.of(page, size);
        Page<CreditChangeLog> p;
        if (dimension != null && !dimension.isEmpty()) {
            p = changeLogRepository.findBySupplierIdAndDimensionOrderByCreatedAtDesc(supplierId, dimension, pageable);
        } else {
            p = changeLogRepository.findBySupplierIdOrderByCreatedAtDesc(supplierId, pageable);
        }
        List<CreditChangeLogResponse> list = p.getContent().stream().map(this::toLogResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void onOrderCompleted(Long supplierId, Long orderId, boolean onTime) {
        SupplierCredit credit = ensureCredit(supplierId);
        credit.setTotalOrders(credit.getTotalOrders() + 1);
        credit.setCompletedOrders(credit.getCompletedOrders() + 1);
        if (onTime) {
            credit.setOnTimeDeliveries(credit.getOnTimeDeliveries() + 1);
        } else {
            credit.setLateDeliveries(credit.getLateDeliveries() + 1);
        }
        updateDeliveryScore(credit);
        creditRepository.save(credit);
        logChange(supplierId, onTime ? "ORDER_COMPLETE" : "LATE_DELIVERY", "DELIVERY",
                credit.getDeliveryScore(), orderId, "ORDER",
                onTime ? "订单按时完成" : "订单延迟交付");
    }

    @Override
    @Transactional
    public void onQualityCheck(Long supplierId, Long orderId, boolean passed) {
        SupplierCredit credit = ensureCredit(supplierId);
        if (passed) {
            credit.setQualityPassCount(credit.getQualityPassCount() + 1);
        } else {
            credit.setQualityFailCount(credit.getQualityFailCount() + 1);
        }
        updateQualityScore(credit);
        creditRepository.save(credit);
        logChange(supplierId, passed ? "QUALITY_PASS" : "QUALITY_FAIL", "QUALITY",
                credit.getQualityScore(), orderId, "ORDER",
                passed ? "质量检查通过" : "质量检查不合格");
    }

    @Override
    @Transactional
    public void onDisputeResolved(Long supplierId, Long disputeId, boolean lost) {
        SupplierCredit credit = ensureCredit(supplierId);
        credit.setTotalDisputes(credit.getTotalDisputes() + 1);
        if (lost) {
            credit.setLostDisputes(credit.getLostDisputes() + 1);
        }
        updateDisputeScore(credit);
        creditRepository.save(credit);
        logChange(supplierId, lost ? "DISPUTE_LOSE" : "DISPUTE_WIN", "DISPUTE",
                credit.getDisputeScore(), disputeId, "DISPUTE",
                lost ? "纠纷败诉" : "纠纷胜诉");
    }

    @Override
    @Transactional
    public void onAftersaleCreated(Long supplierId, Long aftersaleId) {
        SupplierCredit credit = ensureCredit(supplierId);
        credit.setTotalAftersales(credit.getTotalAftersales() + 1);
        updateServiceScore(credit);
        creditRepository.save(credit);
        logChange(supplierId, "AFTERSALE", "SERVICE",
                credit.getServiceScore(), aftersaleId, "AFTERSALE", "新增售后申请");
    }

    @Override
    @Transactional
    public void onBuyerReview(Long supplierId, Long reviewId, int rating) {
        SupplierCredit credit = ensureCredit(supplierId);
        int newTotal = credit.getTotalReviews() + 1;
        BigDecimal currentSum = credit.getAvgBuyerRating().multiply(new BigDecimal(credit.getTotalReviews()));
        BigDecimal newAvg = currentSum.add(new BigDecimal(rating))
                .divide(new BigDecimal(newTotal), 2, RoundingMode.HALF_UP);
        credit.setTotalReviews(newTotal);
        credit.setAvgBuyerRating(newAvg);
        updateServiceScore(credit);
        creditRepository.save(credit);
        logChange(supplierId, "BUYER_REVIEW", "SERVICE",
                credit.getServiceScore(), reviewId, "REVIEW", "买家评价: " + rating + "星");
    }

    @Override
    @Transactional
    public void manualAdjust(Long supplierId, String dimension, BigDecimal adjustment, String reason) {
        SupplierCredit credit = ensureCredit(supplierId);
        BigDecimal oldScore;
        BigDecimal newScore;
        switch (dimension) {
            case "DELIVERY":
                oldScore = credit.getDeliveryScore();
                newScore = clampScore(oldScore.add(adjustment));
                credit.setDeliveryScore(newScore);
                break;
            case "QUALITY":
                oldScore = credit.getQualityScore();
                newScore = clampScore(oldScore.add(adjustment));
                credit.setQualityScore(newScore);
                break;
            case "SERVICE":
                oldScore = credit.getServiceScore();
                newScore = clampScore(oldScore.add(adjustment));
                credit.setServiceScore(newScore);
                break;
            case "DISPUTE":
                oldScore = credit.getDisputeScore();
                newScore = clampScore(oldScore.add(adjustment));
                credit.setDisputeScore(newScore);
                break;
            default:
                throw new RuntimeException("未知维度: " + dimension);
        }
        recalculateOverall(credit);
        creditRepository.save(credit);
        logChange(supplierId, "MANUAL_ADJUST", dimension, newScore, null, null, reason);
    }

    @Override
    @Transactional
    public void recalculate(Long supplierId) {
        SupplierCredit credit = ensureCredit(supplierId);
        updateDeliveryScore(credit);
        updateQualityScore(credit);
        updateServiceScore(credit);
        updateDisputeScore(credit);
        recalculateOverall(credit);
        credit.setLastCalculatedAt(LocalDateTime.now());
        creditRepository.save(credit);
    }

    // === Internal calculation methods ===

    private void updateDeliveryScore(SupplierCredit c) {
        int total = c.getOnTimeDeliveries() + c.getLateDeliveries();
        if (total == 0) return;
        BigDecimal rate = new BigDecimal(c.getOnTimeDeliveries())
                .divide(new BigDecimal(total), 4, RoundingMode.HALF_UP);
        c.setDeliveryScore(rate.multiply(new BigDecimal("100")).setScale(2, RoundingMode.HALF_UP));
        recalculateOverall(c);
    }

    private void updateQualityScore(SupplierCredit c) {
        int total = c.getQualityPassCount() + c.getQualityFailCount();
        if (total == 0) return;
        BigDecimal rate = new BigDecimal(c.getQualityPassCount())
                .divide(new BigDecimal(total), 4, RoundingMode.HALF_UP);
        c.setQualityScore(rate.multiply(new BigDecimal("100")).setScale(2, RoundingMode.HALF_UP));
        recalculateOverall(c);
    }

    private void updateDisputeScore(SupplierCredit c) {
        if (c.getTotalDisputes() == 0) return;
        BigDecimal loseRate = new BigDecimal(c.getLostDisputes())
                .divide(new BigDecimal(c.getTotalDisputes()), 4, RoundingMode.HALF_UP);
        BigDecimal score = new BigDecimal("100").subtract(
                loseRate.multiply(new BigDecimal("100"))
        ).setScale(2, RoundingMode.HALF_UP);
        c.setDisputeScore(clampScore(score));
        recalculateOverall(c);
    }

    private void updateServiceScore(SupplierCredit c) {
        // Service score = weighted average of buyer rating + aftersale rate penalty
        BigDecimal ratingScore = c.getAvgBuyerRating().multiply(new BigDecimal("20")); // 5 star -> 100
        int completedOrders = Math.max(c.getCompletedOrders(), 1);
        BigDecimal aftersaleRate = new BigDecimal(c.getTotalAftersales())
                .divide(new BigDecimal(completedOrders), 4, RoundingMode.HALF_UP);
        BigDecimal penalty = aftersaleRate.multiply(new BigDecimal("50")); // max 50 point penalty
        c.setServiceScore(clampScore(ratingScore.subtract(penalty)));
        recalculateOverall(c);
    }

    private void recalculateOverall(SupplierCredit c) {
        // Weighted: delivery 30%, quality 30%, service 20%, dispute 20%
        BigDecimal overall = c.getDeliveryScore().multiply(new BigDecimal("0.30"))
                .add(c.getQualityScore().multiply(new BigDecimal("0.30")))
                .add(c.getServiceScore().multiply(new BigDecimal("0.20")))
                .add(c.getDisputeScore().multiply(new BigDecimal("0.20")))
                .setScale(2, RoundingMode.HALF_UP);
        c.setCreditScore(overall);
        c.setCreditLevel(determineCreditLevel(overall));
    }

    private String determineCreditLevel(BigDecimal score) {
        if (score.compareTo(new BigDecimal("95")) >= 0) return "AAA";
        if (score.compareTo(new BigDecimal("85")) >= 0) return "AA";
        if (score.compareTo(new BigDecimal("75")) >= 0) return "A";
        if (score.compareTo(new BigDecimal("60")) >= 0) return "B";
        if (score.compareTo(new BigDecimal("40")) >= 0) return "C";
        return "D";
    }

    private BigDecimal clampScore(BigDecimal score) {
        if (score.compareTo(BigDecimal.ZERO) < 0) return BigDecimal.ZERO;
        if (score.compareTo(new BigDecimal("100")) > 0) return new BigDecimal("100.00");
        return score.setScale(2, RoundingMode.HALF_UP);
    }

    private SupplierCredit ensureCredit(Long supplierId) {
        return creditRepository.findBySupplierId(supplierId)
                .orElseGet(() -> {
                    SupplierCredit c = SupplierCredit.builder().supplierId(supplierId).build();
                    return creditRepository.save(c);
                });
    }

    private void logChange(Long supplierId, String changeType, String dimension,
                           BigDecimal newScore, Long relatedId, String relatedType, String reason) {
        CreditChangeLog log = CreditChangeLog.builder()
                .supplierId(supplierId)
                .changeType(changeType)
                .dimension(dimension)
                .newScore(newScore)
                .relatedId(relatedId)
                .relatedType(relatedType)
                .reason(reason)
                .build();
        changeLogRepository.save(log);
    }

    private SupplierCreditResponse toResponse(SupplierCredit c) {
        SupplierCreditResponse r = new SupplierCreditResponse();
        r.setId(c.getId());
        r.setSupplierId(c.getSupplierId());
        r.setCreditScore(c.getCreditScore());
        r.setCreditLevel(c.getCreditLevel());
        r.setDeliveryScore(c.getDeliveryScore());
        r.setQualityScore(c.getQualityScore());
        r.setServiceScore(c.getServiceScore());
        r.setDisputeScore(c.getDisputeScore());
        r.setTotalOrders(c.getTotalOrders());
        r.setCompletedOrders(c.getCompletedOrders());
        r.setOnTimeDeliveries(c.getOnTimeDeliveries());
        r.setLateDeliveries(c.getLateDeliveries());
        r.setQualityPassCount(c.getQualityPassCount());
        r.setQualityFailCount(c.getQualityFailCount());
        r.setTotalDisputes(c.getTotalDisputes());
        r.setLostDisputes(c.getLostDisputes());
        r.setTotalAftersales(c.getTotalAftersales());
        r.setAvgResponseHours(c.getAvgResponseHours());
        r.setAvgBuyerRating(c.getAvgBuyerRating());
        r.setTotalReviews(c.getTotalReviews());
        r.setLastCalculatedAt(c.getLastCalculatedAt());

        // Compute rates
        int deliveryTotal = c.getOnTimeDeliveries() + c.getLateDeliveries();
        r.setOnTimeRate(deliveryTotal > 0
                ? new BigDecimal(c.getOnTimeDeliveries() * 100).divide(new BigDecimal(deliveryTotal), 1, RoundingMode.HALF_UP) + "%"
                : "N/A");
        int qualityTotal = c.getQualityPassCount() + c.getQualityFailCount();
        r.setQualityRate(qualityTotal > 0
                ? new BigDecimal(c.getQualityPassCount() * 100).divide(new BigDecimal(qualityTotal), 1, RoundingMode.HALF_UP) + "%"
                : "N/A");
        r.setDisputeLoseRate(c.getTotalDisputes() > 0
                ? new BigDecimal(c.getLostDisputes() * 100).divide(new BigDecimal(c.getTotalDisputes()), 1, RoundingMode.HALF_UP) + "%"
                : "N/A");
        return r;
    }

    private CreditChangeLogResponse toLogResponse(CreditChangeLog log) {
        CreditChangeLogResponse r = new CreditChangeLogResponse();
        r.setId(log.getId());
        r.setSupplierId(log.getSupplierId());
        r.setChangeType(log.getChangeType());
        r.setDimension(log.getDimension());
        r.setOldScore(log.getOldScore());
        r.setNewScore(log.getNewScore());
        r.setChangeAmount(log.getChangeAmount());
        r.setRelatedId(log.getRelatedId());
        r.setRelatedType(log.getRelatedType());
        r.setReason(log.getReason());
        r.setCreatedAt(log.getCreatedAt());
        return r;
    }
}
