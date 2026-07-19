package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 微信支付网关（骨架实现）。
 * 当前为占位实现，接入微信支付SDK后替换各方法内的真实逻辑。
 */
@Slf4j
@Component
public class WechatPayGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "WECHAT";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        // 接入微信支付SDK后调用统一下单接口
        log.warn("[WechatPayGateway] 微信支付尚未接入，使用模拟返回");
        return GatewayPayResult.builder().success(false).message("微信支付尚未接入").build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        return GatewayQueryResult.builder().success(false).status("NOT_FOUND").message("微信支付尚未接入").build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        return GatewayRefundResult.builder().success(false).message("微信支付尚未接入").build();
    }
}
