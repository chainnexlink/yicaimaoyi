package com.yicai.trade.module.logistics.repository;

import com.yicai.trade.module.logistics.entity.Logistics;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LogisticsRepository extends JpaRepository<Logistics, Long> {
    Optional<Logistics> findByTrackingNo(String trackingNo);
    Optional<Logistics> findByOrderId(Long orderId);
    Page<Logistics> findByStatus(String status, Pageable pageable);
    long countByStatus(String status);
}
