package com.yicai.trade.module.payment.gateway.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.payment.gateway.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * PayPal 支付网关
 * 基于 PayPal Orders API v2 实现，支持 Sandbox 和 Live 环境
 */
@Slf4j
@Component
public class PayPalGateway implements PaymentGateway {

    @Value("${paypal.client-id:}")
    private String clientId;

    @Value("${paypal.client-secret:}")
    private String clientSecret;

    @Value("${paypal.mode:sandbox}")
    private String mode;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private String cachedAccessToken;
    private long tokenExpiresAt;

    public boolean isConfigured() {
        return clientId != null && !clientId.isBlank()
                && clientSecret != null && !clientSecret.isBlank();
    }

    public String getClientId() {
        return clientId;
    }

    public String getMode() {
        return mode;
    }

    @Override
    public String getMethod() {
        return "PAYPAL";
    }

    /**
     * 获取 PayPal API 基础 URL
     */
    private String getBaseUrl() {
        return "sandbox".equalsIgnoreCase(mode)
                ? "https://api-m.sandbox.paypal.com"
                : "https://api-m.paypal.com";
    }

    /**
     * 获取 Access Token（带缓存）
     */
    public String getAccessToken() {
        if (!isConfigured()) {
            throw new IllegalStateException("PayPal merchant credentials are not configured");
        }
        if (cachedAccessToken != null && System.currentTimeMillis() < tokenExpiresAt) {
            return cachedAccessToken;
        }

        String url = getBaseUrl() + "/v1/oauth2/token";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        String credentials = Base64.getEncoder().encodeToString(
                (clientId + ":" + clientSecret).getBytes(StandardCharsets.UTF_8));
        headers.set("Authorization", "Basic " + credentials);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");

        try {
            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(body, headers), JsonNode.class);

            JsonNode responseBody = response.getBody();
            if (responseBody != null && responseBody.has("access_token")) {
                cachedAccessToken = responseBody.get("access_token").asText();
                int expiresIn = responseBody.get("expires_in").asInt(3600);
                // 提前60秒过期，避免边界情况
                tokenExpiresAt = System.currentTimeMillis() + (expiresIn - 60) * 1000L;
                log.info("[PayPal] Access Token 获取成功，{}秒后过期", expiresIn);
                return cachedAccessToken;
            }
            throw new RuntimeException("PayPal token 响应格式异常");
        } catch (Exception e) {
            log.error("[PayPal] 获取 Access Token 失败: {}", e.getMessage());
            throw new RuntimeException("获取 PayPal Access Token 失败", e);
        }
    }

    /**
     * 创建 PayPal 订单
     */
    public String createOrder(String paymentNo, String amount, String currency, String description) {
        String url = getBaseUrl() + "/v2/checkout/orders";
        String token = getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(token);
        headers.set("Prefer", "return=representation");
        headers.set("PayPal-Request-Id", paymentNo);

        Map<String, Object> orderBody = new LinkedHashMap<>();
        orderBody.put("intent", "CAPTURE");

        Map<String, Object> purchaseUnit = new LinkedHashMap<>();
        purchaseUnit.put("reference_id", paymentNo);
        purchaseUnit.put("custom_id", paymentNo);
        purchaseUnit.put("invoice_id", paymentNo);
        purchaseUnit.put("description", description != null ? description : "YiCai Trade Payment");

        Map<String, String> amountMap = new LinkedHashMap<>();
        amountMap.put("currency_code", currency != null ? currency : "USD");
        amountMap.put("value", amount);
        purchaseUnit.put("amount", amountMap);

        orderBody.put("purchase_units", List.of(purchaseUnit));

        try {
            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(orderBody, headers), JsonNode.class);

            JsonNode body = response.getBody();
            if (body != null && body.has("id")) {
                String orderId = body.get("id").asText();
                String status = body.get("status").asText();
                log.info("[PayPal] 订单创建成功: orderId={}, status={}", orderId, status);
                return orderId;
            }
            throw new RuntimeException("PayPal 创建订单响应格式异常");
        } catch (Exception e) {
            log.error("[PayPal] 创建订单失败: {}", e.getMessage());
            throw new RuntimeException("创建 PayPal 订单失败", e);
        }
    }

    /**
     * 捕获 PayPal 订单支付
     */
    public JsonNode captureOrder(String paypalOrderId) {
        String url = getBaseUrl() + "/v2/checkout/orders/" + paypalOrderId + "/capture";
        String token = getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(token);
        headers.set("Prefer", "return=representation");
        headers.set("PayPal-Request-Id", paypalOrderId + "-capture");

        try {
            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>("{}", headers), JsonNode.class);

            JsonNode body = response.getBody();
            if (body != null) {
                String status = body.get("status").asText();
                log.info("[PayPal] 订单捕获完成: orderId={}, status={}", paypalOrderId, status);
                return body;
            }
            throw new RuntimeException("PayPal 捕获订单响应格式异常");
        } catch (Exception e) {
            log.error("[PayPal] 捕获订单失败: {}", e.getMessage());
            throw new RuntimeException("捕获 PayPal 订单失败", e);
        }
    }

    /**
     * PaymentGateway 接口实现 - 发起支付
     */
    @Override
    public GatewayPayResult pay(GatewayPayRequest request) {
        log.info("[PayPal] 支付请求: paymentNo={}, amount={}", request.getPaymentNo(), request.getAmount());

        try {
            String paypalOrderId = createOrder(
                    request.getPaymentNo(),
                    request.getAmount().toPlainString(),
                    request.getCurrency() == null ? "USD" : request.getCurrency(),
                    request.getSubject());

            return GatewayPayResult.builder()
                    .success(true)
                    .transactionId(paypalOrderId)
                    .message("PayPal 订单已创建，等待买家确认支付")
                    .payUrl(null) // 前端通过 JS SDK 弹出支付窗口，不需要跳转
                    .build();
        } catch (Exception e) {
            return GatewayPayResult.builder()
                    .success(false)
                    .message("PayPal 支付创建失败: " + e.getMessage())
                    .build();
        }
    }

    /**
     * PaymentGateway 接口实现 - 查询支付状态
     */
    @Override
    public GatewayQueryResult queryStatus(String transactionId) {
        log.info("[PayPal] 查询订单状态: {}", transactionId);

        try {
            String url = getBaseUrl() + "/v2/checkout/orders/" + transactionId;
            String token = getAccessToken();

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(token);

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class);

            JsonNode body = response.getBody();
            if (body != null) {
                String status = body.get("status").asText();
                String mappedStatus = mapPayPalStatus(status);

                return GatewayQueryResult.builder()
                        .success(true)
                        .status(mappedStatus)
                        .transactionId(transactionId)
                        .message("PayPal 订单状态: " + status)
                        .build();
            }
        } catch (Exception e) {
            log.error("[PayPal] 查询订单状态失败: {}", e.getMessage());
        }

        return GatewayQueryResult.builder()
                .success(false)
                .status("NOT_FOUND")
                .message("查询 PayPal 订单状态失败")
                .build();
    }

    /**
     * PaymentGateway 接口实现 - 退款
     */
    @Override
    public GatewayRefundResult refund(GatewayRefundRequest request) {
        log.info("[PayPal] 退款请求: originalTxn={}, amount={}",
                request.getOriginalTransactionId(), request.getRefundAmount());

        try {
            String captureId = request.getOriginalTransactionId();
            String url = getBaseUrl() + "/v2/payments/captures/" + captureId + "/refund";
            String token = getAccessToken();

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(token);

            Map<String, Object> refundBody = new LinkedHashMap<>();
            if (request.getRefundAmount() != null) {
                Map<String, String> amountMap = new LinkedHashMap<>();
                amountMap.put("value", request.getRefundAmount().toPlainString());
                amountMap.put("currency_code", request.getCurrency() == null ? "USD" : request.getCurrency());
                refundBody.put("amount", amountMap);
            }
            if (request.getReason() != null) {
                refundBody.put("note_to_payer", request.getReason());
            }

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(refundBody, headers), JsonNode.class);

            JsonNode body = response.getBody();
            if (body != null && body.has("id")) {
                return GatewayRefundResult.builder()
                        .success(true)
                        .transactionId(body.get("id").asText())
                        .message("PayPal 退款已处理")
                        .build();
            }
        } catch (Exception e) {
            log.error("[PayPal] 退款失败: {}", e.getMessage());
        }

        return GatewayRefundResult.builder()
                .success(false)
                .message("PayPal 退款失败")
                .build();
    }

    /**
     * 从订单中获取 Capture ID
     */
    private String getCaptureId(String paypalOrderId) {
        try {
            String url = getBaseUrl() + "/v2/checkout/orders/" + paypalOrderId;
            String token = getAccessToken();

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(token);

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class);

            JsonNode body = response.getBody();
            if (body != null && body.has("purchase_units")) {
                JsonNode captures = body.get("purchase_units").get(0)
                        .path("payments").path("captures");
                if (captures.isArray() && captures.size() > 0) {
                    return captures.get(0).get("id").asText();
                }
            }
        } catch (Exception e) {
            log.error("[PayPal] 获取 Capture ID 失败: {}", e.getMessage());
        }
        return null;
    }

    /**
     * 映射 PayPal 状态到内部状态
     */
    private String mapPayPalStatus(String paypalStatus) {
        return switch (paypalStatus) {
            case "COMPLETED" -> "SUCCESS";
            case "APPROVED" -> "PROCESSING";
            case "CREATED" -> "PENDING";
            case "VOIDED" -> "FAILED";
            default -> "PENDING";
        };
    }
}
