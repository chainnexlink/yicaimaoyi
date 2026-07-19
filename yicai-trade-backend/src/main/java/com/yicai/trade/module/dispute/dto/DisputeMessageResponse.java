package com.yicai.trade.module.dispute.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class DisputeMessageResponse {
    private Long id;
    private Long senderId;
    private String senderRole;
    private String content;
    private String attachmentUrls;
    private String msgType;
    private LocalDateTime createdAt;
}
