package com.yicai.trade.module.review.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.review.dto.ReviewCreateRequest;
import com.yicai.trade.module.review.dto.ReviewResponse;
import com.yicai.trade.module.review.dto.ReviewSummaryResponse;

public interface OrderReviewService {
    ReviewResponse create(ReviewCreateRequest request);
    ReviewResponse getByOrderId(Long orderId);
    PageResult<ReviewResponse> listBySupplierId(Long supplierId, String status, int page, int size);
    PageResult<ReviewResponse> listByBuyerId(Long buyerId, int page, int size);
    PageResult<ReviewResponse> listAll(String status, int page, int size);
    void supplierReply(Long reviewId, Long supplierId, String reply);
    void hide(Long reviewId);
    void appeal(Long reviewId, Long buyerId, String reason);
    ReviewSummaryResponse getSummary(Long supplierId);
}
