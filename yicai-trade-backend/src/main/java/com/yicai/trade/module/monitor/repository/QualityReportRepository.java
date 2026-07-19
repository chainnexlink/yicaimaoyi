package com.yicai.trade.module.monitor.repository;

import com.yicai.trade.module.monitor.entity.QualityReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface QualityReportRepository extends JpaRepository<QualityReport, Long> {
    Optional<QualityReport> findByReportNo(String reportNo);
    Page<QualityReport> findByOrderIdOrderByCreatedAtDesc(Long orderId, Pageable pageable);
    Page<QualityReport> findBySupplierIdOrderByCreatedAtDesc(Long supplierId, Pageable pageable);
    Page<QualityReport> findByBuyerIdOrderByCreatedAtDesc(Long buyerId, Pageable pageable);
    List<QualityReport> findByOrderIdOrderByCreatedAtDesc(Long orderId);
    long countByOrderId(Long orderId);
    long countBySupplierIdAndConclusion(Long supplierId, String conclusion);
}
