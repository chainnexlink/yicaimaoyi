package com.yicai.trade.module.aftersale.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class AftersaleResponse {
    private Long id;
    private String aftersaleNo;
    private Long orderId;
    private String orderNo;
    private Long buyerId;
    private Long supplierId;
    private String type;
    private String reasonType;
    private String reason;
    private String evidenceUrls;
    private BigDecimal refundAmount;
    private String returnTrackingNo;
    private String returnCarrier;
    private String exchangeTrackingNo;
    private String exchangeCarrier;
    private String status;
    private String supplierRemark;
    private String platformRemark;
    private LocalDateTime resolvedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<AftersaleLogResponse> logs;
}
