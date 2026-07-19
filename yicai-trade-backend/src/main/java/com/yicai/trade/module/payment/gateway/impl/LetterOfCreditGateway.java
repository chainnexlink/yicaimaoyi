package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 信用证 (Letter of Credit / L/C) 网关
 * 国际贸易中的重要支付方式，通过银行信用担保
 * 流程: 开证 -> 交单 -> 审单 -> 付款
 */
@Slf4j
@Component
public class LetterOfCreditGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "LETTER_OF_CREDIT";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        log.info("[L/C] 信用证支付请求: paymentNo={}, amount={}", request.getPaymentNo(), request.getAmount());

        return GatewayPayResult.builder()
                .success(false)
                .message("信用证网关尚未接入")
                .build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        log.info("[L/C] 查询信用证状态: {}", transactionId);
        return GatewayQueryResult.builder()
                .success(false)
                .status("UNAVAILABLE")
                .message("信用证网关尚未接入")
                .build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        log.info("[L/C] 信用证退款/修改: {}", request.getOriginalTransactionId());
        return GatewayRefundResult.builder()
                .success(false)
                .message("信用证退款网关尚未接入")
                .build();
    }
}
