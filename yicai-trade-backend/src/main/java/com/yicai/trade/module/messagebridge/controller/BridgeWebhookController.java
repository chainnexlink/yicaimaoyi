package com.yicai.trade.module.messagebridge.controller;

import com.yicai.trade.module.messagebridge.repository.BridgeConfigRepository;
import com.yicai.trade.module.messagebridge.service.BridgeForwardingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/webhook")
@RequiredArgsConstructor
public class BridgeWebhookController {

    private final BridgeForwardingService forwardingService;
    private final BridgeConfigRepository configRepository;

    // ===== 企业微信回调 =====

    @PostMapping("/wechat-work")
    public ResponseEntity<String> wechatWorkCallback(
            @RequestBody Map<String, Object> payload,
            @RequestParam(required = false) String msg_signature,
            @RequestParam(required = false) String timestamp,
            @RequestParam(required = false) String nonce) {
        log.info("Received WeChat Work webhook: timestamp={}, nonce={}", timestamp, nonce);

        // 签名验证
        String token = getConfigValue("WECHAT_WORK_TOKEN", "");
        if (token.isEmpty()) {
            log.warn("WeChat Work webhook token未配置，拒绝请求");
            return ResponseEntity.status(403).body("webhook token not configured");
        }
        if (msg_signature == null || timestamp == null || nonce == null) {
            log.warn("WeChat Work webhook缺少签名参数");
            return ResponseEntity.status(400).body("missing signature parameters");
        }
        if (!verifyWechatSignature(token, timestamp, nonce, msg_signature)) {
            log.warn("WeChat Work webhook signature verification failed");
            return ResponseEntity.status(403).body("signature verification failed");
        }

        try {
            String userId = String.valueOf(payload.getOrDefault("FromUserName", ""));
            String content = String.valueOf(payload.getOrDefault("Content", ""));
            String msgType = String.valueOf(payload.getOrDefault("MsgType", "text"));

            if (!userId.isEmpty() && !content.isEmpty()) {
                forwardingService.receiveExternalMessage("WECHAT_WORK", userId, content);
                log.info("WeChat Work message forwarded: userId={}, msgType={}", userId, msgType);
            }
        } catch (Exception e) {
            log.error("Error processing WeChat Work webhook: {}", e.getMessage(), e);
        }
        return ResponseEntity.ok("success");
    }

    @GetMapping("/wechat-work")
    public ResponseEntity<String> wechatWorkVerify(
            @RequestParam(required = false) String msg_signature,
            @RequestParam(required = false) String timestamp,
            @RequestParam(required = false) String nonce,
            @RequestParam(required = false) String echostr) {
        // 企业微信URL验证：验证签名后返回 echostr
        String token = getConfigValue("WECHAT_WORK_TOKEN", "");
        if (token.isEmpty()) {
            log.warn("WeChat Work URL验证失败: token未配置");
            return ResponseEntity.status(403).body("");
        }
        if (msg_signature == null || timestamp == null || nonce == null) {
            log.warn("WeChat Work URL验证失败: 缺少签名参数");
            return ResponseEntity.status(400).body("");
        }
        if (!verifyWechatSignature(token, timestamp, nonce, msg_signature)) {
            log.warn("WeChat Work URL verification failed");
            return ResponseEntity.status(403).body("");
        }
        log.info("WeChat Work URL verification success");
        return ResponseEntity.ok(echostr != null ? echostr : "");
    }

    // ===== QQ机器人回调 =====

    @PostMapping("/qq-bot")
    public ResponseEntity<String> qqBotCallback(
            @RequestBody Map<String, Object> payload,
            @RequestHeader(value = "X-Signature", required = false) String signature) {
        log.info("Received QQ Bot webhook");

        // Token 验证
        String botToken = getConfigValue("QQ_BOT_TOKEN", "");
        if (botToken.isEmpty()) {
            log.warn("QQ Bot webhook token未配置，拒绝请求");
            return ResponseEntity.status(403).body("webhook token not configured");
        }
        if (signature == null || signature.isBlank()) {
            log.warn("QQ Bot webhook缺少签名头");
            return ResponseEntity.status(400).body("missing signature header");
        }
        if (!verifyQQBotSignature(botToken, payload, signature)) {
            log.warn("QQ Bot webhook signature verification failed");
            return ResponseEntity.status(403).body("signature verification failed");
        }

        try {
            String userId = String.valueOf(payload.getOrDefault("user_id", ""));
            String content = String.valueOf(payload.getOrDefault("content", ""));
            String messageType = String.valueOf(payload.getOrDefault("message_type", "private"));

            if (!userId.isEmpty() && !content.isEmpty()) {
                forwardingService.receiveExternalMessage("QQ_BOT", userId, content);
                log.info("QQ Bot message forwarded: userId={}, messageType={}", userId, messageType);
            }
        } catch (Exception e) {
            log.error("Error processing QQ Bot webhook: {}", e.getMessage(), e);
        }
        return ResponseEntity.ok("ok");
    }

    // ===== 签名验证 =====

    private boolean verifyWechatSignature(String token, String timestamp, String nonce, String expectedSignature) {
        try {
            String[] arr = {token, timestamp, nonce};
            Arrays.sort(arr);
            String combined = String.join("", arr);
            MessageDigest digest = MessageDigest.getInstance("SHA-1");
            byte[] hash = digest.digest(combined.getBytes(StandardCharsets.UTF_8));
            String computed = bytesToHex(hash);
            return computed.equalsIgnoreCase(expectedSignature);
        } catch (Exception e) {
            log.error("WeChat signature verification error: {}", e.getMessage());
            return false;
        }
    }

    private boolean verifyQQBotSignature(String secret, Map<String, Object> payload, String expectedSignature) {
        try {
            String payloadStr = payload.toString();
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(payloadStr.getBytes(StandardCharsets.UTF_8));
            String computed = bytesToHex(hash);
            return computed.equalsIgnoreCase(expectedSignature.replace("sha256=", ""));
        } catch (Exception e) {
            log.error("QQ Bot signature verification error: {}", e.getMessage());
            return false;
        }
    }

    private String getConfigValue(String key, String defaultValue) {
        return configRepository.findByConfigKey(key)
                .map(c -> c.getConfigValue() != null ? c.getConfigValue() : defaultValue)
                .orElse(defaultValue);
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
