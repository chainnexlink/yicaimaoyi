package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionBid;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionBidRepository extends JpaRepository<AuctionBid, Long> {

    /** 查询拍卖的所有出价(按价格升序) */
    List<AuctionBid> findByAuctionIdOrderByBidPriceAsc(Long auctionId);

    /** 查询拍卖的所有出价(按时间倒序) */
    List<AuctionBid> findByAuctionIdOrderByCreatedAtDesc(Long auctionId);

    /** 查询供应商在某拍卖的出价 */
    List<AuctionBid> findByAuctionIdAndSupplierIdOrderByCreatedAtDesc(Long auctionId, Long supplierId);

    /** 查询当前最低出价 */
    Optional<AuctionBid> findFirstByAuctionIdOrderByBidPriceAsc(Long auctionId);

    /** 统计拍卖参与供应商数 */
    @Query("SELECT COUNT(DISTINCT b.supplierId) FROM AuctionBid b WHERE b.auction.id = :auctionId")
    Integer countDistinctSuppliersByAuctionId(@Param("auctionId") Long auctionId);

    /** 统计拍卖出价总数 */
    Integer countByAuctionId(Long auctionId);

    /** 重置所有出价的最低价标记 */
    @Modifying
    @Query("UPDATE AuctionBid b SET b.isLowest = false WHERE b.auction.id = :auctionId")
    void resetLowestFlag(@Param("auctionId") Long auctionId);

    /** 设置中标标记 */
    @Modifying
    @Query("UPDATE AuctionBid b SET b.isWinner = true WHERE b.id = :bidId")
    void setWinner(@Param("bidId") Long bidId);
}
