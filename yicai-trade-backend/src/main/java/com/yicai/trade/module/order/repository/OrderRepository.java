package com.yicai.trade.module.order.repository;

import com.yicai.trade.module.order.entity.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    Page<Order> findByBuyerId(Long buyerId, Pageable pageable);
    Page<Order> findBySupplierId(Long supplierId, Pageable pageable);
    long countByStatus(String status);

    // 定时任务: 未支付自动取消
    List<Order> findByStatusAndCreatedAtBefore(String status, LocalDateTime before);

    // 定时任务: 买家未确认收货自动完成
    List<Order> findByStatusAndUpdatedAtBefore(String status, LocalDateTime before);
}
