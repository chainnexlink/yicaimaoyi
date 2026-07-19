package com.yicai.trade.module.demand.repository;

import com.yicai.trade.module.demand.entity.Demand;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DemandRepository extends JpaRepository<Demand, Long> {
    Optional<Demand> findByDemandNo(String demandNo);
    Page<Demand> findByBuyerId(Long buyerId, Pageable pageable);
    Page<Demand> findByStatus(String status, Pageable pageable);
    Page<Demand> findByAuditStatus(String auditStatus, Pageable pageable);
    Page<Demand> findByCategoryCode(String categoryCode, Pageable pageable);
    long countByStatus(String status);
    long countByAuditStatus(String auditStatus);
}
