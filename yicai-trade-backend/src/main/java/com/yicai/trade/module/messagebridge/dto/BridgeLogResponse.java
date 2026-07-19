package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class BridgeLogResponse {
    private Long id;
    private Long messageId;
    private Long supplierId;
    private String channelType;
    private String direction;
    private String contentSummary;
    private String externalMsgId;
    private String status;
    private String errorMessage;
    private LocalDateTime createdAt;
}
