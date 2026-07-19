package com.yicai.trade.module.content.repository;

import com.yicai.trade.module.content.entity.Banner;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BannerRepository extends JpaRepository<Banner, Long> {
    Page<Banner> findByPositionOrderBySortOrderAsc(String position, Pageable pageable);
    List<Banner> findByPositionAndStatusOrderBySortOrderAsc(String position, String status);
    long countByStatus(String status);
    long countByPosition(String position);
}
