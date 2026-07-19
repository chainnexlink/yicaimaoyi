package com.yicai.trade.module.payment.gateway;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 支付网关工厂
 * 根据 paymentMethod 选择对应的网关实现；未知方式直接拒绝，避免假成功。
 */
@Slf4j
@Component
public class PaymentGatewayFactory {

    private final Map<String, PaymentGateway> gatewayMap;
    public PaymentGatewayFactory(List<PaymentGateway> gateways) {
        this.gatewayMap = gateways.stream()
                .collect(Collectors.toMap(PaymentGateway::getMethod, Function.identity(), (a, b) -> a));
        log.info("已注册支付网关: {}", gatewayMap.keySet());
    }

    /**
     * 获取指定支付方式的网关。
     */
    public PaymentGateway getGateway(String paymentMethod) {
        PaymentGateway gateway = gatewayMap.get(paymentMethod == null ? null : paymentMethod.trim().toUpperCase());
        if (gateway != null) {
            return gateway;
        }
        log.warn("拒绝不受支持的支付方式: {}", paymentMethod);
        throw new BusinessException(ErrorCode.PAYMENT_METHOD_NOT_SUPPORTED);
    }
}
