package com.yicai.trade.module.notification.email;

import com.yicai.trade.module.thirdparty.service.ThirdPartyLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

/**
 * SMTP邮件发送服务实现
 */
@Slf4j
@Service
public class SmtpEmailService implements EmailService {

    @Value("${spring.mail.username:}")
    private String fromEmail;

    @Value("${email.enabled:false}")
    private boolean enabled;

    @Value("${email.from-name:易采贸易平台}")
    private String fromName;

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Autowired(required = false)
    private ThirdPartyLogService logService;

    @Override
    public boolean sendVerificationCode(String toEmail, String code) {
        if (!enabled || mailSender == null) {
            log.warn("邮件服务未启用或未配置");
            return false;
        }

        String subject = "【易采贸易】邮箱验证码";
        String content = buildVerificationEmailHtml(code);
        return sendHtmlEmail(toEmail, subject, content);
    }

    @Override
    public boolean sendWelcomeEmail(String toEmail, String username) {
        if (!enabled || mailSender == null) {
            return false;
        }

        String subject = "欢迎注册易采贸易平台 / Welcome to YiCai Trade";
        String content = buildWelcomeEmailHtml(username);
        return sendHtmlEmail(toEmail, subject, content);
    }

    private boolean sendHtmlEmail(String toEmail, String subject, String htmlContent) {
        long startTime = System.currentTimeMillis();
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);

            long costMs = System.currentTimeMillis() - startTime;
            log.info("邮件发送成功: to={}, subject={}, cost={}ms", toEmail, subject, costMs);
            logApiCall("SEND_EMAIL", toEmail, subject, null, true, null, costMs);
            return true;

        } catch (Exception e) {
            long costMs = System.currentTimeMillis() - startTime;
            log.error("邮件发送失败: to={}, error={}", toEmail, e.getMessage(), e);
            logApiCall("SEND_EMAIL", toEmail, subject, null, false, e.getMessage(), costMs);
            return false;
        }
    }

    private String buildVerificationEmailHtml(String code) {
        return """
            <!DOCTYPE html>
            <html>
            <head><meta charset="UTF-8"></head>
            <body style="font-family: 'Segoe UI', Arial, sans-serif; background: #f4f7fa; margin: 0; padding: 20px;">
              <div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08);">
                <div style="background: linear-gradient(135deg, #1a73e8, #0d47a1); padding: 32px 24px; text-align: center;">
                  <h1 style="color: #fff; margin: 0; font-size: 22px;">易采贸易 YiCai Trade</h1>
                </div>
                <div style="padding: 32px 24px; text-align: center;">
                  <p style="color: #333; font-size: 16px; margin-bottom: 8px;">您的邮箱验证码是 / Your verification code:</p>
                  <div style="background: #f0f4ff; border-radius: 8px; padding: 16px; margin: 20px 0;">
                    <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1a73e8;">%s</span>
                  </div>
                  <p style="color: #888; font-size: 14px;">验证码有效期5分钟，请勿泄露给他人</p>
                  <p style="color: #888; font-size: 14px;">This code is valid for 5 minutes. Do not share it.</p>
                </div>
                <div style="background: #f8f9fa; padding: 16px 24px; text-align: center; font-size: 12px; color: #aaa;">
                  &copy; 2026 YiCai Trade Platform. All rights reserved.
                </div>
              </div>
            </body>
            </html>
            """.formatted(code);
    }

    private String buildWelcomeEmailHtml(String username) {
        return """
            <!DOCTYPE html>
            <html>
            <head><meta charset="UTF-8"></head>
            <body style="font-family: 'Segoe UI', Arial, sans-serif; background: #f4f7fa; margin: 0; padding: 20px;">
              <div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08);">
                <div style="background: linear-gradient(135deg, #1a73e8, #0d47a1); padding: 32px 24px; text-align: center;">
                  <h1 style="color: #fff; margin: 0; font-size: 22px;">Welcome to YiCai Trade</h1>
                </div>
                <div style="padding: 32px 24px;">
                  <p style="color: #333; font-size: 16px;">Hi %s,</p>
                  <p style="color: #555; line-height: 1.6;">感谢您注册易采贸易平台！我们致力于为全球采购商和供应商提供智能匹配、电子反拍和订单监控等一站式贸易服务。</p>
                  <p style="color: #555; line-height: 1.6;">Thank you for joining YiCai Trade! We provide smart matching, e-auction and order monitoring services for global buyers and suppliers.</p>
                </div>
                <div style="background: #f8f9fa; padding: 16px 24px; text-align: center; font-size: 12px; color: #aaa;">
                  &copy; 2026 YiCai Trade Platform. All rights reserved.
                </div>
              </div>
            </body>
            </html>
            """.formatted(username);
    }

    private void logApiCall(String action, String target, String request, String response,
                            boolean success, String errorMsg, long costMs) {
        if (logService != null) {
            try {
                logService.log("EMAIL_SERVICE", action, target, request, response, success, errorMsg, costMs);
            } catch (Exception e) {
                log.warn("记录邮件日志失败: {}", e.getMessage());
            }
        }
    }
}
