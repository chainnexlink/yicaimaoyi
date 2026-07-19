package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "验证码登录请求")
public class CodeLoginRequest {

    @NotBlank(message = "账号不能为空")
    @Schema(description = "手机号或邮箱", example = "13800138000")
    private String account;

    @NotBlank(message = "验证码不能为空")
    @Schema(description = "6位验证码", example = "123456")
    private String code;

    @Schema(description = "验证类型: SMS=短信, EMAIL=邮件", example = "SMS")
    private String type;

    @Schema(description = "用户类型: BUYER/SUPPLIER", example = "BUYER")
    private String userType;
}
