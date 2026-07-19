package com.yicai.trade.module.notification.sms;

/**
 * 短信发送网关接口
 */
public interface SmsGateway {

    /**
     * 发送短信验证码
     *
     * @param phone 手机号
     * @param code  验证码
     * @return 发送结果
     */
    SmsResult sendVerificationCode(String phone, String code);

    /**
     * 短信发送结果
     */
    record SmsResult(boolean success, String message, String smsId) {
        public static SmsResult ok(String smsId) {
            return new SmsResult(true, "发送成功", smsId);
        }

        public static SmsResult fail(String message) {
            return new SmsResult(false, message, null);
        }
    }
}
