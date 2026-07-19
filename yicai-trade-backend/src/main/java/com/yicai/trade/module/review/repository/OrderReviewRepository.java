package com.yicai.trade.module.review.repository;

import com.yicai.trade.module.review.entity.OrderReview;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface OrderReviewRepository extends JpaRepository<OrderReview, Long> {
    Optional<OrderReview> findByOrderId(Long orderId);
    Page<OrderReview> findBySupplierId(Long supplierId, Pageable pageable);
    Page<OrderReview> findBySupplierIdAndStatus(Long supplierId, String status, Pageable pageable);
    Page<OrderReview> findByBuyerId(Long buyerId, Pageable pageable);
    Page<OrderReview> findByStatus(String status, Pageable pageable);
    boolean existsByOrderIdAndBuyerId(Long orderId, Long buyerId);
    long countBySupplierId(Long supplierId);
    long countBySupplierIdAndStatus(Long supplierId, String status);

    @Query("SELECT COALESCE(AVG(r.overallRating), 0) FROM OrderReview r WHERE r.supplierId = :supplierId AND r.status = 'PUBLISHED'")
    double avgOverallRating(Long supplierId);

    @Query("SELECT COALESCE(AVG(r.qualityRating), 0) FROM OrderReview r WHERE r.supplierId = :supplierId AND r.status = 'PUBLISHED'")
    double avgQualityRating(Long supplierId);

    @Query("SELECT COALESCE(AVG(r.deliveryRating), 0) FROM OrderReview r WHERE r.supplierId = :supplierId AND r.status = 'PUBLISHED'")
    double avgDeliveryRating(Long supplierId);
}
