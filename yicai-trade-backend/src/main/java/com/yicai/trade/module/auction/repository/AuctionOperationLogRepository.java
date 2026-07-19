package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionOperationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuctionOperationLogRepository extends JpaRepository<AuctionOperationLog, Long> {

    List<AuctionOperationLog> findByAuctionIdOrderByCreatedAtDesc(Long auctionId);

    List<AuctionOperationLog> findByAuctionIdAndOperationTypeOrderByCreatedAtDesc(Long auctionId, String operationType);

    List<AuctionOperationLog> findByOperatorIdOrderByCreatedAtDesc(Long operatorId);
}
