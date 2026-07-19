package com.yicai.trade.module.monitor.repository;

import com.yicai.trade.module.monitor.entity.MonitorAlert;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MonitorAlertRepository extends JpaRepository<MonitorAlert, Long> {
    Page<MonitorAlert> findByBuyerIdAndStatusOrderByCreatedAtDesc(Long buyerId, String status, Pageable pageable);
    Page<MonitorAlert> findBySupplierIdAndStatusOrderByCreatedAtDesc(Long supplierId, String status, Pageable pageable);
    Page<MonitorAlert> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);
    
    List<MonitorAlert> findByOrderIdAndStatusOrderByCreatedAtDesc(Long orderId, String status);
    List<MonitorAlert> findByBuyerIdAndStatusInOrderByCreatedAtDesc(Long buyerId, List<String> statuses);
    
    long countByBuyerIdAndStatus(Long buyerId, String status);
    long countBySupplierIdAndStatus(Long supplierId, String status);
    long countByStatus(String status);
}
