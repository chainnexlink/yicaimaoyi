package com.yicai.trade.module.order.repository;

import com.yicai.trade.module.order.entity.OrderEscrow;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderEscrowRepository extends JpaRepository<OrderEscrow, Long> {

    Optional<OrderEscrow> findByOrderId(Long orderId);

    Optional<OrderEscrow> findByEscrowNo(String escrowNo);

    List<OrderEscrow> findByStatus(String status);

    Page<OrderEscrow> findByStatus(String status, Pageable pageable);

    Page<OrderEscrow> findByBuyerId(Long buyerId, Pageable pageable);

    Page<OrderEscrow> findBySupplierId(Long supplierId, Pageable pageable);

    /** 查找已到自动释放时间但尚未释放的托管记录 */
    List<OrderEscrow> findByStatusAndAutoReleaseAtBefore(String status, LocalDateTime dateTime);
}
