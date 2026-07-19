package com.yicai.trade.module.payment.gateway;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class GatewayRefundRequest {
    private String refundNo;
    private String originalTransactionId;
    private BigDecimal refundAmount;
    private String currency;
    private String reason;
    private String notifyUrl;
}
