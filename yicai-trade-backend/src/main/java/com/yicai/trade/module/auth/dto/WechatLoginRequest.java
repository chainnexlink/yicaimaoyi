package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "微信登录请求")
public class WechatLoginRequest {

    @NotBlank(message = "微信授权码不能为空")
    @Schema(description = "微信OAuth授权码")
    private String code;

    @Schema(description = "用户类型: BUYER/SUPPLIER", example = "BUYER")
    private String userType;
}
