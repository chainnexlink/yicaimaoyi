package com.yicai.trade.module.payment.gateway;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GatewayRefundResult {
    private boolean success;
    private String transactionId;
    private String message;
}
