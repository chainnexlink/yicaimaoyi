package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "登录请求", description = "用户登录请求参数")
public class LoginRequest {
    
    @NotBlank(message = "账号不能为空")
    @Schema(description = "登录账号（用户名/邮箱/手机号）", example = "admin", requiredMode = Schema.RequiredMode.REQUIRED)
    private String account;
    
    @NotBlank(message = "密码不能为空")
    @Schema(description = "登录密码", example = "your-password", requiredMode = Schema.RequiredMode.REQUIRED)
    private String password;
    
    @Schema(description = "用户类型（BUYER-采购商/SUPPLIER-供应商）", example = "BUYER")
    private String userType;
}
