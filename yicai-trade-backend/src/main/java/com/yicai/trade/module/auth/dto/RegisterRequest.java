package com.yicai.trade.module.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(name = "注册请求", description = "用户注册请求参数")
public class RegisterRequest {
    
    @NotBlank(message = "用户名不能为空")
    @Size(min = 3, max = 50, message = "用户名长度必须在3-50之间")
    @Schema(description = "用户名（3-50个字符）", example = "zhangsan", requiredMode = Schema.RequiredMode.REQUIRED)
    private String username;
    
    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 100, message = "密码长度必须在6-100之间")
    @Schema(description = "密码（6-100个字符）", example = "123456", requiredMode = Schema.RequiredMode.REQUIRED)
    private String password;
    
    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱地址", example = "zhangsan@example.com")
    private String email;
    
    @Pattern(regexp = "^\\+?\\d{7,15}$", message = "手机号格式不正确")
    @Schema(description = "手机号码（支持国际区号，如+8613800138000）", example = "+8613800138000")
    private String phone;
    
    @Schema(description = "真实姓名", example = "张三")
    private String realName;
    
    @NotBlank(message = "用户类型不能为空")
    @Pattern(regexp = "(?i)^(BUYER|SUPPLIER)$", message = "用户类型仅支持BUYER或SUPPLIER")
    @Schema(description = "用户类型：BUYER-采购商，SUPPLIER-供应商", example = "BUYER", requiredMode = Schema.RequiredMode.REQUIRED)
    private String userType;
    
    @Schema(description = "公司名称", example = "深圳XX科技有限公司")
    private String companyName;

    @Schema(description = "验证码（邮箱或手机注册时必填）", example = "123456")
    private String verificationCode;

    @Schema(description = "注册方式: PASSWORD/EMAIL/PHONE", example = "EMAIL")
    private String loginType;
}
