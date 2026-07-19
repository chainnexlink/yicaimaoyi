package com.yicai.trade.module.wallet.repository;

import com.yicai.trade.module.wallet.entity.PlatformCommission;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlatformCommissionRepository extends JpaRepository<PlatformCommission, Long> {

    Optional<PlatformCommission> findByContractId(Long contractId);

    List<PlatformCommission> findByBuyerId(Long buyerId);

    List<PlatformCommission> findByStatus(String status);

    Page<PlatformCommission> findByBuyerId(Long buyerId, Pageable pageable);

    Page<PlatformCommission> findAllBy(Pageable pageable);

    boolean existsByContractId(Long contractId);

    Page<PlatformCommission> findByStatus(String status, Pageable pageable);
}
