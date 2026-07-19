package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * 模拟支付网关（开发/测试阶段使用）
 * 所有操作直接返回成功，第三方接入后替换为真实网关
 */
@Slf4j
@Primary
@Component
@Profile("h2")
public class MockPaymentGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "MOCK";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        String txId = "MOCK_TX_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        log.info("[MockGateway] 模拟支付成功: paymentNo={}, amount={}, txId={}", request.getPaymentNo(), request.getAmount(), txId);
        return GatewayPayResult.builder()
                .success(true)
                .transactionId(txId)
                .message("模拟支付成功")
                .build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        log.info("[MockGateway] 模拟查询状态: txId={}", transactionId);
        return GatewayQueryResult.builder()
                .success(true)
                .status("SUCCESS")
                .transactionId(transactionId)
                .message("模拟查询成功")
                .build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        String txId = "MOCK_REF_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        log.info("[MockGateway] 模拟退款成功: refundNo={}, amount={}, txId={}", request.getRefundNo(), request.getRefundAmount(), txId);
        return GatewayRefundResult.builder()
                .success(true)
                .transactionId(txId)
                .message("模拟退款成功")
                .build();
    }
}
