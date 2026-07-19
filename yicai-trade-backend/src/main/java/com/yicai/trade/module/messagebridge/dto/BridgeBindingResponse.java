package com.yicai.trade.module.messagebridge.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class BridgeBindingResponse {
    private Long id;
    private Long supplierId;
    private String channelType;
    private String channelUserId;
    private String channelUsername;
    private String bindStatus;
    private LocalDateTime boundAt;
    private LocalDateTime createdAt;
}
