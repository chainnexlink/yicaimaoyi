package com.yicai.trade.module.monitor.repository;

import com.yicai.trade.module.monitor.entity.MonitorSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MonitorSettingRepository extends JpaRepository<MonitorSetting, Long> {
    Optional<MonitorSetting> findByOrderId(Long orderId);
    List<MonitorSetting> findByBuyerIdAndIsActiveTrue(Long buyerId);
    List<MonitorSetting> findBySupplierIdAndIsActiveTrue(Long supplierId);
    List<MonitorSetting> findByIsActiveTrue();
    long countBySupplierIdAndIsActiveTrue(Long supplierId);
}
