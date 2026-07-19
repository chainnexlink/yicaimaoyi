package com.yicai.trade.module.payment.gateway.impl;

import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 银行转账网关（骨架实现）。
 * 当前为占位实现，对接银企直连或网银接口后替换各方法内的真实逻辑。
 */
@Slf4j
@Component
public class BankTransferGateway implements PaymentGateway {

    @Override
    public String getMethod() {
        return "BANK_TRANSFER";
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        // 接入后生成银行转账凭证，返回收款账户信息
        log.warn("[BankTransferGateway] 银行转账网关尚未接入，使用模拟返回");
        return GatewayPayResult.builder().success(false).message("银行转账网关尚未接入").build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        return GatewayQueryResult.builder().success(false).status("NOT_FOUND").message("银行转账网关尚未接入").build();
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        return GatewayRefundResult.builder().success(false).message("银行转账网关尚未接入").build();
    }
}
