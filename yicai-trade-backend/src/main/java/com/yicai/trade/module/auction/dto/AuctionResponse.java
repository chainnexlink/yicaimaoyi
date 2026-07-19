package com.yicai.trade.module.auction.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 拍卖响应
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuctionResponse {

    private Long id;
    private String auctionNo;
    private String auctionType;
    private String auctionTypeText;
    private String currency;
    private Long buyerId;
    private String buyerCompany;
    private String productName;
    private String productCategory;
    private String specification;
    private Integer quantity;
    private String unit;
    private BigDecimal startingPrice;
    private BigDecimal currentLowestPrice;
    private BigDecimal minDecrement;
    private BigDecimal reservePrice;
    private Boolean showReservePrice;
    private BigDecimal referencePrice;
    private String referenceSource;
    private Boolean inviteOnly;
    private Integer bidCooldownSeconds;

    // ========== 报名时间 ==========
    private LocalDateTime signupStartTime;
    private LocalDateTime signupEndTime;
    private Integer signupCount;

    // ========== 竞价时间 ==========
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private LocalDateTime originalEndTime;

    // ========== 反拍规则 ==========
    private Integer minParticipants;
    private Integer extensionMinutes;
    private Integer extensionTriggerMinutes;
    private Integer maxExtensions;
    private Integer currentExtensions;
    private Boolean showRanking;
    private Boolean showLowestPrice;

    // ========== 综合评分 ==========
    private Boolean scoringEnabled;
    private Integer priceWeight;
    private Integer deliveryWeight;
    private Integer qualityWeight;
    private Integer serviceWeight;

    // ========== 状态信息 ==========
    private String status;
    private String statusText;
    private Long approverId;
    private LocalDateTime approvedAt;
    private String approvalRemark;

    // ========== 中标信息 ==========
    private Long winnerSupplierId;
    private String winnerCompany;
    private BigDecimal winningPrice;
    private Integer bidCount;
    private Integer participantCount;

    // ========== 结果确认 ==========
    private LocalDateTime confirmDeadline;
    private Boolean buyerConfirmed;
    private LocalDateTime buyerConfirmedAt;
    private Boolean supplierConfirmed;
    private LocalDateTime supplierConfirmedAt;

    // ========== 订单关联 ==========
    private Long orderId;
    private Long contractId;

    // ========== 交付信息 ==========
    private String deliveryAddress;
    private LocalDate requiredDeliveryDate;
    private String paymentTerms;
    private String remark;
    private String coverImage;
    private String attachments;
    private LocalDateTime createdAt;
    
    /** 剩余时间(秒) */
    private Long remainingSeconds;
    
    /** 是否可出价(状态=ACTIVE且未结束) */
    private Boolean canBid;

    /** 是否可报名 */
    private Boolean canSignup;

    /** 当前用户是否已报名 */
    private Boolean hasSignup;

    /** 当前用户的排名(如果允许查看) */
    private Integer currentRank;
    
    /** 出价记录(可选加载) */
    private List<BidResponse> bids;

    /** 报名记录(可选加载) */
    private List<SignupResponse> signups;

    /** 邀请记录(可选加载) */
    private List<InvitationResponse> invitations;

    /** 综合评分记录(可选加载) */
    private List<ScoreResponse> scores;

    /** 操作日志(可选加载) */
    private List<OperationLogResponse> operationLogs;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BidResponse {
        private Long id;
        private Long supplierId;
        private String supplierCompany;
        private BigDecimal bidPrice;
        private BigDecimal totalAmount;
        private Integer promisedDeliveryDays;
        private Integer bidSequence;
        private Boolean isLowest;
        private Boolean isWinner;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SignupResponse {
        private Long id;
        private Long supplierId;
        private String supplierCompany;
        private String contactName;
        private String contactPhone;
        private String status;
        private Boolean hasBid;
        private Integer bidCount;
        private String auditRemark;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InvitationResponse {
        private Long id;
        private Long supplierId;
        private String supplierCompany;
        private String inviteMessage;
        private String status;
        private LocalDateTime respondedAt;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ScoreResponse {
        private Long id;
        private Long supplierId;
        private String supplierCompany;
        private BigDecimal priceScore;
        private BigDecimal deliveryScore;
        private BigDecimal qualityScore;
        private BigDecimal serviceScore;
        private BigDecimal totalScore;
        private Integer ranking;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OperationLogResponse {
        private Long id;
        private String operationType;
        private String fromStatus;
        private String toStatus;
        private String operatorName;
        private String detail;
        private LocalDateTime createdAt;
    }
}
