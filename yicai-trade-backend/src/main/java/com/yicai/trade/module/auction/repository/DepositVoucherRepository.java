package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.DepositVoucher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DepositVoucherRepository extends JpaRepository<DepositVoucher, Long> {

    List<DepositVoucher> findByUserIdAndStatusOrderByExpiresAtAsc(Long userId, String status);

    List<DepositVoucher> findByUserIdAndVoucherTypeAndStatusOrderByExpiresAtAsc(
            Long userId, String voucherType, String status);

    List<DepositVoucher> findByUserId(Long userId);

    Page<DepositVoucher> findByStatus(String status, Pageable pageable);

    Page<DepositVoucher> findByUserId(Long userId, Pageable pageable);

    @Query("SELECT COUNT(v) FROM DepositVoucher v WHERE v.userId = ?1 AND v.status = 'ACTIVE'")
    long countActiveByUserId(Long userId);

    @Query("SELECT COUNT(v) FROM DepositVoucher v WHERE v.status = ?1")
    long countByStatus(String status);

    @Query("SELECT COUNT(v) FROM DepositVoucher v WHERE v.userId = ?1 AND v.voucherType = ?2 AND v.status = 'ACTIVE'")
    long countActiveByUserIdAndType(Long userId, String voucherType);
}
