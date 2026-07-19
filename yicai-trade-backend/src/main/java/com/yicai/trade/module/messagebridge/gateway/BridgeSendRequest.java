package com.yicai.trade.module.messagebridge.gateway;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BridgeSendRequest {
    private String channelUserId;
    private String title;
    private String content;
    private String messageType;  // SYSTEM / ORDER / INQUIRY etc.
    private Long relatedId;
    private String relatedType;
    private String callbackUrl;
}
