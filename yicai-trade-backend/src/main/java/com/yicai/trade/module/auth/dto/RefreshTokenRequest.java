package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Schema(name = "刷新令牌请求", description = "刷新令牌请求参数")
public class RefreshTokenRequest {
    
    @NotBlank(message = "刷新令牌不能为空")
    @Schema(description = "刷新令牌", example = "a1b2c3d4-e5f6-7890-abcd-ef1234567890", requiredMode = Schema.RequiredMode.REQUIRED)
    private String refreshToken;
}
