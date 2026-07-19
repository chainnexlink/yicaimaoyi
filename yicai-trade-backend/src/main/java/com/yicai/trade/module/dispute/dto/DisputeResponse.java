package com.yicai.trade.module.dispute.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class DisputeResponse {
    private Long id;
    private String disputeNo;
    private Long orderId;
    private String orderNo;
    private Long aftersaleId;
    private Long initiatorId;
    private String initiatorRole;
    private Long respondentId;
    private String respondentRole;
    private String disputeType;
    private String severity;
    private String description;
    private String evidenceUrls;
    private BigDecimal claimAmount;
    private BigDecimal awardedAmount;
    private String rulingType;
    private String rulingReason;
    private Long assignedTo;
    private String status;
    private LocalDateTime ruledAt;
    private LocalDateTime closedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<DisputeMessageResponse> messages;
}
