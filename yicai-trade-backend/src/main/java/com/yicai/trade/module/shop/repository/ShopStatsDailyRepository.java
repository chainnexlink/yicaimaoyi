package com.yicai.trade.module.shop.repository;

import com.yicai.trade.module.shop.entity.ShopStatsDaily;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDate;
import java.util.List;

public interface ShopStatsDailyRepository extends JpaRepository<ShopStatsDaily, Long> {
    List<ShopStatsDaily> findByShopIdAndStatDateBetweenOrderByStatDateAsc(Long shopId, LocalDate start, LocalDate end);

    @Query("SELECT COALESCE(SUM(s.pageViews), 0) FROM ShopStatsDaily s WHERE s.shopId = :shopId AND s.statDate BETWEEN :start AND :end")
    long sumPageViews(Long shopId, LocalDate start, LocalDate end);

    @Query("SELECT COALESCE(SUM(s.orderCount), 0) FROM ShopStatsDaily s WHERE s.shopId = :shopId AND s.statDate BETWEEN :start AND :end")
    long sumOrderCount(Long shopId, LocalDate start, LocalDate end);

    @Query("SELECT COALESCE(SUM(s.orderAmount), 0) FROM ShopStatsDaily s WHERE s.shopId = :shopId AND s.statDate BETWEEN :start AND :end")
    java.math.BigDecimal sumOrderAmount(Long shopId, LocalDate start, LocalDate end);
}
