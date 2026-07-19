package com.yicai.trade.module.notification.email;

/**
 * 邮件发送服务接口
 */
public interface EmailService {

    /**
     * 发送邮箱验证码
     */
    boolean sendVerificationCode(String toEmail, String code);

    /**
     * 发送欢迎邮件
     */
    boolean sendWelcomeEmail(String toEmail, String username);
}
