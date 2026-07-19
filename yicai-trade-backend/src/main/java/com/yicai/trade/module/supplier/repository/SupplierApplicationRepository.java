package com.yicai.trade.module.supplier.repository;

import com.yicai.trade.module.supplier.entity.SupplierApplication;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SupplierApplicationRepository extends JpaRepository<SupplierApplication, Long> {
    Page<SupplierApplication> findByStatus(String status, Pageable pageable);
    boolean existsByUserIdAndStatus(Long userId, String status);
}
