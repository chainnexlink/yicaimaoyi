package com.yicai.trade.module.payment.repository;

import com.yicai.trade.module.payment.entity.Refund;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefundRepository extends JpaRepository<Refund, Long> {
    
    Optional<Refund> findByRefundNo(String refundNo);
    
    List<Refund> findByOrderId(Long orderId);
    
    List<Refund> findByPaymentId(Long paymentId);
    
    Page<Refund> findByApplicantId(Long applicantId, Pageable pageable);
    
    Page<Refund> findByStatus(String status, Pageable pageable);
    
    boolean existsByRefundNo(String refundNo);

    long countByStatus(String status);

    @Query("SELECT COALESCE(SUM(r.refundAmount), 0) FROM Refund r WHERE r.status = :status")
    BigDecimal sumRefundAmountByStatus(@Param("status") String status);
}
