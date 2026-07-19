package com.yicai.trade.module.notification.sms;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.thirdparty.entity.ThirdPartyConfig;
import com.yicai.trade.module.thirdparty.repository.ThirdPartyConfigRepository;
import com.yicai.trade.module.thirdparty.service.ThirdPartyLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

/**
 * 望为科技短信网关实现 (阿里云API市场)
 * 优先从数据库 t_third_party_config (config_key=SMS_GATEWAY) 读取配置，
 * 模板ID从 extra_config 字段读取，fallback 到环境变量配置。
 */
@Slf4j
@Component
public class AliyunMarketSmsGateway implements SmsGateway {

    private static final String CONFIG_KEY = "SMS_GATEWAY";

    @Value("${sms.api-url:https://wwsms.market.alicloudapi.com/send_sms}")
    private String defaultApiUrl;

    @Value("${sms.app-code:}")
    private String defaultAppCode;

    @Value("${sms.template-id:wangweisms996}")
    private String defaultTemplateId;

    @Value("${sms.enabled:false}")
    private boolean defaultEnabled;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper;

    @Autowired(required = false)
    private ThirdPartyConfigRepository configRepository;

    @Autowired(required = false)
    private ThirdPartyLogService logService;

    public AliyunMarketSmsGateway(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * 从数据库读取SMS配置，fallback到环境变量
     */
    private SmsConfig loadConfig() {
        if (configRepository != null) {
            try {
                var opt = configRepository.findByConfigKey(CONFIG_KEY);
                if (opt.isPresent()) {
                    ThirdPartyConfig db = opt.get();
                    String dbAppCode = db.getAppCode();
                    String dbApiUrl = db.getApiUrl();
                    boolean dbEnabled = db.getEnabled() != null && db.getEnabled();
                    // 模板ID存在extraConfig字段中
                    String dbTemplateId = parseExtraField(db.getExtraConfig(), "template_id");
                    return new SmsConfig(
                            dbApiUrl != null && !dbApiUrl.isEmpty() ? dbApiUrl : defaultApiUrl,
                            dbAppCode != null && !dbAppCode.isEmpty() ? dbAppCode : defaultAppCode,
                            dbTemplateId != null && !dbTemplateId.isEmpty() ? dbTemplateId : defaultTemplateId,
                            dbEnabled
                    );
                }
            } catch (Exception e) {
                log.warn("读取数据库SMS配置失败，使用环境变量: {}", e.getMessage());
            }
        }
        return new SmsConfig(defaultApiUrl, defaultAppCode, defaultTemplateId, defaultEnabled);
    }

    private String parseExtraField(String extraConfig, String key) {
        if (extraConfig == null || extraConfig.isEmpty()) return null;
        try {
            JsonNode root = objectMapper.readTree(extraConfig);
            String val = root.path(key).asText(null);
            return val;
        } catch (Exception e) {
            // extraConfig可能是简单的key=value格式
            for (String line : extraConfig.split("[;\n]")) {
                String[] parts = line.split("=", 2);
                if (parts.length == 2 && parts[0].trim().equals(key)) {
                    return parts[1].trim();
                }
            }
        }
        return null;
    }

    @Override
    public SmsResult sendVerificationCode(String phone, String code) {
        SmsConfig config = loadConfig();

        if (!config.enabled || config.appCode == null || config.appCode.isEmpty()) {
            log.warn("短信服务未启用或未配置AppCode, enabled={}", config.enabled);
            return SmsResult.fail("短信服务未启用");
        }

        long startTime = System.currentTimeMillis();
        String requestInfo = "phone=" + phone + ", code=" + code + ", templateId=" + config.templateId;

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "APPCODE " + config.appCode);
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
            body.add("content", "code:" + code);
            body.add("template_id", config.templateId);
            body.add("phone_number", phone);

            HttpEntity<MultiValueMap<String, String>> entity = new HttpEntity<>(body, headers);

            log.info("发送短信验证码: phone={}, templateId={}, apiUrl={}", phone, config.templateId, config.apiUrl);
            ResponseEntity<String> response = restTemplate.exchange(
                    config.apiUrl, HttpMethod.POST, entity, String.class);

            long costMs = System.currentTimeMillis() - startTime;
            String responseBody = response.getBody();
            log.info("短信API响应: httpStatus={}, body={}", response.getStatusCode(), responseBody);

            if (responseBody != null) {
                JsonNode root = objectMapper.readTree(responseBody);
                String status = root.path("status").asText("");
                boolean success = "OK".equalsIgnoreCase(status);
                String requestId = root.path("request_id").asText("");

                logApiCall("SEND_SMS", phone, requestInfo, responseBody, success,
                        success ? null : status, costMs);

                if (success) {
                    log.info("短信发送成功: phone={}, requestId={}", phone, requestId);
                    return SmsResult.ok(requestId);
                } else {
                    String msg = root.path("msg").asText(root.path("message").asText(status));
                    log.warn("短信发送失败: phone={}, status={}, msg={}", phone, status, msg);
                    return SmsResult.fail(msg);
                }
            }

            logApiCall("SEND_SMS", phone, requestInfo, null, false, "响应体为空", costMs);
            return SmsResult.fail("短信接口返回异常: 空响应");

        } catch (HttpClientErrorException e) {
            long costMs = System.currentTimeMillis() - startTime;
            String errorBody = e.getResponseBodyAsString();
            HttpHeaders responseHeaders = e.getResponseHeaders();
            String errorHeader = responseHeaders != null
                    ? responseHeaders.getFirst("X-Ca-Error-Message") : null;
            log.error("短信API HTTP错误: phone={}, status={}, caError={}",
                    phone, e.getStatusCode(), errorHeader, e);
            logApiCall("SEND_SMS", phone, requestInfo, errorBody, false,
                    errorHeader != null ? errorHeader : e.getMessage(), costMs);
            return SmsResult.fail("短信发送失败: " + (errorHeader != null ? errorHeader : e.getStatusCode()));
        } catch (Exception e) {
            long costMs = System.currentTimeMillis() - startTime;
            log.error("短信发送异常: phone={}, error={}", phone, e.getMessage(), e);
            logApiCall("SEND_SMS", phone, requestInfo, null, false, e.getMessage(), costMs);
            return SmsResult.fail("短信发送失败: " + e.getMessage());
        }
    }

    private void logApiCall(String action, String target, String request, String response,
                            boolean success, String errorMsg, long costMs) {
        if (logService != null) {
            try {
                logService.log("SMS_GATEWAY", action, target, request, response, success, errorMsg, costMs);
            } catch (Exception e) {
                log.warn("记录API日志失败: {}", e.getMessage());
            }
        }
    }

    private record SmsConfig(String apiUrl, String appCode, String templateId, boolean enabled) {}
}
