package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionSupplierScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionSupplierScoreRepository extends JpaRepository<AuctionSupplierScore, Long> {

    List<AuctionSupplierScore> findByAuctionIdOrderByTotalScoreDesc(Long auctionId);

    List<AuctionSupplierScore> findByAuctionIdOrderByRankingAsc(Long auctionId);

    Optional<AuctionSupplierScore> findByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    boolean existsByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    int countByAuctionId(Long auctionId);
}
