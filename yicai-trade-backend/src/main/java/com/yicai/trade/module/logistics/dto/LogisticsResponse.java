package com.yicai.trade.module.logistics.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class LogisticsResponse {
    private Long id;
    private String trackingNo;
    private Long orderId;
    private String orderNo;
    private String senderName;
    private String senderAddress;
    private String receiverName;
    private String receiverAddress;
    private String carrier;
    private String status;
    private LocalDateTime shippedAt;
    private LocalDateTime deliveredAt;
    private String remark;
    private LocalDateTime createdAt;
}
