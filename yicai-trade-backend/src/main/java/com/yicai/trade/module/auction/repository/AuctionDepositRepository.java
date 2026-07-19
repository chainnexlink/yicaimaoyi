package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionDeposit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionDepositRepository extends JpaRepository<AuctionDeposit, Long> {

    Optional<AuctionDeposit> findByAuctionIdAndUserIdAndUserTypeAndStatus(
            Long auctionId, Long userId, String userType, String status);

    List<AuctionDeposit> findByAuctionIdAndStatus(Long auctionId, String status);

    List<AuctionDeposit> findByUserIdAndStatus(Long userId, String status);

    List<AuctionDeposit> findByUserId(Long userId);

    Page<AuctionDeposit> findByStatus(String status, Pageable pageable);

    List<AuctionDeposit> findByStatus(String status);

    @Query("SELECT COUNT(d) FROM AuctionDeposit d WHERE d.status = ?1")
    long countByStatus(String status);

    @Query("SELECT COALESCE(SUM(d.amount), 0) FROM AuctionDeposit d WHERE d.status = 'PAID'")
    java.math.BigDecimal sumPaidDeposits();

    boolean existsByAuctionIdAndUserIdAndStatusIn(Long auctionId, Long userId, List<String> statuses);
}
