package com.yicai.trade.module.review.service.impl;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.review.dto.*;
import com.yicai.trade.module.review.entity.OrderReview;
import com.yicai.trade.module.review.repository.OrderReviewRepository;
import com.yicai.trade.module.review.service.OrderReviewService;
import com.yicai.trade.module.order.entity.Order;
import com.yicai.trade.module.order.repository.OrderRepository;
import com.yicai.trade.module.score.service.SupplierCreditService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderReviewServiceImpl implements OrderReviewService {

    private final OrderReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final SupplierCreditService creditService;

    @Override
    @Transactional
    public ReviewResponse create(ReviewCreateRequest req) {
        // 验证订单状态必须为COMPLETED
        Order order = orderRepository.findById(req.getOrderId())
                .orElseThrow(() -> new RuntimeException("订单不存在: " + req.getOrderId()));
        if (!"COMPLETED".equals(order.getStatus())) {
            throw new RuntimeException("只能对已完成的订单进行评价，当前状态: " + order.getStatus());
        }

        if (reviewRepository.existsByOrderIdAndBuyerId(req.getOrderId(), req.getBuyerId())) {
            throw new RuntimeException("该订单已评价");
        }

        OrderReview review = OrderReview.builder()
                .orderId(req.getOrderId())
                .orderNo(req.getOrderNo())
                .buyerId(req.getBuyerId())
                .buyerName(req.getBuyerName())
                .supplierId(req.getSupplierId())
                .overallRating(req.getOverallRating())
                .qualityRating(req.getQualityRating())
                .deliveryRating(req.getDeliveryRating())
                .serviceRating(req.getServiceRating())
                .priceRating(req.getPriceRating())
                .content(req.getContent())
                .imageUrls(req.getImageUrls())
                .isAnonymous(req.getIsAnonymous() != null ? req.getIsAnonymous() : false)
                .status("PUBLISHED")
                .build();
        review = reviewRepository.save(review);

        // Update supplier credit score
        try {
            creditService.onBuyerReview(req.getSupplierId(), review.getId(), req.getOverallRating());
        } catch (Exception ignored) {
            // Credit service failure should not block review creation
        }

        return toResponse(review);
    }

    @Override
    public ReviewResponse getByOrderId(Long orderId) {
        return reviewRepository.findByOrderId(orderId).map(this::toResponse)
                .orElseThrow(() -> new RuntimeException("该订单暂无评价"));
    }

    @Override
    public PageResult<ReviewResponse> listBySupplierId(Long supplierId, String status, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<OrderReview> p;
        if (status != null && !status.isEmpty()) {
            p = reviewRepository.findBySupplierIdAndStatus(supplierId, status, pageable);
        } else {
            p = reviewRepository.findBySupplierId(supplierId, pageable);
        }
        List<ReviewResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<ReviewResponse> listByBuyerId(Long buyerId, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<OrderReview> p = reviewRepository.findByBuyerId(buyerId, pageable);
        List<ReviewResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    public PageResult<ReviewResponse> listAll(String status, int page, int size) {
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<OrderReview> p;
        if (status != null && !status.isEmpty()) {
            p = reviewRepository.findByStatus(status, pageable);
        } else {
            p = reviewRepository.findAll(pageable);
        }
        List<ReviewResponse> list = p.getContent().stream().map(this::toResponse).collect(Collectors.toList());
        return PageResult.of(list, p.getTotalElements(), page, size);
    }

    @Override
    @Transactional
    public void supplierReply(Long reviewId, Long supplierId, String reply) {
        OrderReview review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("评价不存在"));
        if (!review.getSupplierId().equals(supplierId)) {
            throw new RuntimeException("无权回复此评价");
        }
        review.setSupplierReply(reply);
        review.setRepliedAt(LocalDateTime.now());
        reviewRepository.save(review);
    }

    @Override
    @Transactional
    public void hide(Long reviewId) {
        OrderReview review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("评价不存在"));
        review.setStatus("HIDDEN");
        reviewRepository.save(review);
    }

    @Override
    @Transactional
    public void appeal(Long reviewId, Long buyerId, String reason) {
        OrderReview review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("评价不存在"));
        review.setStatus("APPEALED");
        reviewRepository.save(review);
    }

    @Override
    public ReviewSummaryResponse getSummary(Long supplierId) {
        ReviewSummaryResponse summary = new ReviewSummaryResponse();
        summary.setSupplierId(supplierId);
        summary.setTotalReviews(reviewRepository.countBySupplierIdAndStatus(supplierId, "PUBLISHED"));
        summary.setAvgOverallRating(reviewRepository.avgOverallRating(supplierId));
        summary.setAvgQualityRating(reviewRepository.avgQualityRating(supplierId));
        summary.setAvgDeliveryRating(reviewRepository.avgDeliveryRating(supplierId));
        return summary;
    }

    private ReviewResponse toResponse(OrderReview r) {
        ReviewResponse resp = new ReviewResponse();
        resp.setId(r.getId());
        resp.setOrderId(r.getOrderId());
        resp.setOrderNo(r.getOrderNo());
        resp.setBuyerId(r.getBuyerId());
        resp.setBuyerName(r.getIsAnonymous() ? "匿名买家" : r.getBuyerName());
        resp.setSupplierId(r.getSupplierId());
        resp.setOverallRating(r.getOverallRating());
        resp.setQualityRating(r.getQualityRating());
        resp.setDeliveryRating(r.getDeliveryRating());
        resp.setServiceRating(r.getServiceRating());
        resp.setPriceRating(r.getPriceRating());
        resp.setContent(r.getContent());
        resp.setImageUrls(r.getImageUrls());
        resp.setIsAnonymous(r.getIsAnonymous());
        resp.setSupplierReply(r.getSupplierReply());
        resp.setRepliedAt(r.getRepliedAt());
        resp.setStatus(r.getStatus());
        resp.setCreatedAt(r.getCreatedAt());
        return resp;
    }
}
