package com.yicai.trade.module.notification.sms;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 阿里云官方短信服务 (Dysmsapi) 网关实现
 * 使用 AccessKey + HMAC-SHA1 签名方式调用 SendSms API
 * 无需额外 Maven 依赖
 */
@Slf4j
@Component
public class AliyunDysSmsGateway implements SmsGateway {

    @Value("${sms.aliyun.access-key-id:${ALIYUN_SMS_ACCESS_KEY_ID:}}")
    private String accessKeyId;

    @Value("${sms.aliyun.access-key-secret:${ALIYUN_SMS_ACCESS_KEY_SECRET:}}")
    private String accessKeySecret;

    @Value("${sms.aliyun.sign-name:${ALIYUN_SMS_SIGN_NAME:易采礼品贸易有限公司}}")
    private String signName;

    @Value("${sms.aliyun.template-code:${ALIYUN_SMS_TEMPLATE_CODE:}}")
    private String templateCode;

    @Value("${sms.aliyun.enabled:${ALIYUN_SMS_ENABLED:false}}")
    private boolean enabled;

    private static final String API_ENDPOINT = "https://dysmsapi.aliyuncs.com";
    private static final String API_VERSION = "2017-05-25";

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public AliyunDysSmsGateway(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newHttpClient();
    }

    @Override
    public SmsResult sendVerificationCode(String phone, String code) {
        if (!enabled) {
            log.warn("阿里云短信服务未启用 (sms.aliyun.enabled=false)");
            return SmsResult.fail("短信服务未启用");
        }
        if (accessKeyId == null || accessKeyId.isEmpty()
                || accessKeySecret == null || accessKeySecret.isEmpty()) {
            log.error("阿里云短信 AccessKey 未配置");
            return SmsResult.fail("短信服务配置缺失");
        }
        if (templateCode == null || templateCode.isEmpty()) {
            log.error("阿里云短信模板CODE未配置 (sms.aliyun.template-code)");
            return SmsResult.fail("短信模板未配置");
        }

        long startTime = System.currentTimeMillis();

        try {
            // 构建API请求参数
            Map<String, String> params = new TreeMap<>();
            // 公共参数
            params.put("AccessKeyId", accessKeyId);
            params.put("Action", "SendSms");
            params.put("Format", "JSON");
            params.put("RegionId", "cn-hangzhou");
            params.put("SignatureMethod", "HMAC-SHA1");
            params.put("SignatureNonce", UUID.randomUUID().toString());
            params.put("SignatureVersion", "1.0");
            params.put("Timestamp", getISO8601Timestamp());
            params.put("Version", API_VERSION);
            // 业务参数
            params.put("PhoneNumbers", phone);
            params.put("SignName", signName);
            params.put("TemplateCode", templateCode);
            params.put("TemplateParam", "{\"code\":\"" + code + "\"}");

            // 计算签名
            String signature = computeSignature(params);
            params.put("Signature", signature);

            // 构建请求URL
            StringBuilder urlBuilder = new StringBuilder(API_ENDPOINT).append("/?");
            boolean first = true;
            for (Map.Entry<String, String> entry : params.entrySet()) {
                if (!first) urlBuilder.append("&");
                urlBuilder.append(percentEncode(entry.getKey()))
                        .append("=")
                        .append(percentEncode(entry.getValue()));
                first = false;
            }

            String requestUrl = urlBuilder.toString();
            log.info("发送阿里云短信: phone={}, signName={}, templateCode={}", phone, signName, templateCode);

            // 发送HTTP请求
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(requestUrl))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            long costMs = System.currentTimeMillis() - startTime;
            String responseBody = response.body();

            log.info("阿里云短信API响应: httpStatus={}, body={}, costMs={}", response.statusCode(), responseBody, costMs);

            // 解析响应
            JsonNode root = objectMapper.readTree(responseBody);
            String respCode = root.path("Code").asText("");
            String respMessage = root.path("Message").asText("");
            String bizId = root.path("BizId").asText("");

            if ("OK".equalsIgnoreCase(respCode)) {
                log.info("阿里云短信发送成功: phone={}, bizId={}", phone, bizId);
                return SmsResult.ok(bizId);
            } else {
                log.warn("阿里云短信发送失败: phone={}, code={}, message={}", phone, respCode, respMessage);
                return SmsResult.fail(respMessage + " (" + respCode + ")");
            }

        } catch (Exception e) {
            long costMs = System.currentTimeMillis() - startTime;
            log.error("阿里云短信发送异常: phone={}, costMs={}, error={}", phone, costMs, e.getMessage(), e);
            return SmsResult.fail("短信发送异常: " + e.getMessage());
        }
    }

    /**
     * 计算阿里云API签名 (HMAC-SHA1)
     */
    private String computeSignature(Map<String, String> params) throws Exception {
        // 1. 构造规范化请求字符串
        StringBuilder canonicalQueryString = new StringBuilder();
        boolean first = true;
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (!first) canonicalQueryString.append("&");
            canonicalQueryString.append(percentEncode(entry.getKey()))
                    .append("=")
                    .append(percentEncode(entry.getValue()));
            first = false;
        }

        // 2. 构造待签名字符串
        String stringToSign = "GET" + "&"
                + percentEncode("/") + "&"
                + percentEncode(canonicalQueryString.toString());

        // 3. 使用HMAC-SHA1计算签名
        String signingKey = accessKeySecret + "&";
        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(new SecretKeySpec(signingKey.getBytes(StandardCharsets.UTF_8), "HmacSHA1"));
        byte[] signatureBytes = mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8));

        return Base64.getEncoder().encodeToString(signatureBytes);
    }

    /**
     * 阿里云专用 URL 编码 (RFC 3986)
     */
    private static String percentEncode(String value) {
        if (value == null) return "";
        return URLEncoder.encode(value, StandardCharsets.UTF_8)
                .replace("+", "%20")
                .replace("*", "%2A")
                .replace("%7E", "~");
    }

    /**
     * 获取ISO 8601格式的UTC时间戳
     */
    private static String getISO8601Timestamp() {
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
        df.setTimeZone(TimeZone.getTimeZone("UTC"));
        return df.format(new Date());
    }
}
