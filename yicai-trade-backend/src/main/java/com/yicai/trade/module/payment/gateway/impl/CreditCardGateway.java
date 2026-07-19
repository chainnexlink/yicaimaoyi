package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 信用卡 (Credit Card) 网关
 * 支持 Visa / MasterCard / UnionPay 国际信用卡支付
 * 对接 Stripe / Adyen / PayPal 等国际支付处理商
 */
@Slf4j
@Component
public class CreditCardGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "CREDIT_CARD";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        log.info("[CreditCard] 信用卡支付请求: paymentNo={}, amount={}", request.getPaymentNo(), request.getAmount());

        return GatewayPayResult.builder()
                .success(false)
                .message("信用卡支付网关尚未接入")
                .build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        log.info("[CreditCard] 查询信用卡支付状态: {}", transactionId);
        return GatewayQueryResult.builder()
                .success(false)
                .status("UNAVAILABLE")
                .message("信用卡支付网关尚未接入")
                .build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        log.info("[CreditCard] 信用卡退款: {}", request.getOriginalTransactionId());
        return GatewayRefundResult.builder()
                .success(false)
                .message("信用卡退款网关尚未接入")
                .build();
    }
}
