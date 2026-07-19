package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 电汇 (T/T - Telegraphic Transfer) 网关
 * 跨境贸易最常用的支付方式之一
 * 支持预付T/T (Advance T/T) 和后付T/T (Deferred T/T)
 */
@Slf4j
@Component
public class TelegraphicTransferGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "TT_TRANSFER";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        log.info("[TT] 电汇支付请求: paymentNo={}, amount={}, subject={}",
                request.getPaymentNo(), request.getAmount(), request.getSubject());

        return GatewayPayResult.builder()
                .success(false)
                .message("电汇网关尚未接入，不能自动确认到账")
                .build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        log.info("[TT] 查询电汇状态: {}", transactionId);
        // In production: query bank API or reconciliation system
        return GatewayQueryResult.builder()
                .success(false)
                .status("UNAVAILABLE")
                .message("电汇网关尚未接入")
                .build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        log.info("[TT] 电汇退款: {}", request.getOriginalTransactionId());
        return GatewayRefundResult.builder()
                .success(false)
                .message("电汇退款网关尚未接入")
                .build();
    }
}
