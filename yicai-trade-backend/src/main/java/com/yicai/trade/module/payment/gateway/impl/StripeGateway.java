package com.yicai.trade.module.payment.gateway.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
public class StripeGateway implements PaymentGateway {

    @Value("${stripe.secret-key:}")
    private String secretKey;

    @Value("${stripe.webhook-secret:}")
    private String webhookSecret;

    @Value("${stripe.success-url:}")
    private String successUrl;

    @Value("${stripe.cancel-url:}")
    private String cancelUrl;

    @Value("${stripe.webhook-tolerance-seconds:300}")
    private long webhookToleranceSeconds;

    private static final String API_BASE = "https://api.stripe.com";
    private final RestTemplate restTemplate = new RestTemplate();

    @Override
    public String getMethod() {
        return "STRIPE";
    }

    public boolean isConfigured() {
        return secretKey != null && !secretKey.isBlank()
                && webhookSecret != null && !webhookSecret.isBlank()
                && successUrl != null && !successUrl.isBlank()
                && cancelUrl != null && !cancelUrl.isBlank();
    }

    public JsonNode createCheckoutSession(PaymentResponse payment) {
        requireApiConfiguration();

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("mode", "payment");
        form.add("success_url", appendReturnParameters(successUrl, payment.getId(), true));
        form.add("cancel_url", appendReturnParameters(cancelUrl, payment.getId(), false));
        form.add("client_reference_id", payment.getPaymentNo());
        form.add("metadata[payment_id]", String.valueOf(payment.getId()));
        form.add("metadata[payment_no]", payment.getPaymentNo());
        form.add("payment_intent_data[metadata][payment_id]", String.valueOf(payment.getId()));
        form.add("payment_intent_data[metadata][payment_no]", payment.getPaymentNo());
        form.add("line_items[0][price_data][currency]", payment.getCurrency().toLowerCase());
        form.add("line_items[0][price_data][unit_amount]", String.valueOf(toMinorUnits(payment.getAmount())));
        form.add("line_items[0][price_data][product_data][name]", "YiCai order " + payment.getOrderNo());
        form.add("line_items[0][quantity]", "1");

        HttpHeaders headers = apiHeaders(MediaType.APPLICATION_FORM_URLENCODED);
        headers.set("Idempotency-Key", payment.getPaymentNo());
        ResponseEntity<JsonNode> response = restTemplate.exchange(API_BASE + "/v1/checkout/sessions",
                HttpMethod.POST, new HttpEntity<>(form, headers), JsonNode.class);
        JsonNode body = response.getBody();
        if (body == null || body.path("id").asText().isBlank() || body.path("url").asText().isBlank()) {
            throw new IllegalStateException("Stripe Checkout response is incomplete");
        }
        return body;
    }

    public JsonNode retrieveCheckoutSession(String sessionId) {
        requireApiKey();
        ResponseEntity<JsonNode> response = restTemplate.exchange(
                API_BASE + "/v1/checkout/sessions/" + sessionId,
                HttpMethod.GET, new HttpEntity<>(apiHeaders(null)), JsonNode.class);
        return response.getBody();
    }

    public boolean verifyWebhook(String rawPayload, String signatureHeader) {
        if (webhookSecret == null || webhookSecret.isBlank() || rawPayload == null
                || signatureHeader == null || signatureHeader.isBlank()) {
            return false;
        }
        try {
            Long timestamp = null;
            List<String> signatures = new ArrayList<>();
            for (String item : signatureHeader.split(",")) {
                String[] pair = item.trim().split("=", 2);
                if (pair.length != 2) continue;
                if ("t".equals(pair[0])) timestamp = Long.parseLong(pair[1]);
                if ("v1".equals(pair[0])) signatures.add(pair[1]);
            }
            if (timestamp == null || signatures.isEmpty()
                    || Math.abs(Instant.now().getEpochSecond() - timestamp) > webhookToleranceSeconds) {
                return false;
            }
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(webhookSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] expected = mac.doFinal((timestamp + "." + rawPayload).getBytes(StandardCharsets.UTF_8));
            for (String signature : signatures) {
                byte[] supplied = hexToBytes(signature);
                if (supplied != null && MessageDigest.isEqual(expected, supplied)) return true;
            }
        } catch (Exception e) {
            log.warn("Stripe webhook signature verification failed: {}", e.getMessage());
        }
        return false;
    }

    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        return GatewayPayResult.builder().success(false)
                .message("Stripe payments must be initiated through Checkout Session").build();
    }

    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        try {
            requireApiKey();
            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    API_BASE + "/v1/payment_intents/" + transactionId,
                    HttpMethod.GET, new HttpEntity<>(apiHeaders(null)), JsonNode.class);
            String status = response.getBody() == null ? "" : response.getBody().path("status").asText();
            return GatewayQueryResult.builder().success(true).transactionId(transactionId)
                    .status("succeeded".equals(status) ? "SUCCESS" : "PROCESSING")
                    .message("Stripe PaymentIntent status: " + status).build();
        } catch (Exception e) {
            return GatewayQueryResult.builder().success(false).status("NOT_FOUND")
                    .message("Stripe status query failed").build();
        }
    }

    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        try {
            requireApiKey();
            MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
            form.add("payment_intent", request.getOriginalTransactionId());
            if (request.getRefundAmount() != null) {
                form.add("amount", String.valueOf(toMinorUnits(request.getRefundAmount())));
            }
            form.add("metadata[refund_no]", request.getRefundNo());
            HttpHeaders headers = apiHeaders(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Idempotency-Key", request.getRefundNo());
            ResponseEntity<JsonNode> response = restTemplate.exchange(API_BASE + "/v1/refunds",
                    HttpMethod.POST, new HttpEntity<>(form, headers), JsonNode.class);
            JsonNode body = response.getBody();
            if (body != null && !body.path("id").asText().isBlank()) {
                return GatewayRefundResult.builder().success(true)
                        .transactionId(body.path("id").asText()).message("Stripe refund submitted").build();
            }
        } catch (Exception e) {
            log.error("Stripe refund failed: {}", e.getMessage());
        }
        return GatewayRefundResult.builder().success(false).message("Stripe refund failed").build();
    }

    private HttpHeaders apiHeaders(MediaType contentType) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(secretKey);
        if (contentType != null) headers.setContentType(contentType);
        return headers;
    }

    private long toMinorUnits(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.UNNECESSARY).movePointRight(2).longValueExact();
    }

    private String appendReturnParameters(String base, Long paymentId, boolean success) {
        String separator = base.contains("?") ? "&" : "?";
        String url = base + separator + "payment=" + (success ? "success" : "cancelled")
                + "&payment_id=" + paymentId;
        return success ? url + "&session_id={CHECKOUT_SESSION_ID}" : url;
    }

    private byte[] hexToBytes(String value) {
        if (value == null || (value.length() & 1) == 1) return null;
        byte[] bytes = new byte[value.length() / 2];
        try {
            for (int i = 0; i < value.length(); i += 2) {
                bytes[i / 2] = (byte) Integer.parseInt(value.substring(i, i + 2), 16);
            }
            return bytes;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private void requireApiConfiguration() {
        if (!isConfigured()) throw new IllegalStateException("Stripe merchant configuration is incomplete");
    }

    private void requireApiKey() {
        if (secretKey == null || secretKey.isBlank()) {
            throw new IllegalStateException("Stripe secret key is not configured");
        }
    }
}
