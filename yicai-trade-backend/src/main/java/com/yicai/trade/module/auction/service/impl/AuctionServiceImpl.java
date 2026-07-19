package com.yicai.trade.module.auction.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.module.auction.dto.AuctionCreateRequest;
import com.yicai.trade.module.auction.dto.AuctionResponse;
import com.yicai.trade.module.auction.dto.BidRequest;
import com.yicai.trade.module.auction.entity.*;
import com.yicai.trade.module.auction.repository.*;
import com.yicai.trade.module.auction.service.AuctionService;
import com.yicai.trade.module.buyer.entity.Buyer;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.contract.dto.ContractCreateRequest;
import com.yicai.trade.module.contract.dto.ContractResponse;
import com.yicai.trade.module.contract.service.ContractService;
import com.yicai.trade.module.message.dto.MessageRequest;
import com.yicai.trade.module.message.service.MessageService;
import com.yicai.trade.module.order.dto.OrderCreateRequest;
import com.yicai.trade.module.order.dto.OrderResponse;
import com.yicai.trade.module.order.service.OrderService;
import com.yicai.trade.module.smartmatch.dto.CostEstimateRequest;
import com.yicai.trade.module.smartmatch.dto.CostEstimateResponse;
import com.yicai.trade.module.smartmatch.service.SmartMatchService;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class AuctionServiceImpl implements AuctionService {

    private static final Set<String> PUBLIC_AUCTION_STATUSES = Set.of(
            "APPROVED", "SIGNUP", "PENDING", "ACTIVE", "CONFIRMING",
            "CONFIRMED", "DELIVERING", "COMPLETED", "ENDED", "FAILED");
    private static final Set<String> SUPPORTED_CURRENCIES = Set.of(
            "CNY", "USD", "EUR", "GBP", "JPY", "CAD", "AUD");

    private final AuctionRepository auctionRepository;
    private final AuctionBidRepository bidRepository;
    private final AuctionSignupRepository signupRepository;
    private final AuctionInvitationRepository invitationRepository;
    private final AuctionSupplierListRepository supplierListRepository;
    private final AuctionOperationLogRepository operationLogRepository;
    private final AuctionSupplierScoreRepository scoreRepository;
    private final BuyerRepository buyerRepository;
    private final SupplierRepository supplierRepository;
    private final OrderService orderService;
    private final MessageService messageService;
    private final ContractService contractService;
    private final SimpMessagingTemplate messagingTemplate;
    private final SmartMatchService smartMatchService;
    private final AuctionDepositRepository auctionDepositRepo;

    // ========== 采购商操作 ==========

    @Override
    @Transactional
    public AuctionResponse createAuction(Long buyerId, AuctionCreateRequest request) {
        validateCreateRequest(request);
        Buyer buyer = buyerRepository.findByUserId(buyerId).orElse(null);
        String companyName = buyer != null ? buyer.getCompanyName() : "未知公司";

        Auction auction = Auction.builder()
                .auctionNo("AUC" + System.currentTimeMillis())
                .auctionType(request.getAuctionType() != null ? request.getAuctionType() : "REVERSE_AUCTION")
                .currency(request.getCurrency() != null ? request.getCurrency().toUpperCase(Locale.ROOT) : "USD")
                .buyerId(buyerId)
                .buyerCompany(companyName)
                .productName(request.getProductName())
                .productCategory(request.getProductCategory())
                .specification(request.getSpecification())
                .quantity(request.getQuantity())
                .unit(request.getUnit() != null ? request.getUnit() : "件")
                .startingPrice(request.getStartingPrice())
                .currentLowestPrice(request.getStartingPrice())
                .minDecrement(request.getMinDecrement() != null ? request.getMinDecrement() : new BigDecimal("1.00"))
                .reservePrice(request.getReservePrice())
                .showReservePrice(request.getShowReservePrice() != null ? request.getShowReservePrice() : false)
                .inviteOnly(request.getInviteOnly() != null ? request.getInviteOnly() : false)
                .bidCooldownSeconds(request.getBidCooldownSeconds() != null ? request.getBidCooldownSeconds() : 0)
                // 报名时间
                .signupStartTime(request.getSignupStartTime())
                .signupEndTime(request.getSignupEndTime())
                // 竞价时间
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .originalEndTime(request.getEndTime())
                // 反拍规则
                .minParticipants(request.getMinParticipants() != null ? request.getMinParticipants() : 3)
                .extensionMinutes(request.getExtensionMinutes() != null ? request.getExtensionMinutes() : 5)
                .extensionTriggerMinutes(request.getExtensionTriggerMinutes() != null ? request.getExtensionTriggerMinutes() : 5)
                .maxExtensions(request.getMaxExtensions() != null ? request.getMaxExtensions() : 10)
                .showRanking(request.getShowRanking() != null ? request.getShowRanking() : true)
                .showLowestPrice(request.getShowLowestPrice() != null ? request.getShowLowestPrice() : true)
                // 综合评分
                .scoringEnabled(request.getScoringEnabled() != null ? request.getScoringEnabled() : false)
                .priceWeight(request.getPriceWeight() != null ? request.getPriceWeight() : 100)
                .deliveryWeight(request.getDeliveryWeight() != null ? request.getDeliveryWeight() : 0)
                .qualityWeight(request.getQualityWeight() != null ? request.getQualityWeight() : 0)
                .serviceWeight(request.getServiceWeight() != null ? request.getServiceWeight() : 0)
                // 状态
                .status("DRAFT")
                // 交付信息
                .deliveryAddress(request.getDeliveryAddress())
                .requiredDeliveryDate(request.getRequiredDeliveryDate())
                .paymentTerms(request.getPaymentTerms())
                .remark(request.getRemark())
                .coverImage(request.getCoverImage())
                .attachments(request.getAttachments())
                .build();

        auction = auctionRepository.save(auction);

        // 尝试从成本核算系统导入参考价
        importReferencePrice(auction);

        // 记录操作日志
        recordLog(auction, "CREATE", null, "DRAFT", buyerId, companyName,
                "创建拍卖: " + auction.getProductName() + ", 类型=" + auction.getAuctionType(), null);

        // 如果是邀请制，自动发送邀请
        if (Boolean.TRUE.equals(request.getInviteOnly()) && request.getInviteSupplierIds() != null) {
            for (Long supplierId : request.getInviteSupplierIds()) {
                inviteSupplier(auction.getId(), buyerId, supplierId, "诚邀参与拍卖: " + auction.getProductName());
            }
        }

        log.info("创建拍卖[{}]: 产品={}, 类型={}, 币种={}", auction.getAuctionNo(),
                auction.getProductName(), auction.getAuctionType(), auction.getCurrency());
        return convertToResponse(auction);
    }

    @Override
    @Transactional
    public AuctionResponse publishAuction(Long auctionId, Long buyerId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!auction.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }
        if (!"DRAFT".equals(auction.getStatus())) {
            throw new RuntimeException("只有草稿状态的拍卖可以提交审核");
        }

        // 检查采购商是否已缴纳发布押金
        if (!auctionDepositRepo.existsByAuctionIdAndUserIdAndStatusIn(auctionId, buyerId, java.util.List.of("PAID"))) {
            throw new RuntimeException("请先缴纳发布押金后再提交审核");
        }

        String fromStatus = auction.getStatus();
        auction.setStatus("PENDING_APPROVAL");
        auction = auctionRepository.save(auction);

        recordLog(auction, "PUBLISH", fromStatus, "PENDING_APPROVAL", buyerId, null,
                "提交审核", null);

        log.info("拍卖[{}]已提交审核", auction.getAuctionNo());
        return convertToResponse(auction);
    }

    @Override
    @Transactional
    public void cancelAuction(Long auctionId, Long buyerId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!auction.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }

        String status = auction.getStatus();
        if ("ENDED".equals(status) || "CONFIRMING".equals(status) || "CONFIRMED".equals(status)
                || "DELIVERING".equals(status) || "COMPLETED".equals(status)) {
            throw new RuntimeException("当前状态不允许取消");
        }

        String fromStatus = auction.getStatus();
        auction.setStatus("CANCELLED");
        auctionRepository.save(auction);

        recordLog(auction, "CANCEL", fromStatus, "CANCELLED", buyerId, null, "采购商取消拍卖", null);

        // 退还该拍卖所有已缴纳押金
        refundAllPaidDeposits(auctionId, "采购商取消拍卖,自动退还押金");

        // 通知已报名供应商
        notifySignedUpSuppliers(auction, "拍卖已取消", "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName() + " 已被采购商取消。");

        log.info("拍卖[{}]已取消", auction.getAuctionNo());
    }

    // ========== 供应商邀请 ==========

    @Transactional
    public AuctionResponse.InvitationResponse inviteSupplier(Long auctionId, Long buyerId, Long supplierId, String message) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!auction.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }

        // 检查黑名单
        if (supplierListRepository.existsByBuyerIdAndSupplierIdAndListType(buyerId, supplierId, "BLACKLIST")) {
            throw new RuntimeException("该供应商在黑名单中，无法邀请");
        }

        if (invitationRepository.existsByAuctionIdAndSupplierId(auctionId, supplierId)) {
            throw new RuntimeException("已邀请该供应商");
        }

        Supplier supplier = supplierRepository.findByUserId(supplierId).orElse(null);
        String supplierCompany = supplier != null ? supplier.getCompanyName() : "供应商" + supplierId;

        AuctionInvitation invitation = AuctionInvitation.builder()
                .auctionId(auctionId)
                .supplierId(supplierId)
                .supplierCompany(supplierCompany)
                .inviteMessage(message)
                .status("PENDING")
                .build();

        invitation = invitationRepository.save(invitation);

        // 发送站内消息通知
        try {
            MessageRequest msgReq = new MessageRequest();
            msgReq.setReceiverId(supplierId);
            msgReq.setTitle("拍卖邀请: " + auction.getProductName());
            msgReq.setContent("您被邀请参与拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName()
                    + "。" + (message != null ? message : ""));
            msgReq.setType("AUCTION_INVITE");
            messageService.sendMessage(buyerId, msgReq);
        } catch (Exception e) {
            log.warn("发送邀请通知失败: {}", e.getMessage());
        }

        recordLog(auction, "INVITE", null, null, buyerId, null,
                "邀请供应商: " + supplierCompany, null);

        return convertToInvitationResponse(invitation);
    }

    @Transactional
    public void respondToInvitation(Long invitationId, Long supplierId, boolean accept) {
        AuctionInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new RuntimeException("邀请不存在"));

        if (!invitation.getSupplierId().equals(supplierId)) {
            throw new RuntimeException("无权操作此邀请");
        }
        if (!"PENDING".equals(invitation.getStatus())) {
            throw new RuntimeException("邀请已处理");
        }

        invitation.setStatus(accept ? "ACCEPTED" : "REJECTED");
        invitation.setRespondedAt(LocalDateTime.now());
        invitationRepository.save(invitation);

        log.info("供应商[{}]{}邀请[拍卖{}]", supplierId, accept ? "接受" : "拒绝", invitation.getAuctionId());
    }

    // ========== 黑白名单 ==========

    @Transactional
    public void addToSupplierList(Long buyerId, Long supplierId, String listType, String reason) {
        if (!"WHITELIST".equals(listType) && !"BLACKLIST".equals(listType)) {
            throw new RuntimeException("名单类型无效，只支持 WHITELIST 或 BLACKLIST");
        }

        if (supplierListRepository.existsByBuyerIdAndSupplierIdAndListType(buyerId, supplierId, listType)) {
            throw new RuntimeException("供应商已在" + ("BLACKLIST".equals(listType) ? "黑" : "白") + "名单中");
        }

        Supplier supplier = supplierRepository.findByUserId(supplierId).orElse(null);
        String supplierCompany = supplier != null ? supplier.getCompanyName() : "供应商" + supplierId;

        AuctionSupplierList entry = AuctionSupplierList.builder()
                .buyerId(buyerId)
                .supplierId(supplierId)
                .supplierCompany(supplierCompany)
                .listType(listType)
                .reason(reason)
                .build();

        supplierListRepository.save(entry);
        log.info("采购商[{}]将供应商[{}]加入{}名单", buyerId, supplierId, listType);
    }

    @Transactional
    public void removeFromSupplierList(Long buyerId, Long supplierId, String listType) {
        supplierListRepository.deleteByBuyerIdAndSupplierIdAndListType(buyerId, supplierId, listType);
        log.info("采购商[{}]将供应商[{}]从{}名单移除", buyerId, supplierId, listType);
    }

    // ========== 供应商报名 ==========

    @Override
    @Transactional
    public AuctionResponse.SignupResponse signup(Long auctionId, Long supplierId, String supplierCompany,
                                                  String contactName, String contactPhone, String signupIp) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        String status = auction.getStatus();
        if (!"APPROVED".equals(status) && !"SIGNUP".equals(status)) {
            throw new RuntimeException("当前不在报名阶段");
        }

        LocalDateTime now = LocalDateTime.now();
        if (auction.getSignupStartTime() != null && now.isBefore(auction.getSignupStartTime())) {
            throw new RuntimeException("报名尚未开始");
        }
        if (auction.getSignupEndTime() != null && now.isAfter(auction.getSignupEndTime())) {
            throw new RuntimeException("报名已结束");
        }

        // 邀请制检查
        if (Boolean.TRUE.equals(auction.getInviteOnly())) {
            AuctionInvitation invitation = invitationRepository
                    .findByAuctionIdAndSupplierId(auctionId, supplierId).orElse(null);
            if (invitation == null) {
                throw new RuntimeException("此拍卖为邀请制，您未收到邀请");
            }
            if ("REJECTED".equals(invitation.getStatus())) {
                throw new RuntimeException("您已拒绝此邀请");
            }
            // 自动标记邀请为已接受
            if ("PENDING".equals(invitation.getStatus())) {
                invitation.setStatus("ACCEPTED");
                invitation.setRespondedAt(now);
                invitationRepository.save(invitation);
            }
        }

        // 黑名单检查
        if (supplierListRepository.existsByBuyerIdAndSupplierIdAndListType(
                auction.getBuyerId(), supplierId, "BLACKLIST")) {
            throw new RuntimeException("您已被该采购商列入黑名单，无法参与此拍卖");
        }

        if (signupRepository.existsByAuctionIdAndSupplierId(auctionId, supplierId)) {
            throw new RuntimeException("您已报名此拍卖");
        }

        // 检查供应商是否已缴纳竞拍押金
        if (!auctionDepositRepo.existsByAuctionIdAndUserIdAndStatusIn(auctionId, supplierId, java.util.List.of("PAID"))) {
            throw new RuntimeException("请先缴纳竞拍押金后再报名");
        }

        // 从Supplier表获取真实公司名
        Supplier supplier = supplierRepository.findByUserId(supplierId).orElse(null);
        if (supplier != null) {
            supplierCompany = supplier.getCompanyName();
        }

        AuctionSignup signup = AuctionSignup.builder()
                .auction(auction)
                .supplierId(supplierId)
                .supplierCompany(supplierCompany)
                .contactName(contactName)
                .contactPhone(contactPhone)
                .status("APPROVED") // 默认自动通过，管理员可后续调整
                .signupIp(signupIp)
                .build();

        signup = signupRepository.save(signup);
        auction.setSignupCount(signupRepository.countByAuctionId(auctionId));
        auctionRepository.save(auction);

        recordLog(auction, "SIGNUP", null, null, supplierId, supplierCompany,
                "供应商报名参与", signupIp);

        log.info("拍卖[{}]新报名: 供应商={}", auction.getAuctionNo(), supplierCompany);
        return convertToSignupResponse(signup);
    }

    // ========== 报名审核 ==========

    @Transactional
    public void auditSignup(Long signupId, Long auditorId, boolean approve, String remark) {
        AuctionSignup signup = signupRepository.findById(signupId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));

        if (!"PENDING".equals(signup.getStatus()) && !"APPROVED".equals(signup.getStatus())) {
            throw new RuntimeException("报名状态不允许审核");
        }

        signup.setStatus(approve ? "APPROVED" : "REJECTED");
        signup.setAuditRemark(remark);
        signup.setAuditedAt(LocalDateTime.now());
        signup.setAuditedBy(auditorId);
        signupRepository.save(signup);

        // 更新拍卖报名人数
        Auction auction = signup.getAuction();
        auction.setSignupCount(signupRepository.countByAuctionIdAndStatus(auction.getId(), "APPROVED"));
        auctionRepository.save(auction);

        // 通知供应商审核结果
        try {
            MessageRequest msgReq = new MessageRequest();
            msgReq.setReceiverId(signup.getSupplierId());
            msgReq.setTitle("报名审核结果");
            msgReq.setContent("您在拍卖[" + auction.getAuctionNo() + "]的报名已" + (approve ? "通过" : "被拒绝")
                    + (remark != null ? "，原因: " + remark : ""));
            msgReq.setType("AUCTION_SIGNUP");
            messageService.sendMessage(auditorId, msgReq);
        } catch (Exception e) {
            log.warn("发送审核通知失败: {}", e.getMessage());
        }

        recordLog(signup.getAuction(), approve ? "SIGNUP_APPROVE" : "SIGNUP_REJECT",
                null, null, auditorId, null,
                (approve ? "通过" : "拒绝") + "供应商报名: " + signup.getSupplierCompany()
                        + (remark != null ? ", 备注: " + remark : ""),
                null);
    }

    // ========== 供应商出价 ==========

    @Override
    @Transactional
    public AuctionResponse.BidResponse placeBid(Long supplierId, String supplierCompany, BidRequest request, String bidIp) {
        if (request == null || request.getAuctionId() == null || request.getBidPrice() == null
                || request.getBidPrice().signum() <= 0) {
            throw new BusinessException(400, "竞价ID和大于0的出价金额不能为空");
        }
        Auction auction = auctionRepository.findByIdForUpdate(request.getAuctionId())
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!"ACTIVE".equals(auction.getStatus())) {
            throw new RuntimeException("拍卖未在竞价中，无法出价");
        }

        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(auction.getStartTime())) {
            throw new RuntimeException("竞价尚未开始");
        }
        if (now.isAfter(auction.getEndTime())) {
            throw new RuntimeException("竞价已结束");
        }

        // 检查报名
        AuctionSignup signup = signupRepository.findByAuctionIdAndSupplierId(auction.getId(), supplierId)
                .orElseThrow(() -> new RuntimeException("您尚未报名此拍卖，请先报名"));
        if (!"APPROVED".equals(signup.getStatus())) {
            throw new RuntimeException("您的报名未通过审核");
        }

        // 从Supplier表获取真实公司名
        Supplier supplier = supplierRepository.findByUserId(supplierId).orElse(null);
        if (supplier != null) {
            supplierCompany = supplier.getCompanyName();
        }

        // 出价冷却检查
        if (auction.getBidCooldownSeconds() != null && auction.getBidCooldownSeconds() > 0
                && signup.getLastBidTime() != null) {
            long secondsSinceLastBid = ChronoUnit.SECONDS.between(signup.getLastBidTime(), now);
            if (secondsSinceLastBid < auction.getBidCooldownSeconds()) {
                throw new RuntimeException("出价过于频繁，请等待 " + (auction.getBidCooldownSeconds() - secondsSinceLastBid) + " 秒后再试");
            }
        }

        BigDecimal bidPrice = request.getBidPrice();

        // 验证出价不高于起拍价
        if (bidPrice.compareTo(auction.getStartingPrice()) > 0) {
            throw new RuntimeException("出价不能高于最高限价 " + auction.getStartingPrice());
        }

        // 验证出价低于当前最低价
        if (auction.getCurrentLowestPrice() != null && bidPrice.compareTo(auction.getCurrentLowestPrice()) >= 0) {
            throw new RuntimeException("出价必须低于当前最低价 " + auction.getCurrentLowestPrice());
        }

        // 验证降价幅度
        if (auction.getCurrentLowestPrice() != null && auction.getMinDecrement() != null) {
            BigDecimal minAllowed = auction.getCurrentLowestPrice().subtract(auction.getMinDecrement());
            if (bidPrice.compareTo(minAllowed) > 0) {
                throw new RuntimeException("出价至少需要降低 " + auction.getMinDecrement() + " " + auction.getCurrency());
            }
        }

        // 底价校验（如果设置了底价，不接受低于底价的出价）
        if (auction.getReservePrice() != null && bidPrice.compareTo(auction.getReservePrice()) < 0) {
            throw new RuntimeException("出价低于底价限制");
        }

        Integer bidCount = bidRepository.countByAuctionId(auction.getId());
        bidRepository.resetLowestFlag(auction.getId());

        // 计算总金额
        BigDecimal totalAmount = bidPrice.multiply(new BigDecimal(auction.getQuantity()));

        AuctionBid bid = AuctionBid.builder()
                .auction(auction)
                .supplierId(supplierId)
                .supplierCompany(supplierCompany)
                .bidPrice(bidPrice)
                .totalAmount(totalAmount)
                .promisedDeliveryDays(request.getPromisedDeliveryDays())
                .bidSequence(bidCount + 1)
                .isLowest(true)
                .isWinner(false)
                .remark(request.getRemark())
                .bidIp(bidIp)
                .build();

        bid = bidRepository.save(bid);

        auction.setCurrentLowestPrice(bidPrice);
        auction.setBidCount(bidCount + 1);

        Integer participantCount = bidRepository.countDistinctSuppliersByAuctionId(auction.getId());
        auction.setParticipantCount(participantCount);

        // 延时规则
        if (auction.getExtensionTriggerMinutes() != null && auction.getExtensionMinutes() != null) {
            long remainingMinutes = ChronoUnit.MINUTES.between(now, auction.getEndTime());
            int currentExtensions = auction.getCurrentExtensions() == null ? 0 : auction.getCurrentExtensions();
            int maxExtensions = auction.getMaxExtensions() == null ? 0 : auction.getMaxExtensions();
            if (remainingMinutes <= auction.getExtensionTriggerMinutes()
                    && currentExtensions < maxExtensions) {
                LocalDateTime newEndTime = auction.getEndTime().plusMinutes(auction.getExtensionMinutes());
                auction.setEndTime(newEndTime);
                auction.setCurrentExtensions(currentExtensions + 1);

                recordLog(auction, "EXTEND", "ACTIVE", "ACTIVE", null, null,
                        "自动延时: 延长" + auction.getExtensionMinutes() + "分钟，第"
                                + auction.getCurrentExtensions() + "次延时", null);

                log.info("拍卖[{}]触发延时规则，延时{}分钟，当前延时次数: {}",
                        auction.getAuctionNo(), auction.getExtensionMinutes(), auction.getCurrentExtensions());
            }
        }

        signup.setHasBid(true);
        signup.setBidCount(signup.getBidCount() + 1);
        signup.setLastBidTime(now);
        signupRepository.save(signup);
        auctionRepository.save(auction);

        recordLog(auction, "BID", null, null, supplierId, supplierCompany,
                "出价: " + bidPrice + " " + auction.getCurrency() + ", 总额: " + totalAmount, bidIp);

        // WebSocket实时推送出价通知
        pushBidUpdate(auction, bid);

        log.info("拍卖[{}]收到新出价: 供应商={}, 价格={}", auction.getAuctionNo(), supplierCompany, bidPrice);
        return convertToBidResponse(bid);
    }

    // ========== WebSocket推送 ==========

    private void pushBidUpdate(Auction auction, AuctionBid bid) {
        try {
            Map<String, Object> bidUpdate = new HashMap<>();
            bidUpdate.put("type", "BID_UPDATE");
            bidUpdate.put("auctionId", auction.getId());
            bidUpdate.put("auctionNo", auction.getAuctionNo());
            bidUpdate.put("currentLowestPrice", auction.getCurrentLowestPrice());
            bidUpdate.put("bidCount", auction.getBidCount());
            bidUpdate.put("participantCount", auction.getParticipantCount());
            bidUpdate.put("endTime", auction.getEndTime().toString());
            bidUpdate.put("currentExtensions", auction.getCurrentExtensions());
            bidUpdate.put("bidSequence", bid.getBidSequence());
            bidUpdate.put("timestamp", LocalDateTime.now().toString());

            // 如果允许查看最低价，推送详细信息
            if (Boolean.TRUE.equals(auction.getShowLowestPrice())) {
                bidUpdate.put("bidPrice", bid.getBidPrice());
                bidUpdate.put("supplierCompany", bid.getSupplierCompany());
            }

            // 推送到拍卖频道
            messagingTemplate.convertAndSend("/topic/auction/" + auction.getId(), bidUpdate);

            // 推送价格曲线数据点
            Map<String, Object> pricePoint = new HashMap<>();
            pricePoint.put("type", "PRICE_POINT");
            pricePoint.put("price", bid.getBidPrice());
            pricePoint.put("time", bid.getCreatedAt() != null ? bid.getCreatedAt().toString() : LocalDateTime.now().toString());
            pricePoint.put("sequence", bid.getBidSequence());
            messagingTemplate.convertAndSend("/topic/auction/" + auction.getId() + "/price-curve", pricePoint);

        } catch (Exception e) {
            log.warn("WebSocket推送失败: {}", e.getMessage());
        }
    }

    private void pushAuctionStatusUpdate(Auction auction, String eventType) {
        try {
            Map<String, Object> statusUpdate = new HashMap<>();
            statusUpdate.put("type", eventType);
            statusUpdate.put("auctionId", auction.getId());
            statusUpdate.put("auctionNo", auction.getAuctionNo());
            statusUpdate.put("status", auction.getStatus());
            statusUpdate.put("timestamp", LocalDateTime.now().toString());

            if ("AUCTION_END".equals(eventType) && auction.getWinnerSupplierId() != null) {
                statusUpdate.put("winnerSupplierId", auction.getWinnerSupplierId());
                statusUpdate.put("winnerCompany", auction.getWinnerCompany());
                statusUpdate.put("winningPrice", auction.getWinningPrice());
            }

            messagingTemplate.convertAndSend("/topic/auction/" + auction.getId(), statusUpdate);
        } catch (Exception e) {
            log.warn("WebSocket推送状态更新失败: {}", e.getMessage());
        }
    }

    // ========== 成本核算系统集成 ==========

    private void importReferencePrice(Auction auction) {
        try {
            CostEstimateRequest costReq = CostEstimateRequest.builder()
                    .categoryCode(auction.getProductName())
                    .build();
            CostEstimateResponse costResp = smartMatchService.estimateCost(costReq, "zh");

            if (costResp != null && costResp.getCostBreakdown() != null
                    && costResp.getCostBreakdown().getTotalCost() != null) {
                auction.setReferencePrice(costResp.getCostBreakdown().getTotalCost());
                auction.setReferenceSource("AI成本核算系统自动估算");
                auctionRepository.save(auction);
                log.info("拍卖[{}]导入参考价: {}", auction.getAuctionNo(), costResp.getCostBreakdown().getTotalCost());
            }
        } catch (Exception e) {
            log.warn("导入参考价失败（不影响拍卖创建）: {}", e.getMessage());
        }
    }

    // ========== 消息通知 ==========

    private void notifySignedUpSuppliers(Auction auction, String title, String content) {
        try {
            List<AuctionSignup> signups = signupRepository
                    .findByAuctionIdAndStatusOrderByCreatedAtAsc(auction.getId(), "APPROVED");
            for (AuctionSignup s : signups) {
                MessageRequest msgReq = new MessageRequest();
                msgReq.setReceiverId(s.getSupplierId());
                msgReq.setTitle(title);
                msgReq.setContent(content);
                msgReq.setType("AUCTION_NOTIFICATION");
                messageService.sendMessage(auction.getBuyerId(), msgReq);
            }
        } catch (Exception e) {
            log.warn("批量通知供应商失败: {}", e.getMessage());
        }
    }

    private void notifyWinner(Auction auction) {
        try {
            MessageRequest msgReq = new MessageRequest();
            msgReq.setReceiverId(auction.getWinnerSupplierId());
            msgReq.setTitle("恭喜中标: " + auction.getProductName());
            msgReq.setContent("您在拍卖[" + auction.getAuctionNo() + "]中以价格 " + auction.getWinningPrice()
                    + " " + auction.getCurrency() + " 中标，请在48小时内确认结果。");
            msgReq.setType("AUCTION_WIN");
            messageService.sendMessage(auction.getBuyerId(), msgReq);
        } catch (Exception e) {
            log.warn("通知中标供应商失败: {}", e.getMessage());
        }
    }

    private void notifyLosers(Auction auction) {
        try {
            List<AuctionSignup> signups = signupRepository
                    .findByAuctionIdAndStatusOrderByCreatedAtAsc(auction.getId(), "APPROVED");
            for (AuctionSignup s : signups) {
                if (!s.getSupplierId().equals(auction.getWinnerSupplierId())) {
                    MessageRequest msgReq = new MessageRequest();
                    msgReq.setReceiverId(s.getSupplierId());
                    msgReq.setTitle("拍卖结果通知: " + auction.getProductName());
                    msgReq.setContent("拍卖[" + auction.getAuctionNo() + "]已结束，很遗憾您未中标。感谢参与！");
                    msgReq.setType("AUCTION_LOSE");
                    messageService.sendMessage(auction.getBuyerId(), msgReq);
                }
            }
        } catch (Exception e) {
            log.warn("通知未中标供应商失败: {}", e.getMessage());
        }
    }

    // ========== 综合评分 ==========

    @Transactional
    public void scoreSupplier(Long auctionId, Long supplierId, Long scorerId,
                              BigDecimal deliveryScore, BigDecimal qualityScore, BigDecimal serviceScore) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!Boolean.TRUE.equals(auction.getScoringEnabled())) {
            throw new RuntimeException("此拍卖未启用综合评分");
        }

        Supplier supplier = supplierRepository.findByUserId(supplierId).orElse(null);
        String supplierCompany = supplier != null ? supplier.getCompanyName() : "供应商" + supplierId;

        // 自动计算价格得分（最低价100分，其他按比例）
        BigDecimal priceScore = calculatePriceScore(auctionId, supplierId);

        // 计算加权综合得分
        BigDecimal totalScore = priceScore.multiply(new BigDecimal(auction.getPriceWeight()))
                .add(deliveryScore.multiply(new BigDecimal(auction.getDeliveryWeight())))
                .add(qualityScore.multiply(new BigDecimal(auction.getQualityWeight())))
                .add(serviceScore.multiply(new BigDecimal(auction.getServiceWeight())))
                .divide(new BigDecimal(100), 2, RoundingMode.HALF_UP);

        AuctionSupplierScore score = scoreRepository.findByAuctionIdAndSupplierId(auctionId, supplierId)
                .orElse(AuctionSupplierScore.builder()
                        .auctionId(auctionId)
                        .supplierId(supplierId)
                        .supplierCompany(supplierCompany)
                        .build());

        score.setPriceScore(priceScore);
        score.setDeliveryScore(deliveryScore);
        score.setQualityScore(qualityScore);
        score.setServiceScore(serviceScore);
        score.setTotalScore(totalScore);
        score.setScoredBy(scorerId);
        score.setScoredAt(LocalDateTime.now());

        scoreRepository.save(score);

        // 重新计算排名
        recalculateRankings(auctionId);

        recordLog(auction, "SCORE", null, null, scorerId, null,
                "评分供应商: " + supplierCompany + ", 综合得分: " + totalScore, null);
    }

    private BigDecimal calculatePriceScore(Long auctionId, Long supplierId) {
        // 获取该供应商最低出价
        List<AuctionBid> supplierBids = bidRepository
                .findByAuctionIdAndSupplierIdOrderByCreatedAtDesc(auctionId, supplierId);
        if (supplierBids.isEmpty()) return BigDecimal.ZERO;

        BigDecimal supplierLowest = supplierBids.stream()
                .map(AuctionBid::getBidPrice)
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        // 获取所有供应商最低出价
        AuctionBid overallLowest = bidRepository.findFirstByAuctionIdOrderByBidPriceAsc(auctionId).orElse(null);
        if (overallLowest == null) return BigDecimal.ZERO;

        // 价格得分 = (最低价 / 该供应商价格) * 100
        if (supplierLowest.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
        return overallLowest.getBidPrice()
                .multiply(new BigDecimal("100"))
                .divide(supplierLowest, 2, RoundingMode.HALF_UP);
    }

    private void recalculateRankings(Long auctionId) {
        List<AuctionSupplierScore> scores = scoreRepository.findByAuctionIdOrderByTotalScoreDesc(auctionId);
        int rank = 1;
        for (AuctionSupplierScore score : scores) {
            score.setRanking(rank++);
        }
        scoreRepository.saveAll(scores);
    }

    // ========== 废选 & 重新拍卖 ==========

    @Transactional
    public void voidAuction(Long auctionId, Long operatorId, String reason) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        String fromStatus = auction.getStatus();
        if (!"CONFIRMING".equals(fromStatus) && !"ACTIVE".equals(fromStatus) && !"ENDED".equals(fromStatus)) {
            throw new RuntimeException("当前状态不允许废选");
        }

        auction.setStatus("VOIDED");
        auctionRepository.save(auction);

        recordLog(auction, "VOID", fromStatus, "VOIDED", operatorId, null,
                "废选原因: " + reason, null);

        // 退还所有押金
        refundAllPaidDeposits(auctionId, "拍卖废选,自动退还押金");

        notifySignedUpSuppliers(auction, "拍卖废选通知",
                "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName() + " 已废选。原因: " + reason);

        log.info("拍卖[{}]已废选, 原因: {}", auction.getAuctionNo(), reason);
    }

    @Transactional
    public AuctionResponse reAuction(Long auctionId, Long buyerId) {
        Auction original = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!original.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }

        String status = original.getStatus();
        if (!"FAILED".equals(status) && !"VOIDED".equals(status) && !"CANCELLED".equals(status)) {
            throw new RuntimeException("只有流标/废选/已取消的拍卖可以重新拍卖");
        }

        // 基于原拍卖创建新拍卖（草稿状态）
        LocalDateTime now = LocalDateTime.now();
        Auction newAuction = Auction.builder()
                .auctionNo("AUC" + System.currentTimeMillis())
                .auctionType(original.getAuctionType())
                .currency(original.getCurrency())
                .buyerId(buyerId)
                .buyerCompany(original.getBuyerCompany())
                .productName(original.getProductName())
                .productCategory(original.getProductCategory())
                .specification(original.getSpecification())
                .quantity(original.getQuantity())
                .unit(original.getUnit())
                .startingPrice(original.getStartingPrice())
                .currentLowestPrice(original.getStartingPrice())
                .minDecrement(original.getMinDecrement())
                .reservePrice(original.getReservePrice())
                .showReservePrice(original.getShowReservePrice())
                .referencePrice(original.getReferencePrice())
                .referenceSource(original.getReferenceSource())
                .inviteOnly(original.getInviteOnly())
                .bidCooldownSeconds(original.getBidCooldownSeconds())
                // 时间需要重新设置
                .signupStartTime(now.plusHours(1))
                .signupEndTime(now.plusDays(2))
                .startTime(now.plusDays(2))
                .endTime(now.plusDays(3))
                .originalEndTime(now.plusDays(3))
                // 规则
                .minParticipants(original.getMinParticipants())
                .extensionMinutes(original.getExtensionMinutes())
                .extensionTriggerMinutes(original.getExtensionTriggerMinutes())
                .maxExtensions(original.getMaxExtensions())
                .showRanking(original.getShowRanking())
                .showLowestPrice(original.getShowLowestPrice())
                .scoringEnabled(original.getScoringEnabled())
                .priceWeight(original.getPriceWeight())
                .deliveryWeight(original.getDeliveryWeight())
                .qualityWeight(original.getQualityWeight())
                .serviceWeight(original.getServiceWeight())
                // 状态
                .status("DRAFT")
                // 交付
                .deliveryAddress(original.getDeliveryAddress())
                .requiredDeliveryDate(original.getRequiredDeliveryDate())
                .paymentTerms(original.getPaymentTerms())
                .remark("由拍卖[" + original.getAuctionNo() + "]重新发起")
                .coverImage(original.getCoverImage())
                .attachments(original.getAttachments())
                .build();

        newAuction = auctionRepository.save(newAuction);

        recordLog(newAuction, "REAUCTION", null, "DRAFT", buyerId, null,
                "基于拍卖[" + original.getAuctionNo() + "]重新发起", null);

        log.info("基于拍卖[{}]重新创建拍卖[{}]", original.getAuctionNo(), newAuction.getAuctionNo());
        return convertToResponse(newAuction);
    }

    // ========== 查询方法 ==========

    @Override
    public AuctionResponse getAuctionDetail(Long auctionId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        return convertToResponse(auction);
    }

    @Override
    public AuctionResponse getAuctionDetailWithBids(Long auctionId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        if (!PUBLIC_AUCTION_STATUSES.contains(auction.getStatus())) {
            throw new BusinessException(404, "竞价不存在或尚未公开");
        }
        AuctionResponse response = convertToPublicResponse(auction);
        response.setBids(getAuctionBids(auctionId));
        return response;
    }

    @Override
    public Page<AuctionResponse> getOpenAuctions(String status, Pageable pageable) {
        if (status == null || status.isBlank() || "ALL".equalsIgnoreCase(status)) {
            return auctionRepository.findPublicAuctions(pageable).map(this::convertToPublicResponse);
        }
        String normalized = status.trim().toUpperCase(Locale.ROOT);
        List<String> statuses = switch (normalized) {
            case "ENDED" -> List.of("ENDED", "CONFIRMED", "DELIVERING", "COMPLETED", "FAILED");
            case "ACTIVE", "PENDING", "SIGNUP", "CONFIRMING" -> List.of(normalized);
            default -> throw new BusinessException(400, "不支持的竞价状态筛选");
        };
        return auctionRepository.findPublicAuctionsByStatusIn(statuses, pageable)
                .map(this::convertToPublicResponse);
    }

    @Override
    public List<AuctionResponse> getActiveAuctionsForHome(int limit) {
        return auctionRepository.findActiveAuctions().stream()
                .limit(limit)
                .map(this::convertToPublicResponse)
                .collect(Collectors.toList());
    }

    @Override
    public Page<AuctionResponse> getBuyerAuctions(Long buyerId, Pageable pageable) {
        return auctionRepository.findByBuyerIdOrderByCreatedAtDesc(buyerId, pageable)
                .map(this::convertToResponse);
    }

    @Override
    public List<AuctionResponse.BidResponse> getAuctionBids(Long auctionId) {
        ensurePublicAuction(auctionId);
        List<AuctionBid> bids = bidRepository.findByAuctionIdOrderByCreatedAtDesc(auctionId);
        Map<Long, String> aliases = buildPublicSupplierAliases(bids);
        return bids.stream()
                .map(bid -> convertToPublicBidResponse(bid, aliases.getOrDefault(bid.getSupplierId(), "匿名供应商")))
                .collect(Collectors.toList());
    }

    /** 获取拍卖价格曲线数据 */
    public List<Map<String, Object>> getPriceCurveData(Long auctionId) {
        ensurePublicAuction(auctionId);
        List<AuctionBid> bids = bidRepository.findByAuctionIdOrderByBidPriceAsc(auctionId);
        Map<Long, String> aliases = buildPublicSupplierAliases(bids);
        // 按时间排序返回价格数据点
        return bids.stream()
                .sorted(Comparator.comparing(AuctionBid::getCreatedAt))
                .map(bid -> {
                    Map<String, Object> point = new HashMap<>();
                    point.put("time", bid.getCreatedAt());
                    point.put("price", bid.getBidPrice());
                    point.put("sequence", bid.getBidSequence());
                    point.put("supplierCompany", aliases.getOrDefault(bid.getSupplierId(), "匿名供应商"));
                    return point;
                })
                .collect(Collectors.toList());
    }

    // ========== 定时任务 ==========

    @Override
    @Transactional
    @Scheduled(fixedRate = 60000)
    public void autoStartAuctions() {
        LocalDateTime now = LocalDateTime.now();

        // 1. 报名开始 (APPROVED → SIGNUP)
        List<Auction> toSignup = auctionRepository.findByStatusAndSignupStartTimeBefore("APPROVED", now);
        for (Auction auction : toSignup) {
            String fromStatus = auction.getStatus();
            auction.setStatus("SIGNUP");
            auctionRepository.save(auction);
            recordLog(auction, "START", fromStatus, "SIGNUP", null, "系统", "报名阶段自动开始", null);

            // 通知被邀请的供应商
            if (Boolean.TRUE.equals(auction.getInviteOnly())) {
                List<AuctionInvitation> invitations = invitationRepository
                        .findByAuctionIdOrderByCreatedAtDesc(auction.getId());
                for (AuctionInvitation inv : invitations) {
                    if ("PENDING".equals(inv.getStatus())) {
                        try {
                            MessageRequest msgReq = new MessageRequest();
                            msgReq.setReceiverId(inv.getSupplierId());
                            msgReq.setTitle("拍卖报名开始: " + auction.getProductName());
                            msgReq.setContent("拍卖[" + auction.getAuctionNo() + "]报名已开始，请尽快报名参与。");
                            msgReq.setType("AUCTION_NOTIFICATION");
                            messageService.sendMessage(auction.getBuyerId(), msgReq);
                        } catch (Exception e) {
                            log.warn("通知邀请供应商失败: {}", e.getMessage());
                        }
                    }
                }
            }

            pushAuctionStatusUpdate(auction, "AUCTION_SIGNUP_START");
            log.info("拍卖[{}]报名开始", auction.getAuctionNo());
        }

        // 2. 竞价开始 (SIGNUP → ACTIVE)
        List<Auction> toStart = auctionRepository.findAuctionsToStart(now);
        for (Auction auction : toStart) {
            int signupCount = signupRepository.countByAuctionIdAndStatus(auction.getId(), "APPROVED");
            String fromStatus = auction.getStatus();
            if (signupCount < auction.getMinParticipants()) {
                auction.setStatus("FAILED");
                recordLog(auction, "FAIL", fromStatus, "FAILED", null, "系统",
                        "流标: 报名人数" + signupCount + "不足最低要求" + auction.getMinParticipants(), null);

                notifySignedUpSuppliers(auction, "拍卖流标通知",
                        "拍卖[" + auction.getAuctionNo() + "]因报名人数不足已流标。");
                pushAuctionStatusUpdate(auction, "AUCTION_FAILED");

                // 流标退还所有押金
                refundAllPaidDeposits(auction.getId(), "报名人数不足流标,自动退还押金");

                log.info("拍卖[{}]流标: 报名人数{}不足最低要求{}",
                        auction.getAuctionNo(), signupCount, auction.getMinParticipants());
            } else {
                auction.setStatus("ACTIVE");
                recordLog(auction, "START", fromStatus, "ACTIVE", null, "系统",
                        "竞价开始, 报名供应商数: " + signupCount, null);

                notifySignedUpSuppliers(auction, "竞价开始: " + auction.getProductName(),
                        "拍卖[" + auction.getAuctionNo() + "]竞价已开始，请尽快参与出价。");
                pushAuctionStatusUpdate(auction, "AUCTION_ACTIVE");

                log.info("拍卖[{}]竞价开始, 报名供应商数: {}", auction.getAuctionNo(), signupCount);
            }
            auctionRepository.save(auction);
        }
    }

    @Override
    @Transactional
    @Scheduled(fixedRate = 60000)
    public void autoEndAuctions() {
        LocalDateTime now = LocalDateTime.now();
        List<Auction> toEnd = auctionRepository.findAuctionsToEnd(now);

        for (Auction auction : toEnd) {
            String fromStatus = auction.getStatus();

            // 根据是否启用综合评分决定中标逻辑
            if (Boolean.TRUE.equals(auction.getScoringEnabled())) {
                // 综合评分模式：按 totalScore 最高者中标
                determineWinnerByScore(auction);
            } else {
                // 最低价模式：按最低出价中标
                bidRepository.findFirstByAuctionIdOrderByBidPriceAsc(auction.getId())
                        .ifPresent(winningBid -> {
                            auction.setWinnerSupplierId(winningBid.getSupplierId());
                            auction.setWinnerCompany(winningBid.getSupplierCompany());
                            auction.setWinningPrice(winningBid.getBidPrice());
                            bidRepository.setWinner(winningBid.getId());
                            auction.setConfirmDeadline(now.plusHours(48));

                            log.info("拍卖[{}]最低价中标: 供应商={}, 价格={}",
                                    auction.getAuctionNo(), winningBid.getSupplierCompany(), winningBid.getBidPrice());
                        });
            }

            if (auction.getWinnerSupplierId() == null) {
                auction.setStatus("FAILED");
                recordLog(auction, "FAIL", fromStatus, "FAILED", null, "系统", "流标: 无有效出价", null);
                notifySignedUpSuppliers(auction, "拍卖流标", "拍卖[" + auction.getAuctionNo() + "]因无有效出价已流标。");
                pushAuctionStatusUpdate(auction, "AUCTION_FAILED");
                refundAllPaidDeposits(auction.getId(), "无有效出价流标,自动退还押金");
                log.info("拍卖[{}]流标: 无有效出价", auction.getAuctionNo());
            } else {
                // 底价校验：中标价高于底价时标记为未达标（仅反向拍卖不会出现，但做防御）
                boolean reservePriceMet = true;
                if (auction.getReservePrice() != null && auction.getWinningPrice() != null
                        && auction.getWinningPrice().compareTo(auction.getReservePrice()) > 0) {
                    reservePriceMet = false;
                }

                auction.setStatus("CONFIRMING");
                String endDetail = Boolean.TRUE.equals(auction.getScoringEnabled())
                        ? "竞价结束(综合评分模式), 最高评分中标: " + auction.getWinnerCompany() + ", 价格: " + auction.getWinningPrice()
                        : "竞价结束, 中标: " + auction.getWinnerCompany() + ", 价格: " + auction.getWinningPrice();
                if (!reservePriceMet) {
                    endDetail += " [注意: 中标价未达到底价]";
                }
                recordLog(auction, "END", fromStatus, "CONFIRMING", null, "系统", endDetail, null);

                notifyWinner(auction);
                notifyLosers(auction);
                // 通知采购商竞价结束结果
                notifyBuyerAuctionResult(auction);
                pushAuctionStatusUpdate(auction, "AUCTION_END");

                log.info("拍卖[{}]竞价结束，等待确认", auction.getAuctionNo());
            }

            auctionRepository.save(auction);
        }
    }

    /**
     * 综合评分模式：根据 AuctionSupplierScore 中的 totalScore 最高者中标。
     * 如果没有任何评分记录，回退到最低价模式。
     */
    private void determineWinnerByScore(Auction auction) {
        LocalDateTime now = LocalDateTime.now();
        List<AuctionSupplierScore> scores = scoreRepository
                .findByAuctionIdOrderByTotalScoreDesc(auction.getId());

        if (!scores.isEmpty()) {
            AuctionSupplierScore topScore = scores.get(0);
            // 找到该供应商的最低出价
            bidRepository.findByAuctionIdAndSupplierIdOrderByCreatedAtDesc(auction.getId(), topScore.getSupplierId())
                    .stream().findFirst()
                    .ifPresent(winnerBid -> {
                        auction.setWinnerSupplierId(topScore.getSupplierId());
                        auction.setWinnerCompany(topScore.getSupplierCompany());
                        auction.setWinningPrice(winnerBid.getBidPrice());
                        bidRepository.setWinner(winnerBid.getId());
                        auction.setConfirmDeadline(now.plusHours(48));

                        log.info("拍卖[{}]综合评分中标: 供应商={}, 得分={}, 价格={}",
                                auction.getAuctionNo(), topScore.getSupplierCompany(),
                                topScore.getTotalScore(), winnerBid.getBidPrice());
                    });
        }

        // 如果评分模式没产生中标者（无评分记录），回退到最低价模式
        if (auction.getWinnerSupplierId() == null) {
            log.warn("拍卖[{}]启用了综合评分但无评分记录，回退到最低价模式", auction.getAuctionNo());
            bidRepository.findFirstByAuctionIdOrderByBidPriceAsc(auction.getId())
                    .ifPresent(winningBid -> {
                        auction.setWinnerSupplierId(winningBid.getSupplierId());
                        auction.setWinnerCompany(winningBid.getSupplierCompany());
                        auction.setWinningPrice(winningBid.getBidPrice());
                        bidRepository.setWinner(winningBid.getId());
                        auction.setConfirmDeadline(now.plusHours(48));
                    });
        }
    }

    /**
     * 通知采购商拍卖结果
     */
    private void notifyBuyerAuctionResult(Auction auction) {
        try {
            String content = "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName()
                    + " 竞价已结束，中标供应商: " + auction.getWinnerCompany()
                    + "，中标价格: " + auction.getWinningPrice() + " " + auction.getCurrency()
                    + "，请在48小时内确认结果。";
            MessageRequest msgReq = new MessageRequest();
            msgReq.setReceiverId(auction.getBuyerId());
            msgReq.setTitle("拍卖竞价结束: " + auction.getProductName());
            msgReq.setContent(content);
            msgReq.setType("AUCTION_RESULT");
            messageService.sendMessage(0L, msgReq);
        } catch (Exception e) {
            log.warn("通知采购商拍卖结果失败: {}", e.getMessage());
        }
    }

    /**
     * 每5分钟扫描一次，将超过confirmDeadline仍未双方确认的CONFIRMING拍卖自动废选。
     */
    @Transactional
    @Scheduled(fixedRate = 5 * 60 * 1000)
    public void autoVoidExpiredConfirmations() {
        List<Auction> expiredList = auctionRepository.findExpiredConfirmingAuctions(LocalDateTime.now());

        for (Auction auction : expiredList) {
            try {
                String fromStatus = auction.getStatus();
                auction.setStatus("VOIDED");
                auctionRepository.save(auction);

                recordLog(auction, "VOID", fromStatus, "VOIDED", null, "系统",
                        "确认超时自动废选：超过48小时未双方确认", null);

                // 退还所有押金
                refundAllPaidDeposits(auction.getId(), "确认超时自动废选,退还押金");

                notifySignedUpSuppliers(auction, "拍卖确认超时",
                        "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName()
                                + " 因超过48小时确认期限未完成双方确认，已自动废选。");

                pushAuctionStatusUpdate(auction, "AUCTION_VOIDED");
                log.info("拍卖确认超时自动废选: auctionNo={}, confirmDeadline={}",
                        auction.getAuctionNo(), auction.getConfirmDeadline());
            } catch (Exception e) {
                log.error("拍卖确认超时自动废选失败: auctionId={}, error={}", auction.getId(), e.getMessage());
            }
        }
    }

    /**
     * 每10分钟扫描一次，将报名截止后仍为PENDING状态的邀请自动标记为EXPIRED。
     * 逻辑：找出报名已截止的拍卖，将其下所有PENDING邀请设为EXPIRED。
     */
    @Transactional
    @Scheduled(fixedRate = 10 * 60 * 1000)
    public void autoExpireInvitations() {
        List<Auction> expiredSignupAuctions = auctionRepository.findAuctionsWithExpiredSignup(LocalDateTime.now());

        for (Auction auction : expiredSignupAuctions) {
            try {
                List<AuctionInvitation> pendingInvitations =
                        invitationRepository.findByAuctionIdAndStatus(auction.getId(), "PENDING");

                if (pendingInvitations.isEmpty()) {
                    continue;
                }

                for (AuctionInvitation invitation : pendingInvitations) {
                    invitation.setStatus("EXPIRED");
                    invitation.setRespondedAt(LocalDateTime.now());
                }
                invitationRepository.saveAll(pendingInvitations);

                log.info("拍卖[{}]报名截止，自动过期{}条待回复邀请",
                        auction.getAuctionNo(), pendingInvitations.size());
            } catch (Exception e) {
                log.error("拍卖邀请自动过期失败: auctionId={}, error={}", auction.getId(), e.getMessage());
            }
        }
    }

    // ========== 结果确认 ==========

    @Override
    @Transactional
    public void buyerConfirm(Long auctionId, Long buyerId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        if (!auction.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }
        if (!"CONFIRMING".equals(auction.getStatus())) {
            throw new RuntimeException("当前状态不允许确认");
        }

        auction.setBuyerConfirmed(true);
        auction.setBuyerConfirmedAt(LocalDateTime.now());

        recordLog(auction, "CONFIRM", "CONFIRMING", null, buyerId, null, "采购商确认结果", null);

        if (Boolean.TRUE.equals(auction.getSupplierConfirmed())) {
            auction.setStatus("CONFIRMED");
            auctionRepository.save(auction);
            generateOrderFromAuction(auction);
            pushAuctionStatusUpdate(auction, "AUCTION_CONFIRMED");
            log.info("拍卖[{}]双方已确认，订单已自动生成", auction.getAuctionNo());
        } else {
            auctionRepository.save(auction);
        }
        log.info("拍卖[{}]采购商已确认结果", auction.getAuctionNo());
    }

    @Override
    @Transactional
    public void supplierConfirm(Long auctionId, Long supplierId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        if (!auction.getWinnerSupplierId().equals(supplierId)) {
            throw new RuntimeException("您不是中标供应商");
        }
        if (!"CONFIRMING".equals(auction.getStatus())) {
            throw new RuntimeException("当前状态不允许确认");
        }

        auction.setSupplierConfirmed(true);
        auction.setSupplierConfirmedAt(LocalDateTime.now());

        recordLog(auction, "CONFIRM", "CONFIRMING", null, supplierId, auction.getWinnerCompany(),
                "供应商确认结果", null);

        if (Boolean.TRUE.equals(auction.getBuyerConfirmed())) {
            auction.setStatus("CONFIRMED");
            auctionRepository.save(auction);
            generateOrderFromAuction(auction);
            pushAuctionStatusUpdate(auction, "AUCTION_CONFIRMED");
            log.info("拍卖[{}]双方已确认，订单已自动生成", auction.getAuctionNo());
        } else {
            auctionRepository.save(auction);
        }
        log.info("拍卖[{}]供应商已确认结果", auction.getAuctionNo());
    }

    // ========== 拒绝确认 ==========

    @Override
    @Transactional
    public void buyerReject(Long auctionId, Long buyerId, String reason) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        if (!auction.getBuyerId().equals(buyerId)) {
            throw new RuntimeException("无权操作此拍卖");
        }
        if (!"CONFIRMING".equals(auction.getStatus())) {
            throw new RuntimeException("当前状态不允许拒绝");
        }

        auction.setStatus("VOIDED");
        auctionRepository.save(auction);

        recordLog(auction, "REJECT", "CONFIRMING", "VOIDED", buyerId, null,
                "采购商拒绝确认结果" + (reason != null ? ", 原因: " + reason : ""), null);

        refundAllPaidDeposits(auctionId, "采购商拒绝确认,退还押金");

        notifySignedUpSuppliers(auction, "拍卖结果已被否决",
                "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName()
                        + " 采购商已否决竞价结果，拍卖废选。" + (reason != null ? "原因: " + reason : ""));

        pushAuctionStatusUpdate(auction, "AUCTION_VOIDED");
        log.info("拍卖[{}]采购商拒绝确认，已废选", auction.getAuctionNo());
    }

    @Override
    @Transactional
    public void supplierReject(Long auctionId, Long supplierId, String reason) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));
        if (!auction.getWinnerSupplierId().equals(supplierId)) {
            throw new RuntimeException("您不是中标供应商");
        }
        if (!"CONFIRMING".equals(auction.getStatus())) {
            throw new RuntimeException("当前状态不允许拒绝");
        }

        auction.setStatus("VOIDED");
        auctionRepository.save(auction);

        recordLog(auction, "REJECT", "CONFIRMING", "VOIDED", supplierId, auction.getWinnerCompany(),
                "中标供应商拒绝确认" + (reason != null ? ", 原因: " + reason : ""), null);

        refundAllPaidDeposits(auctionId, "中标供应商拒绝确认,退还押金");

        // 通知采购商
        try {
            MessageRequest msgReq = new MessageRequest();
            msgReq.setReceiverId(auction.getBuyerId());
            msgReq.setTitle("中标供应商拒绝确认");
            msgReq.setContent("拍卖[" + auction.getAuctionNo() + "]中标供应商 " + auction.getWinnerCompany()
                    + " 已拒绝确认结果，拍卖废选。" + (reason != null ? "原因: " + reason : "")
                    + " 您可以选择重新拍卖。");
            msgReq.setType("AUCTION_REJECTED");
            messageService.sendMessage(0L, msgReq);
        } catch (Exception e) {
            log.warn("通知采购商供应商拒绝确认失败: {}", e.getMessage());
        }

        pushAuctionStatusUpdate(auction, "AUCTION_VOIDED");
        log.info("拍卖[{}]中标供应商拒绝确认，已废选", auction.getAuctionNo());
    }

    // ========== 拍卖-订单状态同步 ==========

    @Override
    @Transactional
    public void syncAuctionStatusFromOrder(Long orderId, String orderStatus) {
        auctionRepository.findByOrderId(orderId)
                .ifPresent(auction -> {
                    String fromStatus = auction.getStatus();
                    String newStatus = null;

                    switch (orderStatus) {
                        case "SHIPPED":
                            if ("CONFIRMED".equals(fromStatus)) {
                                newStatus = "DELIVERING";
                            }
                            break;
                        case "COMPLETED":
                            if ("DELIVERING".equals(fromStatus) || "CONFIRMED".equals(fromStatus)) {
                                newStatus = "COMPLETED";
                            }
                            break;
                        case "CANCELLED":
                            if ("CONFIRMED".equals(fromStatus) || "DELIVERING".equals(fromStatus)) {
                                newStatus = "VOIDED";
                            }
                            break;
                    }

                    if (newStatus != null) {
                        auction.setStatus(newStatus);
                        auctionRepository.save(auction);
                        recordLog(auction, "STATUS_SYNC", fromStatus, newStatus, null, "系统",
                                "拍卖状态跟随订单同步: 订单状态=" + orderStatus, null);
                        log.info("拍卖[{}]状态同步: {} → {}，订单状态: {}",
                                auction.getAuctionNo(), fromStatus, newStatus, orderStatus);
                    }
                });
    }

    // ========== 供应商排名查询 ==========

    @Override
    public Map<String, Object> getMyBidRanking(Long auctionId, Long supplierId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("auctionId", auctionId);
        result.put("supplierId", supplierId);

        // 获取供应商最低出价
        List<AuctionBid> myBids = bidRepository.findByAuctionIdAndSupplierIdOrderByCreatedAtDesc(auctionId, supplierId);
        if (myBids.isEmpty()) {
            result.put("hasBid", false);
            result.put("ranking", null);
            result.put("totalBidders", bidRepository.countDistinctSuppliersByAuctionId(auctionId));
            return result;
        }

        AuctionBid myLowestBid = myBids.stream()
                .min(Comparator.comparing(AuctionBid::getBidPrice))
                .get();

        result.put("hasBid", true);
        result.put("myLowestPrice", myLowestBid.getBidPrice());
        result.put("myBidCount", myBids.size());

        // 计算排名（按最低价）
        List<AuctionBid> allBids = bidRepository.findByAuctionIdOrderByBidPriceAsc(auctionId);
        // 按供应商分组，取每个供应商的最低价
        Map<Long, BigDecimal> supplierLowestPrices = new LinkedHashMap<>();
        for (AuctionBid bid : allBids) {
            supplierLowestPrices.merge(bid.getSupplierId(), bid.getBidPrice(), BigDecimal::min);
        }

        // 排序计算排名
        List<Map.Entry<Long, BigDecimal>> sorted = supplierLowestPrices.entrySet().stream()
                .sorted(Map.Entry.comparingByValue())
                .collect(Collectors.toList());

        int ranking = 1;
        for (Map.Entry<Long, BigDecimal> entry : sorted) {
            if (entry.getKey().equals(supplierId)) {
                break;
            }
            ranking++;
        }

        result.put("ranking", ranking);
        result.put("totalBidders", sorted.size());

        // 仅在允许查看最低价时返回
        if (Boolean.TRUE.equals(auction.getShowLowestPrice())) {
            result.put("currentLowestPrice", auction.getCurrentLowestPrice());
        }
        if (Boolean.TRUE.equals(auction.getShowRanking())) {
            result.put("rankingVisible", true);
        } else {
            result.put("rankingVisible", false);
            result.put("ranking", null); // 不允许查看排名时隐藏
        }

        return result;
    }

    @Override
    public Map<String, Object> getMyAuctionStatus(Long auctionId, Long userId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        Map<String, Object> status = new LinkedHashMap<>();
        status.put("auctionId", auctionId);
        status.put("userId", userId);

        // 是否为采购商（发布者）
        boolean isBuyer = userId.equals(auction.getBuyerId());
        status.put("isBuyer", isBuyer);

        // 是否为中标供应商
        boolean isWinner = userId.equals(auction.getWinnerSupplierId());
        status.put("isWinner", isWinner);

        // 报名状态
        boolean hasSignup = signupRepository.existsByAuctionIdAndSupplierId(auctionId, userId);
        status.put("hasSignup", hasSignup);

        if (hasSignup) {
            signupRepository.findByAuctionIdAndSupplierId(auctionId, userId)
                    .ifPresent(signup -> {
                        status.put("signupStatus", signup.getStatus());
                        status.put("signupApproved", "APPROVED".equals(signup.getStatus()));
                    });
        }

        // 出价统计
        List<AuctionBid> myBids = bidRepository.findByAuctionIdAndSupplierIdOrderByCreatedAtDesc(auctionId, userId);
        status.put("hasBid", !myBids.isEmpty());
        status.put("bidCount", myBids.size());
        if (!myBids.isEmpty()) {
            BigDecimal myLowest = myBids.stream()
                    .min(Comparator.comparing(AuctionBid::getBidPrice))
                    .get().getBidPrice();
            status.put("myLowestPrice", myLowest);
        }

        // 押金状态
        boolean hasDeposit = auctionDepositRepo
                .existsByAuctionIdAndUserIdAndStatusIn(auctionId, userId, List.of("PAID"));
        status.put("hasDeposit", hasDeposit);

        // 确认状态
        status.put("buyerConfirmed", auction.getBuyerConfirmed());
        status.put("supplierConfirmed", auction.getSupplierConfirmed());
        status.put("confirmDeadline", auction.getConfirmDeadline());

        // 邀请状态
        invitationRepository.findByAuctionIdAndSupplierId(auctionId, userId)
                .ifPresent(inv -> {
                    status.put("hasInvitation", true);
                    status.put("invitationStatus", inv.getStatus());
                });

        // 关联订单/合同
        status.put("orderId", auction.getOrderId());
        status.put("contractId", auction.getContractId());

        return status;
    }

    private void generateOrderFromAuction(Auction auction) {
        // 1. 先生成合同
        ContractCreateRequest contractRequest = new ContractCreateRequest();
        contractRequest.setAuctionId(auction.getId());
        contractRequest.setSupplierId(auction.getWinnerSupplierId());
        contractRequest.setContractType("PURCHASE");
        contractRequest.setContractTitle("拍卖采购合同 - " + auction.getProductName());
        contractRequest.setTotalAmount(auction.getWinningPrice().multiply(new BigDecimal(auction.getQuantity())));
        contractRequest.setCurrency(auction.getCurrency());
        contractRequest.setDeliveryDate(auction.getRequiredDeliveryDate());
        contractRequest.setRemark("由拍卖[" + auction.getAuctionNo() + "]自动生成");

        ContractResponse contractResponse = contractService.createContract(auction.getBuyerId(), contractRequest);
        auction.setContractId(contractResponse.getId());

        recordLog(auction, "CONTRACT_GENERATE", "CONFIRMED", "CONFIRMED", null, "系统",
                "自动生成合同: " + contractResponse.getContractNo(), null);
        log.info("拍卖[{}]自动生成合同[{}]", auction.getAuctionNo(), contractResponse.getContractNo());

        // 2. 再生成订单
        OrderCreateRequest.OrderItemRequest itemRequest = new OrderCreateRequest.OrderItemRequest();
        itemRequest.setProductName(auction.getProductName());
        itemRequest.setPrice(auction.getWinningPrice());
        itemRequest.setQuantity(auction.getQuantity());
        itemRequest.setUnit(auction.getUnit());

        OrderCreateRequest orderRequest = new OrderCreateRequest();
        orderRequest.setSupplierId(auction.getWinnerSupplierId());
        orderRequest.setShippingAddress(auction.getDeliveryAddress());
        orderRequest.setRemark("由拍卖[" + auction.getAuctionNo() + "]自动生成，关联合同: " + contractResponse.getContractNo());
        orderRequest.setItems(java.util.List.of(itemRequest));

        OrderResponse orderResponse = orderService.createOrder(auction.getBuyerId(), orderRequest);
        auction.setOrderId(orderResponse.getId());
        auctionRepository.save(auction);

        recordLog(auction, "ORDER_GENERATE", "CONFIRMED", "CONFIRMED", null, "系统",
                "自动生成订单: " + orderResponse.getOrderNo(), null);

        log.info("拍卖[{}]自动生成订单[{}], 金额={}",
                auction.getAuctionNo(), orderResponse.getOrderNo(), auction.getWinningPrice());

        // 通知双方订单和合同已生成
        notifyBothPartiesOrderGenerated(auction, contractResponse.getContractNo(), orderResponse.getOrderNo());
    }

    /**
     * 双方确认后，通知采购商和中标供应商订单/合同已自动生成
     */
    private void notifyBothPartiesOrderGenerated(Auction auction, String contractNo, String orderNo) {
        String baseMsg = "拍卖[" + auction.getAuctionNo() + "] " + auction.getProductName()
                + " 双方已确认结果，系统已自动生成合同(" + contractNo + ")和订单(" + orderNo + ")。";
        try {
            MessageRequest buyerMsg = new MessageRequest();
            buyerMsg.setReceiverId(auction.getBuyerId());
            buyerMsg.setTitle("拍卖订单已生成");
            buyerMsg.setContent(baseMsg + "请尽快完成支付，推动订单履约。");
            buyerMsg.setType("AUCTION_ORDER_GENERATED");
            messageService.sendMessage(0L, buyerMsg);
        } catch (Exception e) {
            log.warn("通知采购商订单生成失败: {}", e.getMessage());
        }
        try {
            MessageRequest supplierMsg = new MessageRequest();
            supplierMsg.setReceiverId(auction.getWinnerSupplierId());
            supplierMsg.setTitle("拍卖订单已生成");
            supplierMsg.setContent(baseMsg + "请关注订单状态，等待采购商付款后安排发货。");
            supplierMsg.setType("AUCTION_ORDER_GENERATED");
            messageService.sendMessage(0L, supplierMsg);
        } catch (Exception e) {
            log.warn("通知供应商订单生成失败: {}", e.getMessage());
        }
    }

    // ========== 操作日志 ==========

    private void recordLog(Auction auction, String operationType, String fromStatus, String toStatus,
                           Long operatorId, String operatorName, String detail, String ipAddress) {
        AuctionOperationLog logEntry = AuctionOperationLog.builder()
                .auctionId(auction.getId())
                .auctionNo(auction.getAuctionNo())
                .operationType(operationType)
                .fromStatus(fromStatus)
                .toStatus(toStatus)
                .operatorId(operatorId)
                .operatorName(operatorName)
                .detail(detail)
                .ipAddress(ipAddress)
                .build();
        operationLogRepository.save(logEntry);
    }

    /** 退还拍卖关联的所有已缴纳押金 */
    private void refundAllPaidDeposits(Long auctionId, String reason) {
        List<AuctionDeposit> paidDeposits = auctionDepositRepo.findByAuctionIdAndStatus(auctionId, "PAID");
        for (AuctionDeposit deposit : paidDeposits) {
            deposit.setStatus("REFUNDED");
            deposit.setRefundedAt(java.time.LocalDateTime.now());
            deposit.setRefundReason(reason);
            auctionDepositRepo.save(deposit);
        }
        if (!paidDeposits.isEmpty()) {
            log.info("退还拍卖[{}]押金{}笔, 原因: {}", auctionId, paidDeposits.size(), reason);
        }
    }

    // ========== 管理员方法 ==========

    @Override
    public Page<AuctionResponse> getAllAuctions(String status, Pageable pageable) {
        Page<Auction> auctions;
        if (status != null && !status.isBlank()) {
            auctions = auctionRepository.findByStatusOrderByCreatedAtDesc(status.toUpperCase(), pageable);
        } else {
            auctions = auctionRepository.findAllByOrderByCreatedAtDesc(pageable);
        }
        return auctions.map(this::convertToResponse);
    }

    @Override
    @Transactional
    public AuctionResponse approveAuction(Long auctionId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        if (!"PENDING_APPROVAL".equals(auction.getStatus()) && !"DRAFT".equals(auction.getStatus())) {
            throw new RuntimeException("只有待审核状态的拍卖可以审核通过，当前状态: " + auction.getStatus());
        }

        String fromStatus = auction.getStatus();
        LocalDateTime now = LocalDateTime.now();
        auction.setApprovedAt(now);

        if (auction.getSignupStartTime() != null) {
            if (auction.getSignupStartTime().isBefore(now) || auction.getSignupStartTime().isEqual(now)) {
                auction.setStatus("SIGNUP");
            } else {
                auction.setStatus("APPROVED");
            }
        } else {
            if (auction.getStartTime().isBefore(now) || auction.getStartTime().isEqual(now)) {
                auction.setStatus("ACTIVE");
            } else {
                auction.setStatus("PENDING");
            }
        }

        auction = auctionRepository.save(auction);

        recordLog(auction, "APPROVE", fromStatus, auction.getStatus(), null, "管理员", "审核通过", null);

        log.info("拍卖[{}]审核通过，状态: {}", auction.getAuctionNo(), auction.getStatus());
        return convertToResponse(auction);
    }

    @Override
    @Transactional
    public void rejectAuction(Long auctionId, String reason) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new RuntimeException("拍卖不存在"));

        String status = auction.getStatus();
        if (!"PENDING_APPROVAL".equals(status) && !"DRAFT".equals(status) && !"APPROVED".equals(status)) {
            throw new RuntimeException("当前状态不允许驳回，当前状态: " + status);
        }

        String fromStatus = auction.getStatus();
        auction.setStatus("CANCELLED");
        auction.setApprovalRemark(reason);
        auctionRepository.save(auction);

        recordLog(auction, "REJECT", fromStatus, "CANCELLED", null, "管理员",
                "驳回原因: " + reason, null);

        // 退还采购商押金
        refundAllPaidDeposits(auctionId, "拍卖被驳回,自动退还押金");

        log.info("拍卖[{}]被驳回, 原因: {}", auction.getAuctionNo(), reason);
    }

    @Override
    public Map<String, Object> getAuctionStats() {
        Map<String, Object> stats = new HashMap<>();

        Map<String, Long> statusCounts = new HashMap<>();
        List<Object[]> countResults = auctionRepository.countByStatus();
        long totalCount = 0;
        for (Object[] row : countResults) {
            String status = (String) row[0];
            Long count = (Long) row[1];
            statusCounts.put(status, count);
            totalCount += count;
        }
        stats.put("statusCounts", statusCounts);
        stats.put("totalCount", totalCount);
        stats.put("pendingApprovalCount", statusCounts.getOrDefault("PENDING_APPROVAL", 0L)
                + statusCounts.getOrDefault("DRAFT", 0L));
        stats.put("signupCount", statusCounts.getOrDefault("SIGNUP", 0L));
        stats.put("activeCount", statusCounts.getOrDefault("ACTIVE", 0L));
        stats.put("confirmingCount", statusCounts.getOrDefault("CONFIRMING", 0L));
        stats.put("endedCount", statusCounts.getOrDefault("ENDED", 0L)
                + statusCounts.getOrDefault("CONFIRMED", 0L)
                + statusCounts.getOrDefault("COMPLETED", 0L));
        stats.put("failedCount", statusCounts.getOrDefault("FAILED", 0L));
        stats.put("voidedCount", statusCounts.getOrDefault("VOIDED", 0L));
        stats.put("totalBidCount", auctionRepository.sumBidCount());
        stats.put("totalParticipantCount", auctionRepository.sumParticipantCount());

        BigDecimal totalWinningPrice = auctionRepository.sumWinningPrice();
        stats.put("totalWinningPrice", totalWinningPrice != null ? totalWinningPrice : BigDecimal.ZERO);

        return stats;
    }

    // ========== 转换方法 ==========

    private void validateCreateRequest(AuctionCreateRequest request) {
        if (request == null) {
            throw new BusinessException(400, "竞价需求不能为空");
        }
        if (request.getStartTime() == null || request.getEndTime() == null
                || !request.getEndTime().isAfter(request.getStartTime())) {
            throw new BusinessException(400, "竞价结束时间必须晚于开始时间");
        }
        if (request.getSignupStartTime() != null && request.getSignupEndTime() != null
                && request.getSignupEndTime().isBefore(request.getSignupStartTime())) {
            throw new BusinessException(400, "报名截止时间不能早于报名开始时间");
        }
        if (request.getSignupEndTime() != null && request.getSignupEndTime().isAfter(request.getStartTime())) {
            throw new BusinessException(400, "报名截止时间不能晚于竞价开始时间");
        }
        if (request.getStartingPrice() == null || request.getStartingPrice().signum() <= 0) {
            throw new BusinessException(400, "最高单价必须大于0");
        }
        BigDecimal decrement = request.getMinDecrement() == null ? new BigDecimal("1.00") : request.getMinDecrement();
        if (decrement.signum() <= 0 || decrement.compareTo(request.getStartingPrice()) >= 0) {
            throw new BusinessException(400, "最低降价幅度必须大于0且小于最高单价");
        }
        if (request.getReservePrice() != null
                && (request.getReservePrice().signum() < 0
                || request.getReservePrice().compareTo(request.getStartingPrice()) > 0)) {
            throw new BusinessException(400, "隐藏底价不能小于0或高于最高单价");
        }
        String currency = request.getCurrency() == null ? "USD" : request.getCurrency().toUpperCase(Locale.ROOT);
        if (!SUPPORTED_CURRENCIES.contains(currency)) {
            throw new BusinessException(400, "不支持的报价币种");
        }
        if (Boolean.TRUE.equals(request.getScoringEnabled())) {
            int weightTotal = intValue(request.getPriceWeight(), 0)
                    + intValue(request.getDeliveryWeight(), 0)
                    + intValue(request.getQualityWeight(), 0)
                    + intValue(request.getServiceWeight(), 0);
            if (weightTotal != 100) {
                throw new BusinessException(400, "综合评分权重之和必须为100");
            }
        }
    }

    private void ensurePublicAuction(Long auctionId) {
        Auction auction = auctionRepository.findById(auctionId)
                .orElseThrow(() -> new BusinessException(404, "竞价不存在"));
        if (!PUBLIC_AUCTION_STATUSES.contains(auction.getStatus())) {
            throw new BusinessException(404, "竞价不存在或尚未公开");
        }
    }

    private int intValue(Integer value, int defaultValue) {
        return value == null ? defaultValue : value;
    }

    private AuctionResponse convertToPublicResponse(Auction auction) {
        AuctionResponse response = convertToResponse(auction);
        response.setBuyerId(null);
        response.setReservePrice(null);
        response.setShowReservePrice(false);
        response.setReferenceSource(null);
        response.setApproverId(null);
        response.setApprovalRemark(null);
        response.setWinnerSupplierId(null);
        response.setWinnerCompany(null);
        response.setBuyerConfirmed(null);
        response.setBuyerConfirmedAt(null);
        response.setSupplierConfirmed(null);
        response.setSupplierConfirmedAt(null);
        response.setOrderId(null);
        response.setContractId(null);
        return response;
    }

    private Map<Long, String> buildPublicSupplierAliases(List<AuctionBid> bids) {
        SortedSet<Long> supplierIds = bids.stream()
                .map(AuctionBid::getSupplierId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(TreeSet::new));
        Map<Long, String> aliases = new HashMap<>();
        int index = 0;
        for (Long supplierId : supplierIds) {
            String suffix = index < 26 ? String.valueOf((char) ('A' + index)) : String.valueOf(index + 1);
            aliases.put(supplierId, "匿名供应商 " + suffix);
            index++;
        }
        return aliases;
    }

    private AuctionResponse.BidResponse convertToPublicBidResponse(AuctionBid bid, String alias) {
        return AuctionResponse.BidResponse.builder()
                .supplierCompany(alias)
                .bidPrice(bid.getBidPrice())
                .totalAmount(bid.getTotalAmount())
                .promisedDeliveryDays(bid.getPromisedDeliveryDays())
                .bidSequence(bid.getBidSequence())
                .isLowest(bid.getIsLowest())
                .isWinner(false)
                .createdAt(bid.getCreatedAt())
                .build();
    }

    private AuctionResponse convertToResponse(Auction auction) {
        LocalDateTime now = LocalDateTime.now();
        long remainingSeconds = 0;
        boolean canBid = false;
        boolean canSignup = false;
        String status = auction.getStatus();

        if ("ACTIVE".equals(status) && auction.getEndTime().isAfter(now)) {
            remainingSeconds = ChronoUnit.SECONDS.between(now, auction.getEndTime());
            canBid = true;
        } else if ("SIGNUP".equals(status) || "APPROVED".equals(status)) {
            if (auction.getSignupEndTime() != null && auction.getSignupEndTime().isAfter(now)) {
                remainingSeconds = ChronoUnit.SECONDS.between(now, auction.getSignupEndTime());
                canSignup = true;
            } else if (auction.getStartTime().isAfter(now)) {
                remainingSeconds = ChronoUnit.SECONDS.between(now, auction.getStartTime());
            }
        } else if ("PENDING".equals(status) && auction.getStartTime().isAfter(now)) {
            remainingSeconds = ChronoUnit.SECONDS.between(now, auction.getStartTime());
        }

        String auctionTypeText = switch (auction.getAuctionType() != null ? auction.getAuctionType() : "REVERSE_AUCTION") {
            case "REVERSE_AUCTION" -> "反向拍卖";
            case "TENDER" -> "招标";
            case "INQUIRY" -> "询比价";
            default -> auction.getAuctionType();
        };

        String statusText = switch (status) {
            case "DRAFT" -> "草稿";
            case "PENDING_APPROVAL" -> "待审核";
            case "APPROVED" -> "已审核";
            case "SIGNUP" -> "报名中";
            case "PENDING" -> "待开始";
            case "ACTIVE" -> "竞价中";
            case "CONFIRMING" -> "待确认";
            case "CONFIRMED" -> "已确认";
            case "DELIVERING" -> "履约中";
            case "COMPLETED" -> "已完成";
            case "ENDED" -> "已结束";
            case "CANCELLED" -> "已取消";
            case "FAILED" -> "已流标";
            case "VOIDED" -> "已废选";
            default -> status;
        };

        return AuctionResponse.builder()
                .id(auction.getId())
                .auctionNo(auction.getAuctionNo())
                .auctionType(auction.getAuctionType())
                .auctionTypeText(auctionTypeText)
                .currency(auction.getCurrency())
                .buyerId(auction.getBuyerId())
                .buyerCompany(auction.getBuyerCompany())
                .productName(auction.getProductName())
                .productCategory(auction.getProductCategory())
                .specification(auction.getSpecification())
                .quantity(auction.getQuantity())
                .unit(auction.getUnit())
                .startingPrice(auction.getStartingPrice())
                .currentLowestPrice(auction.getCurrentLowestPrice())
                .minDecrement(auction.getMinDecrement())
                .reservePrice(Boolean.TRUE.equals(auction.getShowReservePrice()) ? auction.getReservePrice() : null)
                .showReservePrice(auction.getShowReservePrice())
                .referencePrice(auction.getReferencePrice())
                .referenceSource(auction.getReferenceSource())
                .inviteOnly(auction.getInviteOnly())
                .bidCooldownSeconds(auction.getBidCooldownSeconds())
                // 报名
                .signupStartTime(auction.getSignupStartTime())
                .signupEndTime(auction.getSignupEndTime())
                .signupCount(auction.getSignupCount())
                // 竞价
                .startTime(auction.getStartTime())
                .endTime(auction.getEndTime())
                .originalEndTime(auction.getOriginalEndTime())
                // 规则
                .minParticipants(auction.getMinParticipants())
                .extensionMinutes(auction.getExtensionMinutes())
                .extensionTriggerMinutes(auction.getExtensionTriggerMinutes())
                .maxExtensions(auction.getMaxExtensions())
                .currentExtensions(auction.getCurrentExtensions())
                .showRanking(auction.getShowRanking())
                .showLowestPrice(auction.getShowLowestPrice())
                // 评分
                .scoringEnabled(auction.getScoringEnabled())
                .priceWeight(auction.getPriceWeight())
                .deliveryWeight(auction.getDeliveryWeight())
                .qualityWeight(auction.getQualityWeight())
                .serviceWeight(auction.getServiceWeight())
                // 状态
                .status(status)
                .statusText(statusText)
                .approverId(auction.getApproverId())
                .approvedAt(auction.getApprovedAt())
                .approvalRemark(auction.getApprovalRemark())
                // 中标
                .winnerSupplierId(auction.getWinnerSupplierId())
                .winnerCompany(auction.getWinnerCompany())
                .winningPrice(auction.getWinningPrice())
                .bidCount(auction.getBidCount())
                .participantCount(auction.getParticipantCount())
                // 确认
                .confirmDeadline(auction.getConfirmDeadline())
                .buyerConfirmed(auction.getBuyerConfirmed())
                .buyerConfirmedAt(auction.getBuyerConfirmedAt())
                .supplierConfirmed(auction.getSupplierConfirmed())
                .supplierConfirmedAt(auction.getSupplierConfirmedAt())
                // 订单
                .orderId(auction.getOrderId())
                .contractId(auction.getContractId())
                // 交付
                .deliveryAddress(auction.getDeliveryAddress())
                .requiredDeliveryDate(auction.getRequiredDeliveryDate())
                .paymentTerms(auction.getPaymentTerms())
                .remark(auction.getRemark())
                .coverImage(auction.getCoverImage())
                .attachments(auction.getAttachments())
                .createdAt(auction.getCreatedAt())
                .remainingSeconds(remainingSeconds)
                .canBid(canBid)
                .canSignup(canSignup)
                .build();
    }

    private AuctionResponse.BidResponse convertToBidResponse(AuctionBid bid) {
        return AuctionResponse.BidResponse.builder()
                .id(bid.getId())
                .supplierId(bid.getSupplierId())
                .supplierCompany(bid.getSupplierCompany())
                .bidPrice(bid.getBidPrice())
                .totalAmount(bid.getTotalAmount())
                .promisedDeliveryDays(bid.getPromisedDeliveryDays())
                .bidSequence(bid.getBidSequence())
                .isLowest(bid.getIsLowest())
                .isWinner(bid.getIsWinner())
                .createdAt(bid.getCreatedAt())
                .build();
    }

    private AuctionResponse.SignupResponse convertToSignupResponse(AuctionSignup signup) {
        return AuctionResponse.SignupResponse.builder()
                .id(signup.getId())
                .supplierId(signup.getSupplierId())
                .supplierCompany(signup.getSupplierCompany())
                .contactName(signup.getContactName())
                .contactPhone(signup.getContactPhone())
                .status(signup.getStatus())
                .hasBid(signup.getHasBid())
                .bidCount(signup.getBidCount())
                .auditRemark(signup.getAuditRemark())
                .createdAt(signup.getCreatedAt())
                .build();
    }

    private AuctionResponse.InvitationResponse convertToInvitationResponse(AuctionInvitation invitation) {
        return AuctionResponse.InvitationResponse.builder()
                .id(invitation.getId())
                .supplierId(invitation.getSupplierId())
                .supplierCompany(invitation.getSupplierCompany())
                .inviteMessage(invitation.getInviteMessage())
                .status(invitation.getStatus())
                .respondedAt(invitation.getRespondedAt())
                .createdAt(invitation.getCreatedAt())
                .build();
    }

    private AuctionResponse.ScoreResponse convertToScoreResponse(AuctionSupplierScore score) {
        return AuctionResponse.ScoreResponse.builder()
                .id(score.getId())
                .supplierId(score.getSupplierId())
                .supplierCompany(score.getSupplierCompany())
                .priceScore(score.getPriceScore())
                .deliveryScore(score.getDeliveryScore())
                .qualityScore(score.getQualityScore())
                .serviceScore(score.getServiceScore())
                .totalScore(score.getTotalScore())
                .ranking(score.getRanking())
                .build();
    }

    private AuctionResponse.OperationLogResponse convertToLogResponse(AuctionOperationLog logEntry) {
        return AuctionResponse.OperationLogResponse.builder()
                .id(logEntry.getId())
                .operationType(logEntry.getOperationType())
                .fromStatus(logEntry.getFromStatus())
                .toStatus(logEntry.getToStatus())
                .operatorName(logEntry.getOperatorName())
                .detail(logEntry.getDetail())
                .createdAt(logEntry.getCreatedAt())
                .build();
    }
}
