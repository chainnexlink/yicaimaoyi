package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "微信绑定手机号请求")
public class WechatBindPhoneRequest {

    @NotBlank(message = "微信临时令牌不能为空")
    @Schema(description = "微信登录返回的临时令牌")
    private String wechatToken;

    @NotBlank(message = "手机号不能为空")
    @Schema(description = "手机号码")
    private String phone;

    @NotBlank(message = "验证码不能为空")
    @Schema(description = "短信验证码")
    private String code;

    @Schema(description = "用户类型: BUYER/SUPPLIER", example = "BUYER")
    private String userType;
}
