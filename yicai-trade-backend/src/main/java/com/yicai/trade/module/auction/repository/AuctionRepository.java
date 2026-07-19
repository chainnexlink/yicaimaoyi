package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.Auction;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionRepository extends JpaRepository<Auction, Long> {

    Optional<Auction> findByAuctionNo(String auctionNo);

    /** 串行化同一场次的出价，防止并发请求同时基于旧最低价成交。 */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT a FROM Auction a WHERE a.id = :id")
    Optional<Auction> findByIdForUpdate(@Param("id") Long id);

    /** 查询采购商的拍卖 */
    Page<Auction> findByBuyerIdOrderByCreatedAtDesc(Long buyerId, Pageable pageable);

    /** 查询指定状态的拍卖 */
    List<Auction> findByStatus(String status);

    /** 查询进行中的拍卖(首页展示) */
    @Query("SELECT a FROM Auction a WHERE a.status = 'ACTIVE' ORDER BY a.endTime ASC")
    List<Auction> findActiveAuctions();

    /** 分页查询所有可公开展示的场次，不暴露草稿、待审核或被驳回数据。 */
    @Query("SELECT a FROM Auction a WHERE a.status IN ('APPROVED', 'SIGNUP', 'PENDING', 'ACTIVE', 'CONFIRMING', 'CONFIRMED', 'DELIVERING', 'COMPLETED', 'ENDED', 'FAILED') ORDER BY a.createdAt DESC")
    Page<Auction> findPublicAuctions(Pageable pageable);

    /** 按前端状态筛选公开场次。 */
    @Query("SELECT a FROM Auction a WHERE a.status IN :statuses AND a.status IN ('APPROVED', 'SIGNUP', 'PENDING', 'ACTIVE', 'CONFIRMING', 'CONFIRMED', 'DELIVERING', 'COMPLETED', 'ENDED', 'FAILED') ORDER BY a.createdAt DESC")
    Page<Auction> findPublicAuctionsByStatusIn(@Param("statuses") List<String> statuses, Pageable pageable);

    /** 查询需要自动开始的拍卖(待开始且开始时间已到) */
    @Query("SELECT a FROM Auction a WHERE a.status IN ('PENDING', 'SIGNUP') AND a.startTime <= :now")
    List<Auction> findAuctionsToStart(@Param("now") LocalDateTime now);

    /** 查询需要自动结束的拍卖(进行中且结束时间已到) */
    @Query("SELECT a FROM Auction a WHERE a.status = 'ACTIVE' AND a.endTime <= :now")
    List<Auction> findAuctionsToEnd(@Param("now") LocalDateTime now);

    /** 查询报名开始时间已到的拍卖 */
    List<Auction> findByStatusAndSignupStartTimeBefore(String status, LocalDateTime now);

    /** 更新拍卖状态 */
    @Modifying
    @Query("UPDATE Auction a SET a.status = :status WHERE a.id = :id")
    void updateStatus(@Param("id") Long id, @Param("status") String status);

    /** 更新当前最低价和出价次数 */
    @Modifying
    @Query("UPDATE Auction a SET a.currentLowestPrice = :price, a.bidCount = a.bidCount + 1 WHERE a.id = :id")
    void updateLowestPrice(@Param("id") Long id, @Param("price") java.math.BigDecimal price);

    // ========== 管理员查询 ==========

    /** 按状态分页查询拍卖 */
    Page<Auction> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);

    /** 分页查询所有拍卖(按创建时间倒序) */
    Page<Auction> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /** 统计各状态的拍卖数量 */
    @Query("SELECT a.status, COUNT(a) FROM Auction a GROUP BY a.status")
    List<Object[]> countByStatus();

    /** 统计总出价次数 */
    @Query("SELECT COALESCE(SUM(a.bidCount), 0) FROM Auction a")
    Long sumBidCount();

    /** 统计总参与供应商数 */
    @Query("SELECT COALESCE(SUM(a.participantCount), 0) FROM Auction a")
    Long sumParticipantCount();

    /** 统计已结束拍卖的成交总金额 */
    @Query("SELECT COALESCE(SUM(a.winningPrice), 0) FROM Auction a WHERE a.status = 'ENDED' AND a.winningPrice IS NOT NULL")
    java.math.BigDecimal sumWinningPrice();

    /** 统计待审核拍卖(DRAFT状态) */
    long countByStatus(String status);

    /** 按状态列表查询 */
    List<Auction> findByStatusIn(List<String> statuses);

    /** 查询确认超时的拍卖（CONFIRMING状态且已超过confirmDeadline） */
    @Query("SELECT a FROM Auction a WHERE a.status = 'CONFIRMING' AND a.confirmDeadline IS NOT NULL AND a.confirmDeadline < :now")
    List<Auction> findExpiredConfirmingAuctions(@Param("now") LocalDateTime now);

    /** 通过关联订单ID查找拍卖 */
    Optional<Auction> findByOrderId(Long orderId);

    /** 查询报名截止但邀请未响应的拍卖（用于自动过期邀请） */
    @Query("SELECT a FROM Auction a WHERE a.status IN ('ACTIVE', 'CONFIRMING', 'CONFIRMED') AND a.signupEndTime IS NOT NULL AND a.signupEndTime < :now")
    List<Auction> findAuctionsWithExpiredSignup(@Param("now") LocalDateTime now);
}
