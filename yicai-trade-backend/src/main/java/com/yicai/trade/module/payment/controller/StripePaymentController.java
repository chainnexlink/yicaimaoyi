package com.yicai.trade.module.payment.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.gateway.impl.StripeGateway;
import com.yicai.trade.module.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Objects;

@Slf4j
@RestController
@RequestMapping("/api/payments/stripe")
@RequiredArgsConstructor
@Tag(name = "Stripe支付", description = "Stripe Checkout 国际银行卡支付")
public class StripePaymentController {

    private final StripeGateway stripeGateway;
    private final PaymentService paymentService;
    private final ResourceAuthorizationService authorization;

    @GetMapping("/config")
    public Result<Map<String, Object>> getConfig() {
        return Result.success(Map.of("enabled", stripeGateway.isConfigured()));
    }

    @PostMapping("/checkout-session")
    @Operation(summary = "创建Stripe Checkout会话")
    public Result<Map<String, String>> createCheckoutSession(@Valid @RequestBody CheckoutRequest request) {
        authorization.assertPaymentPayerAccess(request.paymentId());
        PaymentResponse payment = paymentService.getPaymentById(request.paymentId());
        assertMethod(payment);

        JsonNode session;
        if ("PROCESSING".equals(payment.getStatus()) && payment.getTransactionId() != null) {
            session = stripeGateway.retrieveCheckoutSession(payment.getTransactionId());
        } else if ("PENDING".equals(payment.getStatus())) {
            session = stripeGateway.createCheckoutSession(payment);
            paymentService.markPaymentProcessing(payment.getId(), "STRIPE", session.path("id").asText());
        } else {
            throw new BusinessException(ErrorCode.PAYMENT_STATUS_INVALID);
        }
        if (session == null || session.path("url").asText().isBlank()) {
            throw new BusinessException(ErrorCode.PAYMENT_GATEWAY_ERROR, "Stripe Checkout URL不可用");
        }
        return Result.success(Map.of("sessionId", session.path("id").asText(),
                "checkoutUrl", session.path("url").asText()));
    }

    private void assertMethod(PaymentResponse payment) {
        if (!"STRIPE".equals(payment.getPaymentMethod())) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付单不是Stripe通道");
        }
    }

    public record CheckoutRequest(@NotNull Long paymentId) {}
}
