package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 支付宝支付网关（骨架实现）。
 * 当前为占位实现，接入支付宝SDK后替换各方法内的真实逻辑。
 */
@Slf4j
@Component
public class AlipayGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "ALIPAY";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        // 接入支付宝SDK后调用 alipayClient.pageExecute()
        log.warn("[AlipayGateway] 支付宝尚未接入，使用模拟返回");
        return GatewayPayResult.builder().success(false).message("支付宝尚未接入").build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        // 接入支付宝SDK后调用交易查询接口
        return GatewayQueryResult.builder().success(false).status("NOT_FOUND").message("支付宝尚未接入").build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        // 接入支付宝SDK后调用退款接口
        return GatewayRefundResult.builder().success(false).message("支付宝尚未接入").build();
    }
}
