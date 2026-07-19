package com.yicai.trade.module.logistics.dto;

import lombok.Data;

@Data
public class LogisticsRequest {
    private Long orderId;
    private String orderNo;
    private String senderName;
    private String senderAddress;
    private String receiverName;
    private String receiverAddress;
    private String carrier;
    private String remark;
}
