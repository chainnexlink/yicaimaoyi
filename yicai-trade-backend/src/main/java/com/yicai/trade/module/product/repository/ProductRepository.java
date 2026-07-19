package com.yicai.trade.module.product.repository;

import com.yicai.trade.module.product.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
    Page<Product> findByAuditStatus(String auditStatus, Pageable pageable);
    Page<Product> findByCategory(String category, Pageable pageable);
    Page<Product> findByAuditStatusAndCategory(String auditStatus, String category, Pageable pageable);
    Page<Product> findByNameContaining(String name, Pageable pageable);
    long countByAuditStatus(String auditStatus);
}
