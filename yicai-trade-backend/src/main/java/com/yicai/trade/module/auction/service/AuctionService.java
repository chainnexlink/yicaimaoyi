package com.yicai.trade.module.auction.service;

import com.yicai.trade.module.auction.dto.AuctionCreateRequest;
import com.yicai.trade.module.auction.dto.AuctionResponse;
import com.yicai.trade.module.auction.dto.BidRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface AuctionService {

    // ========== 采购商操作 ==========

    AuctionResponse createAuction(Long buyerId, AuctionCreateRequest request);
    AuctionResponse publishAuction(Long auctionId, Long buyerId);
    void cancelAuction(Long auctionId, Long buyerId);
    Page<AuctionResponse> getBuyerAuctions(Long buyerId, Pageable pageable);
    void buyerConfirm(Long auctionId, Long buyerId);
    void buyerReject(Long auctionId, Long buyerId, String reason);

    // ========== 供应商操作 ==========

    AuctionResponse.SignupResponse signup(Long auctionId, Long supplierId, String supplierCompany,
                                          String contactName, String contactPhone, String signupIp);
    AuctionResponse.BidResponse placeBid(Long supplierId, String supplierCompany, BidRequest request, String bidIp);
    void supplierConfirm(Long auctionId, Long supplierId);
    void supplierReject(Long auctionId, Long supplierId, String reason);

    // ========== 供应商邀请 ==========

    AuctionResponse.InvitationResponse inviteSupplier(Long auctionId, Long buyerId, Long supplierId, String message);
    void respondToInvitation(Long invitationId, Long supplierId, boolean accept);

    // ========== 黑白名单 ==========

    void addToSupplierList(Long buyerId, Long supplierId, String listType, String reason);
    void removeFromSupplierList(Long buyerId, Long supplierId, String listType);

    // ========== 报名审核 ==========

    void auditSignup(Long signupId, Long auditorId, boolean approve, String remark);

    // ========== 综合评分 ==========

    void scoreSupplier(Long auctionId, Long supplierId, Long scorerId,
                       BigDecimal deliveryScore, BigDecimal qualityScore, BigDecimal serviceScore);

    // ========== 废选 & 重新拍卖 ==========

    void voidAuction(Long auctionId, Long operatorId, String reason);
    AuctionResponse reAuction(Long auctionId, Long buyerId);

    // ========== 公共查询 ==========

    AuctionResponse getAuctionDetail(Long auctionId);
    AuctionResponse getAuctionDetailWithBids(Long auctionId);
    Page<AuctionResponse> getOpenAuctions(String status, Pageable pageable);
    List<AuctionResponse> getActiveAuctionsForHome(int limit);
    List<AuctionResponse.BidResponse> getAuctionBids(Long auctionId);
    List<Map<String, Object>> getPriceCurveData(Long auctionId);

    /** 供应商查询自己在指定拍卖中的当前排名 */
    Map<String, Object> getMyBidRanking(Long auctionId, Long supplierId);

    /** 查询当前用户在该拍卖中的参与状态（报名、出价、排名、是否中标等） */
    Map<String, Object> getMyAuctionStatus(Long auctionId, Long userId);

    /** 拍卖状态跟随关联订单同步（由订单模块回调） */
    void syncAuctionStatusFromOrder(Long orderId, String orderStatus);

    // ========== 定时任务 ==========

    void autoStartAuctions();
    void autoEndAuctions();

    // ========== 管理员 ==========

    Page<AuctionResponse> getAllAuctions(String status, Pageable pageable);
    AuctionResponse approveAuction(Long auctionId);
    void rejectAuction(Long auctionId, String reason);
    Map<String, Object> getAuctionStats();
}
