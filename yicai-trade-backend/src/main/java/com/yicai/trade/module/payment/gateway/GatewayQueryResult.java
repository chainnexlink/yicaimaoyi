package com.yicai.trade.module.payment.gateway;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GatewayQueryResult {
    private boolean success;
    /** 第三方返回的状态：SUCCESS / PROCESSING / FAILED / NOT_FOUND */
    private String status;
    private String transactionId;
    private String message;
}
