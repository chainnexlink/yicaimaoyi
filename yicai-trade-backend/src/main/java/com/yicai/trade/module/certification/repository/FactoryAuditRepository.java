package com.yicai.trade.module.certification.repository;

import com.yicai.trade.module.certification.entity.FactoryAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FactoryAuditRepository extends JpaRepository<FactoryAudit, Long> {
    Page<FactoryAudit> findByStatus(String status, Pageable pageable);
    Page<FactoryAudit> findBySupplierId(Long supplierId, Pageable pageable);
    List<FactoryAudit> findBySupplierIdOrderByAuditDateDesc(Long supplierId);
    long countByStatus(String status);
    long countBySupplierId(Long supplierId);
}
