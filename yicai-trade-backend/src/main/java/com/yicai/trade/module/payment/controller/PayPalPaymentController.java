package com.yicai.trade.module.payment.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.security.ResourceAuthorizationService;
import com.yicai.trade.module.payment.dto.PaymentResponse;
import com.yicai.trade.module.payment.gateway.impl.PayPalGateway;
import com.yicai.trade.module.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

@Slf4j
@RestController
@RequestMapping("/api/payments/paypal")
@RequiredArgsConstructor
@Tag(name = "PayPal支付", description = "PayPal Orders v2 在线支付接口")
public class PayPalPaymentController {

    private final PayPalGateway payPalGateway;
    private final PaymentService paymentService;
    private final ResourceAuthorizationService authorization;

    @GetMapping("/config")
    @Operation(summary = "获取PayPal前端公开配置")
    public Result<Map<String, Object>> getConfig() {
        Map<String, Object> config = new LinkedHashMap<>();
        config.put("enabled", payPalGateway.isConfigured());
        config.put("clientId", payPalGateway.isConfigured() ? payPalGateway.getClientId() : "");
        config.put("mode", payPalGateway.getMode());
        return Result.success(config);
    }

    @PostMapping("/create-order")
    @Operation(summary = "创建PayPal订单", description = "金额、币种和流水号只从平台支付单读取")
    public Result<Map<String, String>> createPayPalOrder(@Valid @RequestBody CreateOrderRequest request) {
        authorization.assertPaymentPayerAccess(request.paymentId());
        PaymentResponse payment = paymentService.getPaymentById(request.paymentId());
        assertMethod(payment);

        if ("PROCESSING".equals(payment.getStatus()) && payment.getTransactionId() != null) {
            return Result.success(Map.of("orderId", payment.getTransactionId()));
        }
        if (!"PENDING".equals(payment.getStatus())) {
            throw new BusinessException(ErrorCode.PAYMENT_STATUS_INVALID);
        }

        String orderId = payPalGateway.createOrder(payment.getPaymentNo(),
                payment.getAmount().toPlainString(), payment.getCurrency(),
                "Order " + payment.getOrderNo());
        paymentService.markPaymentProcessing(payment.getId(), "PAYPAL", orderId);
        return Result.success(Map.of("orderId", orderId));
    }

    @PostMapping("/capture-order")
    @Operation(summary = "捕获PayPal支付", description = "服务端核对订单绑定、金额与币种后确认平台支付")
    public Result<Map<String, Object>> capturePayPalOrder(@Valid @RequestBody CaptureOrderRequest request) {
        authorization.assertPaymentPayerAccess(request.paymentId());
        PaymentResponse payment = paymentService.getPaymentById(request.paymentId());
        assertMethod(payment);
        if (!Objects.equals(payment.getTransactionId(), request.orderId())) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "PayPal订单与平台支付单不匹配");
        }
        // 在调用不可逆的capture前再次执行本地过期和状态检查。
        paymentService.markPaymentProcessing(payment.getId(), "PAYPAL", request.orderId());

        JsonNode result = payPalGateway.captureOrder(request.orderId());
        if (!"COMPLETED".equals(result.path("status").asText())) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "PayPal payment is not completed");
        }
        JsonNode capture = result.path("purchase_units").path(0)
                .path("payments").path("captures").path(0);
        String captureId = capture.path("id").asText();
        BigDecimal amount = new BigDecimal(capture.path("amount").path("value").asText());
        String currency = capture.path("amount").path("currency_code").asText();
        PaymentResponse confirmed = paymentService.confirmExternalPayment(payment.getId(), "PAYPAL",
                captureId, amount, currency);

        log.info("PayPal支付已确认: paymentNo={}, captureId={}", payment.getPaymentNo(), captureId);
        return Result.success(Map.of(
                "status", confirmed.getStatus(),
                "paymentId", confirmed.getId(),
                "captureId", captureId,
                "paypalOrderId", request.orderId()));
    }

    private void assertMethod(PaymentResponse payment) {
        if (!"PAYPAL".equals(payment.getPaymentMethod())) {
            throw new BusinessException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付单不是PayPal通道");
        }
    }

    public record CreateOrderRequest(@NotNull Long paymentId) {}

    public record CaptureOrderRequest(@NotNull Long paymentId, @NotBlank String orderId) {}
}
