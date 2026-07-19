package com.yicai.trade.module.payment.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.gateway.impl.StripeGateway;
import com.yicai.trade.module.payment.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

@Slf4j
@RestController
@RequestMapping("/api/payments/callback")
@RequiredArgsConstructor
public class StripeWebhookController {

    private final StripeGateway stripeGateway;
    private final PaymentService paymentService;
    private final ObjectMapper objectMapper;

    @PostMapping(value = "/stripe", consumes = "application/json")
    public ResponseEntity<String> handleStripeWebhook(
            @RequestBody String rawPayload,
            @RequestHeader(value = "Stripe-Signature", required = false) String signature) {
        if (!stripeGateway.verifyWebhook(rawPayload, signature)) {
            log.warn("拒绝无效Stripe webhook签名");
            return ResponseEntity.badRequest().body("invalid signature");
        }
        try {
            JsonNode event = objectMapper.readTree(rawPayload);
            String type = event.path("type").asText();
            if (!"checkout.session.completed".equals(type)
                    && !"checkout.session.async_payment_succeeded".equals(type)) {
                return ResponseEntity.ok("ignored");
            }

            JsonNode session = event.path("data").path("object");
            if (!"paid".equals(session.path("payment_status").asText())) {
                return ResponseEntity.ok("awaiting payment");
            }
            Long paymentId = Long.valueOf(session.path("metadata").path("payment_id").asText());
            PaymentResponse payment = paymentService.getPaymentById(paymentId);
            if (!"STRIPE".equals(payment.getPaymentMethod())
                    || !Objects.equals(payment.getPaymentNo(), session.path("client_reference_id").asText())
                    || !Objects.equals(payment.getTransactionId(), session.path("id").asText())) {
                log.error("Stripe webhook与平台支付单绑定不匹配: paymentId={}", paymentId);
                return ResponseEntity.badRequest().body("payment binding mismatch");
            }

            BigDecimal amount = BigDecimal.valueOf(session.path("amount_total").asLong())
                    .movePointLeft(2).setScale(2, RoundingMode.UNNECESSARY);
            String currency = session.path("currency").asText().toUpperCase();
            String paymentIntentId = session.path("payment_intent").asText();
            paymentService.confirmExternalPayment(paymentId, "STRIPE", paymentIntentId, amount, currency);
            log.info("Stripe支付已确认: paymentNo={}, paymentIntent={}", payment.getPaymentNo(), paymentIntentId);
            return ResponseEntity.ok("received");
        } catch (Exception e) {
            log.error("处理Stripe webhook失败: {}", e.getMessage(), e);
            return ResponseEntity.badRequest().body("invalid event");
        }
    }
}
