package com.yicai.trade.module.score.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.score.dto.CreditChangeLogResponse;
import com.yicai.trade.module.score.dto.SupplierCreditResponse;

import java.math.BigDecimal;

public interface SupplierCreditService {
    SupplierCreditResponse getOrCreate(Long supplierId);
    SupplierCreditResponse getBySupplierId(Long supplierId);
    PageResult<SupplierCreditResponse> ranking(int page, int size);
    PageResult<CreditChangeLogResponse> getChangeLog(Long supplierId, String dimension, int page, int size);

    // Event handlers - called by other modules
    void onOrderCompleted(Long supplierId, Long orderId, boolean onTime);
    void onQualityCheck(Long supplierId, Long orderId, boolean passed);
    void onDisputeResolved(Long supplierId, Long disputeId, boolean lost);
    void onAftersaleCreated(Long supplierId, Long aftersaleId);
    void onBuyerReview(Long supplierId, Long reviewId, int rating);
    void manualAdjust(Long supplierId, String dimension, BigDecimal adjustment, String reason);
    void recalculate(Long supplierId);
}
