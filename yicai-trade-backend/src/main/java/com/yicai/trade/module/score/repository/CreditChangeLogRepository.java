package com.yicai.trade.module.score.repository;

import com.yicai.trade.module.score.entity.CreditChangeLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CreditChangeLogRepository extends JpaRepository<CreditChangeLog, Long> {
    Page<CreditChangeLog> findBySupplierIdOrderByCreatedAtDesc(Long supplierId, Pageable pageable);
    Page<CreditChangeLog> findBySupplierIdAndDimensionOrderByCreatedAtDesc(Long supplierId, String dimension, Pageable pageable);
}
