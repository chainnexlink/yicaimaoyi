package com.yicai.trade.module.score.repository;

import com.yicai.trade.module.score.entity.SupplierCredit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SupplierCreditRepository extends JpaRepository<SupplierCredit, Long> {
    Optional<SupplierCredit> findBySupplierId(Long supplierId);
    Page<SupplierCredit> findByCreditLevel(String creditLevel, Pageable pageable);
    Page<SupplierCredit> findAllByOrderByCreditScoreDesc(Pageable pageable);
}
