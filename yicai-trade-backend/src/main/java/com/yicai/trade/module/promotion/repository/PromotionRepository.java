package com.yicai.trade.module.promotion.repository;

import com.yicai.trade.module.promotion.entity.Promotion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PromotionRepository extends JpaRepository<Promotion, Long> {
    Page<Promotion> findBySupplierId(Long supplierId, Pageable pageable);
    Page<Promotion> findByStatus(String status, Pageable pageable);
    Page<Promotion> findByPromoType(String promoType, Pageable pageable);
    Page<Promotion> findBySupplierIdAndStatus(Long supplierId, String status, Pageable pageable);
    long countByStatus(String status);
    long countBySupplierId(Long supplierId);
}
