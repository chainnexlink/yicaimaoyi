package com.yicai.trade.module.shop.repository;

import com.yicai.trade.module.shop.entity.Shop;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ShopRepository extends JpaRepository<Shop, Long> {
    Optional<Shop> findBySupplierId(Long supplierId);
    Page<Shop> findByStatus(String status, Pageable pageable);
    Page<Shop> findByIndustry(String industry, Pageable pageable);
    Page<Shop> findByShopNameContaining(String keyword, Pageable pageable);
    long countByStatus(String status);
}
