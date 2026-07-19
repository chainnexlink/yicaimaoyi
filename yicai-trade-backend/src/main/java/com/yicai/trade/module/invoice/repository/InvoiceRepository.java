package com.yicai.trade.module.invoice.repository;

import com.yicai.trade.module.invoice.entity.Invoice;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
    Optional<Invoice> findByInvoiceNo(String invoiceNo);
    Page<Invoice> findByStatus(String status, Pageable pageable);
    Page<Invoice> findByBuyerId(Long buyerId, Pageable pageable);
    Page<Invoice> findBySupplierId(Long supplierId, Pageable pageable);
    Page<Invoice> findByOrderId(Long orderId, Pageable pageable);
    long countByStatus(String status);
    long countBySupplierId(Long supplierId);
}
