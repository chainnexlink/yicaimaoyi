package com.yicai.trade.module.dispute.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class DisputeCreateRequest {
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
}
