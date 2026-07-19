package com.yicai.trade.module.payment.repository;

import com.yicai.trade.module.payment.entity.PaymentOperationLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaymentOperationLogRepository extends JpaRepository<PaymentOperationLog, Long> {

    List<PaymentOperationLog> findByPaymentIdOrderByCreatedAtDesc(Long paymentId);

    List<PaymentOperationLog> findByRefundIdOrderByCreatedAtDesc(Long refundId);

    Page<PaymentOperationLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<PaymentOperationLog> findByOperationTypeOrderByCreatedAtDesc(String operationType, Pageable pageable);
}
