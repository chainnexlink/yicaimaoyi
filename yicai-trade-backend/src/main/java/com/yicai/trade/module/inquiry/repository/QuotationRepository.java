package com.yicai.trade.module.inquiry.repository;

import com.yicai.trade.module.inquiry.entity.Quotation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuotationRepository extends JpaRepository<Quotation, Long> {
    List<Quotation> findByInquiryId(Long inquiryId);
    Page<Quotation> findBySupplierId(Long supplierId, Pageable pageable);

    long countByInquiryId(Long inquiryId);

    @Query("SELECT q FROM Quotation q WHERE " +
            "(:status IS NULL OR q.status = :status) AND " +
            "(:inquiryId IS NULL OR q.inquiryId = :inquiryId) AND " +
            "(:supplierId IS NULL OR q.supplierId = :supplierId)")
    Page<Quotation> findByAdminFilters(
            @Param("status") String status,
            @Param("inquiryId") Long inquiryId,
            @Param("supplierId") Long supplierId,
            Pageable pageable);

    @Query("SELECT q.inquiryId, COUNT(q) FROM Quotation q GROUP BY q.inquiryId")
    List<Object[]> countGroupByInquiryId();
}
