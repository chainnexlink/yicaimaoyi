package com.yicai.trade.module.payment.gateway;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class GatewayPayRequest {
    private String paymentNo;
    private BigDecimal amount;
    private String currency;
    private String subject;
    private String bankAccount;
    private String bankName;
    private String notifyUrl;
}
