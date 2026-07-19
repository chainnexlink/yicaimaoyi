package com.yicai.trade.module.payment.controller;

import com.yicai.trade.module.payment.entity.Payment;
import com.yicai.trade.module.payment.repository.PaymentRepository;
import com.yicai.trade.module.payment.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 第三方支付回调控制器
 * 用于接收支付宝/微信等第三方支付平台的异步通知。
 * 当前为模拟实现，接入真实支付后需替换签名验证逻辑。
 */
@Slf4j
@RestController
@RequestMapping("/api/payments/callback")
@RequiredArgsConstructor
@Tag(name = "支付回调", description = "第三方支付异步通知回调接口")
public class PaymentCallbackController {

    private final PaymentService paymentService;
    private final PaymentRepository paymentRepository;

    @PostMapping("/alipay")
    @Operation(summary = "支付宝回调", description = "接收支付宝异步通知（当前为模拟）")
    public String alipayCallback(@RequestBody Map<String, String> params) {
        log.info("收到支付宝回调通知: {}", params);

        try {
            if (!verifyAlipaySignature(params)) {
                log.warn("支付宝回调签名验证失败");
                return "fail";
            }

            String paymentNo = params.get("out_trade_no");
            String tradeNo = params.get("trade_no");
            String tradeStatus = params.get("trade_status");

            if (paymentNo == null || tradeStatus == null) {
                log.warn("支付宝回调参数缺失: paymentNo={}, tradeStatus={}", paymentNo, tradeStatus);
                return "fail";
            }

            Payment payment = paymentRepository.findByPaymentNo(paymentNo)
                    .orElse(null);
            if (payment == null) {
                log.warn("支付宝回调找不到支付记录: paymentNo={}", paymentNo);
                return "fail";
            }

            if ("TRADE_SUCCESS".equals(tradeStatus) || "TRADE_FINISHED".equals(tradeStatus)) {
                if (!"SUCCESS".equals(payment.getStatus())) {
                    paymentService.confirmPayment(payment.getId(), tradeNo);
                }
            }

            return "success";
        } catch (Exception e) {
            log.error("处理支付宝回调异常: {}", e.getMessage(), e);
            return "fail";
        }
    }

    @PostMapping("/wechat")
    @Operation(summary = "微信支付回调", description = "接收微信支付异步通知（当前为模拟）")
    public String wechatCallback(@RequestBody Map<String, String> params) {
        log.info("收到微信支付回调通知: {}", params);

        try {
            if (!verifyWechatSignature(params)) {
                log.warn("微信支付回调签名验证失败");
                return "<xml><return_code>FAIL</return_code></xml>";
            }

            String paymentNo = params.get("out_trade_no");
            String transactionId = params.get("transaction_id");
            String resultCode = params.get("result_code");

            if (paymentNo == null || resultCode == null) {
                log.warn("微信支付回调参数缺失: paymentNo={}, resultCode={}", paymentNo, resultCode);
                return "<xml><return_code>FAIL</return_code></xml>";
            }

            Payment payment = paymentRepository.findByPaymentNo(paymentNo)
                    .orElse(null);
            if (payment == null) {
                log.warn("微信支付回调找不到支付记录: paymentNo={}", paymentNo);
                return "<xml><return_code>FAIL</return_code></xml>";
            }

            if ("SUCCESS".equals(resultCode)) {
                if (!"SUCCESS".equals(payment.getStatus())) {
                    paymentService.confirmPayment(payment.getId(), transactionId);
                }
            }

            return "<xml><return_code>SUCCESS</return_code></xml>";
        } catch (Exception e) {
            log.error("处理微信支付回调异常: {}", e.getMessage(), e);
            return "<xml><return_code>FAIL</return_code></xml>";
        }
    }

    @PostMapping("/bank")
    @Operation(summary = "银行转账回调", description = "接收银行转账确认通知（当前为模拟）")
    public Map<String, Object> bankTransferCallback(@RequestBody Map<String, String> params) {
        log.info("收到银行转账回调通知: {}", params);
        log.error("银行回调验签尚未接入，拒绝更新支付状态");
        return Map.of("code", "FAIL", "message", "银行回调尚未启用");
    }

    /**
     * 验证支付宝回调签名。
     * 生产环境必须接入真实支付宝SDK后替换为：
     * AlipaySignature.rsaCheckV1(params, alipayPublicKey, "UTF-8", "RSA2")
     * 未接入 SDK 前必须在所有环境失败关闭。
     */
    private boolean verifyAlipaySignature(Map<String, String> params) {
        log.error("支付宝签名验证尚未接入，拒绝回调请求");
        return false;
    }

    /**
     * 验证微信支付回调签名。
     * 生产环境必须接入真实微信支付SDK后替换为实际验签逻辑。
     * 未接入 SDK 前必须在所有环境失败关闭。
     */
    private boolean verifyWechatSignature(Map<String, String> params) {
        log.error("微信支付签名验证尚未接入，拒绝回调请求");
        return false;
    }
}
