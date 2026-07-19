package com.yicai.trade.module.aftersale.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class AftersaleCreateRequest {
    private Long orderId;
    private String orderNo;
    private Long buyerId;
    private Long supplierId;
    private String type;       // RETURN, EXCHANGE, REPAIR, REFUND_ONLY
    private String reasonType; // QUALITY, WRONG_ITEM, DAMAGED, MISSING, SPEC_MISMATCH, OTHER
    private String reason;
    private String evidenceUrls; // JSON array
    private BigDecimal refundAmount;
}
