package com.yicai.trade.module.dispute.repository;

import com.yicai.trade.module.dispute.entity.Dispute;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface DisputeRepository extends JpaRepository<Dispute, Long> {
    Page<Dispute> findByStatus(String status, Pageable pageable);
    Page<Dispute> findByInitiatorId(Long initiatorId, Pageable pageable);
    Page<Dispute> findByRespondentId(Long respondentId, Pageable pageable);
    Page<Dispute> findByDisputeType(String disputeType, Pageable pageable);
    Page<Dispute> findByAssignedTo(Long assignedTo, Pageable pageable);
    long countByStatus(String status);

    @Query("SELECT COUNT(d) FROM Dispute d WHERE (d.initiatorId = :supplierId AND d.initiatorRole = 'SUPPLIER') OR (d.respondentId = :supplierId AND d.respondentRole = 'SUPPLIER')")
    long countBySupplierId(Long supplierId);

    @Query("SELECT COUNT(d) FROM Dispute d WHERE d.status = 'CLOSED' AND d.rulingType IN ('FULL_REFUND','PARTIAL_REFUND','COMPENSATION') AND ((d.respondentId = :supplierId AND d.respondentRole = 'SUPPLIER'))")
    long countLostBySupplierId(Long supplierId);
}
