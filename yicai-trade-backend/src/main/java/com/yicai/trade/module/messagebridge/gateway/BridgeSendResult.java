package com.yicai.trade.module.messagebridge.gateway;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BridgeSendResult {
    private boolean success;
    private String externalMsgId;
    private String message;
}
