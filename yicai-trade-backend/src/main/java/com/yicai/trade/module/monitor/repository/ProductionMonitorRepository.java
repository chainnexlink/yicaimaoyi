package com.yicai.trade.module.monitor.repository;

import com.yicai.trade.module.monitor.entity.ProductionMonitor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ProductionMonitorRepository extends JpaRepository<ProductionMonitor, Long> {
    Page<ProductionMonitor> findByOrderIdOrderByCreatedAtDesc(Long orderId, Pageable pageable);
    Page<ProductionMonitor> findBySupplierIdOrderByCreatedAtDesc(Long supplierId, Pageable pageable);
    Page<ProductionMonitor> findByBuyerIdOrderByCreatedAtDesc(Long buyerId, Pageable pageable);
    
    List<ProductionMonitor> findByOrderIdOrderByCreatedAtDesc(Long orderId);
    List<ProductionMonitor> findByMonitorSettingIdOrderByCreatedAtDesc(Long settingId);
    
    // 供应商的待审核监控
    Page<ProductionMonitor> findByReviewStatusOrderByCreatedAtDesc(String reviewStatus, Pageable pageable);
    
    // 采购商未查看的监控
    List<ProductionMonitor> findByBuyerIdAndBuyerViewedFalseOrderByCreatedAtDesc(Long buyerId);
    
    // 统计
    long countBySupplierIdAndCreatedAtAfter(Long supplierId, LocalDateTime after);
    long countByOrderId(Long orderId);
    
    @Query("SELECT COUNT(m) FROM ProductionMonitor m WHERE m.supplierId = :supplierId AND m.isOverdue = true")
    long countOverdueBySupplier(@Param("supplierId") Long supplierId);
    
    // 最新一条监控记录
    ProductionMonitor findTopByOrderIdOrderByCreatedAtDesc(Long orderId);
}
