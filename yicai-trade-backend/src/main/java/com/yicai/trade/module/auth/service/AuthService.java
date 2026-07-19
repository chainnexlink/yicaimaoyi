package com.yicai.trade.module.auth.service;

import com.yicai.trade.module.auth.dto.*;

public interface AuthService {
    
    TokenResponse login(LoginRequest request);
    
    TokenResponse register(RegisterRequest request);
    
    TokenResponse refreshToken(RefreshTokenRequest request);
    
    void logout(String token);

    /** 发送验证码（短信/邮箱） */
    void sendVerificationCode(SendCodeRequest request);

    /** 验证码登录（手机号/邮箱） */
    TokenResponse codeLogin(CodeLoginRequest request);

    /** 微信OAuth登录 */
    TokenResponse wechatLogin(WechatLoginRequest request);

    /** 微信登录绑定手机号 */
    TokenResponse wechatBindPhone(WechatBindPhoneRequest request);

    /** 获取微信OAuth授权URL */
    String getWechatAuthUrl(String redirectUri);
}
