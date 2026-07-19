package com.yicai.trade.module.aftersale.repository;

import com.yicai.trade.module.aftersale.entity.Aftersale;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AftersaleRepository extends JpaRepository<Aftersale, Long> {
    Optional<Aftersale> findByAftersaleNo(String aftersaleNo);
    Page<Aftersale> findByStatus(String status, Pageable pageable);
    Page<Aftersale> findByBuyerId(Long buyerId, Pageable pageable);
    Page<Aftersale> findBySupplierId(Long supplierId, Pageable pageable);
    Page<Aftersale> findByOrderId(Long orderId, Pageable pageable);
    Page<Aftersale> findByType(String type, Pageable pageable);
    long countByStatus(String status);
    long countBySupplierId(Long supplierId);
    long countBySupplierIdAndStatus(Long supplierId, String status);
}
