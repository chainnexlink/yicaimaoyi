package com.yicai.trade.module.payment.repository;

import com.yicai.trade.module.payment.entity.Payment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    
    Optional<Payment> findByPaymentNo(String paymentNo);
    
    List<Payment> findByOrderId(Long orderId);
    
    Page<Payment> findByPayerId(Long payerId, Pageable pageable);
    
    Page<Payment> findByPayeeId(Long payeeId, Pageable pageable);
    
    Page<Payment> findByStatus(String status, Pageable pageable);
    
    Optional<Payment> findByOrderIdAndStatus(Long orderId, String status);
    
    boolean existsByPaymentNo(String paymentNo);

    long countByStatus(String status);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.status = :status")
    BigDecimal sumAmountByStatus(@Param("status") String status);

    /** 查询已过期但状态仍为 PENDING 的支付记录（用于定时任务） */
    List<Payment> findByStatusAndExpiredAtBefore(String status, LocalDateTime time);
}
