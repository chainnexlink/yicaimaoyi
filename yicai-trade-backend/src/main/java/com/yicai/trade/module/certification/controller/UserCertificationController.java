package com.yicai.trade.module.certification.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.certification.dto.*;
import com.yicai.trade.module.certification.service.CertificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/certification")
@RequiredArgsConstructor
@Tag(name = "企业资质认证(用户端)", description = "用户提交和查看企业认证")
public class UserCertificationController {

    private final CertificationService certificationService;

    @PostMapping
    @Operation(summary = "提交认证申请")
    public Result<CertificationResponse> create(@AuthenticationPrincipal UserDetails user,
                                                 @RequestBody CertificationRequest request) {
        Long userId = Long.parseLong(user.getUsername());
        return Result.success(certificationService.create(userId, request));
    }

    @GetMapping
    @Operation(summary = "查看我的认证列表")
    public Result<List<CertificationResponse>> myList(@AuthenticationPrincipal UserDetails user) {
        Long userId = Long.parseLong(user.getUsername());
        return Result.success(certificationService.getMyList(userId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "查看认证详情")
    public Result<CertificationResponse> detail(@PathVariable Long id) {
        return Result.success(certificationService.getById(id));
    }
}
