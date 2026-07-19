package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(name = "令牌响应", description = "登录/注册成功后返回的令牌信息")
public class TokenResponse {
    
    @Schema(description = "访问令牌（JWT）", example = "eyJhbGciOiJIUzUxMiJ9...")
    private String accessToken;
    
    @Schema(description = "刷新令牌（用于获取新的访问令牌）", example = "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
    private String refreshToken;
    
    @Schema(description = "令牌类型", example = "Bearer")
    private String tokenType;
    
    @Schema(description = "访问令牌有效期（秒）", example = "900")
    private long expiresIn;
    
    @Schema(description = "当前登录用户信息")
    private UserInfo user;

    @Schema(description = "是否需要绑定手机号（微信登录）")
    private Boolean needBindPhone;

    @Schema(description = "微信临时令牌（用于绑定手机号）")
    private String wechatToken;

    @Schema(description = "是否为新注册用户")
    private Boolean isNewUser;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @Schema(name = "用户信息", description = "当前登录用户的基本信息")
    public static class UserInfo {
        @Schema(description = "用户ID", example = "1")
        private Long id;
        
        @Schema(description = "用户名", example = "zhangsan")
        private String username;
        
        @Schema(description = "邮箱", example = "zhangsan@example.com")
        private String email;
        
        @Schema(description = "手机号", example = "13800138000")
        private String phone;
        
        @Schema(description = "真实姓名", example = "张三")
        private String realName;
        
        @Schema(description = "头像地址")
        private String avatarUrl;
        
        @Schema(description = "用户类型（BUYER/SUPPLIER）", example = "BUYER")
        private String userType;

        @Schema(description = "采购商业务主体ID")
        private Long buyerId;

        @Schema(description = "供应商业务主体ID")
        private Long supplierId;
    }
}
