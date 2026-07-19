package com.yicai.trade.module.notification.verification;

/**
 * 验证码服务接口
 */
public interface VerificationCodeService {

    /**
     * 生成并缓存验证码
     *
     * @param target 目标（手机号/邮箱）
     * @param type   类型（SMS/EMAIL）
     * @return 生成的6位验证码
     */
    String generateCode(String target, String type);

    /**
     * 验证码校验
     *
     * @param target 目标
     * @param type   类型
     * @param code   用户输入的验证码
     * @return 是否正确
     */
    boolean verifyCode(String target, String type, String code);
}
