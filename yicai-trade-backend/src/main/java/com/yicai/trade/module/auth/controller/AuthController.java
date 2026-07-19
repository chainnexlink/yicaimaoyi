package com.yicai.trade.module.auth.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.auth.dto.*;
import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.auth.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "认证管理", description = "用户登录、注册、验证码、微信登录等接口")
public class AuthController {
    
    private final AuthService authService;
    private final UserRepository userRepository;
    
    @PostMapping("/login")
    @Operation(summary = "密码登录", description = "通过账号（用户名/邮箱/手机号）和密码进行登录")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "登录成功"),
            @ApiResponse(responseCode = "401", description = "用户名或密码错误")
    })
    public Result<TokenResponse> login(
            @Parameter(description = "登录请求参数") @Valid @RequestBody LoginRequest request) {
        return Result.success(authService.login(request));
    }
    
    @PostMapping("/register")
    @Operation(summary = "用户注册", description = "注册新用户，支持密码/邮箱验证码/手机验证码三种方式")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "注册成功"),
            @ApiResponse(responseCode = "400", description = "参数校验失败或用户已存在")
    })
    public Result<TokenResponse> register(
            @Parameter(description = "注册请求参数") @Valid @RequestBody RegisterRequest request) {
        return Result.success(authService.register(request));
    }

    @PostMapping("/send-code")
    @Operation(summary = "发送验证码", description = "发送短信或邮箱验证码，用于注册和验证码登录")
    public Result<Void> sendVerificationCode(@Valid @RequestBody SendCodeRequest request) {
        authService.sendVerificationCode(request);
        return Result.success();
    }

    @PostMapping("/code-login")
    @Operation(summary = "验证码登录", description = "通过手机/邮箱验证码登录，未注册用户自动创建账号")
    public Result<TokenResponse> codeLogin(@Valid @RequestBody CodeLoginRequest request) {
        return Result.success(authService.codeLogin(request));
    }

    @PostMapping("/wechat/login")
    @Operation(summary = "微信登录", description = "通过微信OAuth授权码登录，未绑定手机号返回needBindPhone=true")
    public Result<TokenResponse> wechatLogin(@Valid @RequestBody WechatLoginRequest request) {
        return Result.success(authService.wechatLogin(request));
    }

    @PostMapping("/wechat/bind-phone")
    @Operation(summary = "微信登录绑定手机号", description = "微信首次登录需绑定手机号，验证短信验证码后完成注册/绑定")
    public Result<TokenResponse> wechatBindPhone(@Valid @RequestBody WechatBindPhoneRequest request) {
        return Result.success(authService.wechatBindPhone(request));
    }

    @GetMapping("/wechat/auth-url")
    @Operation(summary = "获取微信授权URL", description = "获取微信扫码登录的授权页面URL")
    public Result<Map<String, String>> getWechatAuthUrl(@RequestParam String redirectUri) {
        String url = authService.getWechatAuthUrl(redirectUri);
        return Result.success(Map.of("authUrl", url != null ? url : ""));
    }
    
    @PostMapping("/refresh")
    @Operation(summary = "刷新令牌")
    public Result<TokenResponse> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request) {
        return Result.success(authService.refreshToken(request));
    }

    @GetMapping("/me")
    @Operation(summary = "获取当前用户信息", description = "获取当前登录用户的详细资料")
    public Result<UserProfileResponse> getCurrentUser(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        
        return Result.success(UserProfileResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phone(user.getPhone())
                .realName(user.getRealName())
                .avatarUrl(user.getAvatarUrl())
                .userType(user.getUserType())
                .status(user.getStatus())
                .emailVerified(user.getEmailVerified())
                .phoneVerified(user.getPhoneVerified())
                .loginType(user.getLoginType())
                .wechatBound(user.getWechatOpenId() != null && !user.getWechatOpenId().isEmpty())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build());
    }
    
    @PostMapping("/logout")
    @Operation(summary = "用户登出")
    public Result<Void> logout(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        authService.logout(token);
        return Result.success();
    }
}
