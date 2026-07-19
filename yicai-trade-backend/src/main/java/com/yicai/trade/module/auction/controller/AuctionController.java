package com.yicai.trade.module.auction.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.auction.dto.AuctionCreateRequest;
import com.yicai.trade.module.auction.dto.AuctionResponse;
import com.yicai.trade.module.auction.dto.BidRequest;
import com.yicai.trade.module.auction.service.AuctionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Tag(name = "Auction", description = "电子拍卖场API")
@RestController
@RequestMapping("/api/v1/auction")
@RequiredArgsConstructor
public class AuctionController {

    private final AuctionService auctionService;

    // ========== 采购商API ==========

    @Operation(summary = "创建拍卖", description = "采购商创建新的电子拍卖项目（反向拍卖/招标/询比价）")
    @PostMapping("/create")
    public Result<AuctionResponse> createAuction(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AuctionCreateRequest request) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.createAuction(userId, request));
    }

    @Operation(summary = "提交审核")
    @PostMapping("/{id}/publish")
    public Result<AuctionResponse> publishAuction(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.publishAuction(auctionId, userId));
    }

    @Operation(summary = "取消拍卖")
    @PostMapping("/{id}/cancel")
    public Result<Void> cancelAuction(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.cancelAuction(auctionId, userId);
        return Result.success(null);
    }

    @Operation(summary = "采购商确认结果")
    @PostMapping("/{id}/buyer-confirm")
    public Result<Void> buyerConfirm(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.buyerConfirm(auctionId, userId);
        return Result.success(null);
    }

    @Operation(summary = "采购商拒绝确认", description = "采购商否决竞价结果，拍卖废选")
    @PostMapping("/{id}/buyer-reject")
    public Result<Void> buyerReject(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String reason) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.buyerReject(auctionId, userId, reason);
        return Result.success(null);
    }

    @Operation(summary = "获取我的拍卖")
    @GetMapping("/my")
    public Result<Page<AuctionResponse>> getMyAuctions(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.getBuyerAuctions(userId, PageRequest.of(page, size)));
    }

    @Operation(summary = "重新拍卖", description = "基于流标/废选/已取消的拍卖重新发起")
    @PostMapping("/{id}/re-auction")
    public Result<AuctionResponse> reAuction(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.reAuction(auctionId, userId));
    }

    // ========== 供应商邀请 ==========

    @Operation(summary = "邀请供应商", description = "采购商邀请供应商参与拍卖")
    @PostMapping("/{id}/invite")
    public Result<AuctionResponse.InvitationResponse> inviteSupplier(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Long supplierId,
            @RequestParam(required = false) String message) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.inviteSupplier(auctionId, userId, supplierId, message));
    }

    @Operation(summary = "回复邀请", description = "供应商接受或拒绝拍卖邀请")
    @PostMapping("/invitation/{id}/respond")
    public Result<Void> respondToInvitation(
            @PathVariable("id") Long invitationId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam boolean accept) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.respondToInvitation(invitationId, userId, accept);
        return Result.success(null);
    }

    // ========== 黑白名单 ==========

    @Operation(summary = "添加供应商名单", description = "将供应商加入黑名单或白名单")
    @PostMapping("/supplier-list/add")
    public Result<Void> addToSupplierList(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Long supplierId,
            @RequestParam String listType,
            @RequestParam(required = false) String reason) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.addToSupplierList(userId, supplierId, listType, reason);
        return Result.success(null);
    }

    @Operation(summary = "移除供应商名单")
    @PostMapping("/supplier-list/remove")
    public Result<Void> removeFromSupplierList(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Long supplierId,
            @RequestParam String listType) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.removeFromSupplierList(userId, supplierId, listType);
        return Result.success(null);
    }

    // ========== 供应商API ==========

    @Operation(summary = "供应商报名")
    @PostMapping("/{id}/signup")
    public Result<AuctionResponse.SignupResponse> signup(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(value = "contactName", required = false) String contactName,
            @RequestParam(value = "contactPhone", required = false) String contactPhone,
            HttpServletRequest httpRequest) {
        Long userId = Long.parseLong(userDetails.getUsername());
        String supplierCompany = "供应商" + userId;
        String signupIp = httpRequest.getRemoteAddr();
        return Result.success(auctionService.signup(auctionId, userId, supplierCompany, contactName, contactPhone, signupIp));
    }

    @Operation(summary = "供应商出价")
    @PostMapping("/bid")
    public Result<AuctionResponse.BidResponse> placeBid(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody BidRequest request,
            HttpServletRequest httpRequest) {
        Long userId = Long.parseLong(userDetails.getUsername());
        String supplierCompany = "供应商" + userId;
        String bidIp = httpRequest.getRemoteAddr();
        return Result.success(auctionService.placeBid(userId, supplierCompany, request, bidIp));
    }

    @Operation(summary = "供应商确认结果")
    @PostMapping("/{id}/supplier-confirm")
    public Result<Void> supplierConfirm(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.supplierConfirm(auctionId, userId);
        return Result.success(null);
    }

    @Operation(summary = "供应商拒绝确认", description = "中标供应商拒绝确认结果，拍卖废选")
    @PostMapping("/{id}/supplier-reject")
    public Result<Void> supplierReject(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) String reason) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.supplierReject(auctionId, userId, reason);
        return Result.success(null);
    }

    // ========== 供应商排名 ==========

    @Operation(summary = "查询我的出价排名", description = "供应商查看自己在拍卖中的当前排名")
    @GetMapping("/{id}/my-ranking")
    public Result<Map<String, Object>> getMyBidRanking(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.getMyBidRanking(auctionId, userId));
    }

    // ========== 公共API ==========

    @Operation(summary = "获取拍卖详情")
    @GetMapping("/{id}")
    public Result<AuctionResponse> getAuctionDetail(@PathVariable("id") Long auctionId) {
        return Result.success(auctionService.getAuctionDetailWithBids(auctionId));
    }

    @Operation(summary = "获取我在该拍卖中的参与状态", description = "返回当前用户是否已报名、出价次数、排名、是否中标等信息")
    @GetMapping("/{id}/my-status")
    public Result<Map<String, Object>> getMyAuctionStatus(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return Result.success(auctionService.getMyAuctionStatus(auctionId, userId));
    }

    @Operation(summary = "获取公开拍卖列表")
    @GetMapping("/list")
    public Result<Page<AuctionResponse>> getOpenAuctions(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, Math.min(size, 50));
        return Result.success(auctionService.getOpenAuctions(status, PageRequest.of(safePage, safeSize)));
    }

    @Operation(summary = "获取首页拍卖")
    @GetMapping("/home")
    public Result<List<AuctionResponse>> getHomeAuctions(
            @RequestParam(value = "limit", defaultValue = "6") int limit) {
        return Result.success(auctionService.getActiveAuctionsForHome(Math.max(1, Math.min(limit, 12))));
    }

    @Operation(summary = "获取出价记录")
    @GetMapping("/{id}/bids")
    public Result<List<AuctionResponse.BidResponse>> getAuctionBids(@PathVariable("id") Long auctionId) {
        return Result.success(auctionService.getAuctionBids(auctionId));
    }

    @Operation(summary = "获取价格曲线数据", description = "用于前端绘制实时价格变化图表")
    @GetMapping("/{id}/price-curve")
    public Result<List<Map<String, Object>>> getPriceCurveData(@PathVariable("id") Long auctionId) {
        return Result.success(auctionService.getPriceCurveData(auctionId));
    }

    // ========== 管理员API ==========

    @Operation(summary = "管理员-获取所有拍卖")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/all")
    public Result<Page<AuctionResponse>> getAllAuctions(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        return Result.success(auctionService.getAllAuctions(status, PageRequest.of(page, size)));
    }

    @Operation(summary = "管理员-审核通过")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{id}/approve")
    public Result<AuctionResponse> approveAuction(@PathVariable("id") Long auctionId) {
        return Result.success(auctionService.approveAuction(auctionId));
    }

    @Operation(summary = "管理员-驳回")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{id}/reject")
    public Result<Void> rejectAuction(
            @PathVariable("id") Long auctionId,
            @RequestParam(value = "reason", required = false) String reason) {
        auctionService.rejectAuction(auctionId, reason);
        return Result.success(null);
    }

    @Operation(summary = "管理员-废选", description = "管理员宣布拍卖废选")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{id}/void")
    public Result<Void> voidAuction(
            @PathVariable("id") Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String reason) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.voidAuction(auctionId, userId, reason);
        return Result.success(null);
    }

    @Operation(summary = "管理员-报名审核", description = "审核供应商报名申请")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/signup/{id}/audit")
    public Result<Void> auditSignup(
            @PathVariable("id") Long signupId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam boolean approve,
            @RequestParam(required = false) String remark) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.auditSignup(signupId, userId, approve, remark);
        return Result.success(null);
    }

    @Operation(summary = "管理员-综合评分", description = "对供应商进行交期/质量/服务评分")
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/admin/{auctionId}/score")
    public Result<Void> scoreSupplier(
            @PathVariable Long auctionId,
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Long supplierId,
            @RequestParam(defaultValue = "0") BigDecimal deliveryScore,
            @RequestParam(defaultValue = "0") BigDecimal qualityScore,
            @RequestParam(defaultValue = "0") BigDecimal serviceScore) {
        Long userId = Long.parseLong(userDetails.getUsername());
        auctionService.scoreSupplier(auctionId, supplierId, userId, deliveryScore, qualityScore, serviceScore);
        return Result.success(null);
    }

    @Operation(summary = "管理员-统计数据")
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/stats")
    public Result<Map<String, Object>> getAuctionStats() {
        return Result.success(auctionService.getAuctionStats());
    }
}
