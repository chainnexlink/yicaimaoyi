package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionInvitationRepository extends JpaRepository<AuctionInvitation, Long> {

    List<AuctionInvitation> findByAuctionIdOrderByCreatedAtDesc(Long auctionId);

    List<AuctionInvitation> findBySupplierIdOrderByCreatedAtDesc(Long supplierId);

    List<AuctionInvitation> findBySupplierIdAndStatus(Long supplierId, String status);

    Optional<AuctionInvitation> findByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    boolean existsByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    int countByAuctionId(Long auctionId);

    int countByAuctionIdAndStatus(Long auctionId, String status);

    /** 按拍卖ID和状态批量查询（用于自动过期等场景） */
    List<AuctionInvitation> findByAuctionIdAndStatus(Long auctionId, String status);
}
