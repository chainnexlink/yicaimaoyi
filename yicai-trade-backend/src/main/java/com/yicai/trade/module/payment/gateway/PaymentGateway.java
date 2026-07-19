package com.yicai.trade.module.payment.gateway;

/**
 * 支付网关策略接口
 * 不同支付方式实现此接口，通过 PaymentGatewayFactory 动态选择
 */
public interface PaymentGateway {

    /** 返回支付方式标识，如 BANK_TRANSFER, ALIPAY, WECHAT, CREDIT */
    String getMethod();

    /** 发起支付 */
    GatewayPayResult pay(GatewayPayRequest request);

    /** 查询支付状态 */
    GatewayQueryResult queryStatus(String transactionId);

    /** 发起退款 */
    GatewayRefundResult refund(GatewayRefundRequest request);
}
