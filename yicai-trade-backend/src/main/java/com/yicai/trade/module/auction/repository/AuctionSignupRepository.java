package com.yicai.trade.module.auction.repository;

import com.yicai.trade.module.auction.entity.AuctionSignup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AuctionSignupRepository extends JpaRepository<AuctionSignup, Long> {

    /** 查询拍卖的所有报名记录 */
    List<AuctionSignup> findByAuctionIdOrderByCreatedAtDesc(Long auctionId);

    /** 查询拍卖的已通过报名记录 */
    List<AuctionSignup> findByAuctionIdAndStatusOrderByCreatedAtAsc(Long auctionId, String status);

    /** 查询供应商是否已报名 */
    Optional<AuctionSignup> findByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    /** 检查供应商是否已报名 */
    boolean existsByAuctionIdAndSupplierId(Long auctionId, Long supplierId);

    /** 统计拍卖的报名人数 */
    int countByAuctionId(Long auctionId);

    /** 统计拍卖的已通过报名人数 */
    int countByAuctionIdAndStatus(Long auctionId, String status);

    /** 查询供应商的所有报名记录 */
    List<AuctionSignup> findBySupplierIdOrderByCreatedAtDesc(Long supplierId);

    /** 查询供应商已通过的报名记录(可参与竞价的) */
    @Query("SELECT s FROM AuctionSignup s WHERE s.supplierId = :supplierId AND s.status = 'APPROVED' " +
           "AND s.auction.status IN ('SIGNUP', 'ACTIVE')")
    List<AuctionSignup> findActiveSignupsBySupplierId(@Param("supplierId") Long supplierId);
}
