package com.yicai.trade.module.payment.gateway;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GatewayPayResult {
    private boolean success;
    private String transactionId;
    private String message;
    /** 第三方支付链接/二维码（预留） */
    private String payUrl;
}
