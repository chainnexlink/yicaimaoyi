package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "发送验证码请求")
public class SendCodeRequest {

    @NotBlank(message = "目标不能为空")
    @Schema(description = "目标（手机号或邮箱）", example = "13800138000")
    private String target;

    @NotBlank(message = "类型不能为空")
    @Schema(description = "类型: SMS=短信, EMAIL=邮件", example = "SMS")
    private String type;
}
