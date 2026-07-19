package com.yicai.trade.module.certification.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.*;
import com.yicai.trade.module.certification.service.CertificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/certification")
@RequiredArgsConstructor
@Tag(name = "认证管理(管理端)", description = "管理员审核企业认证接口")
public class CertificationController {

    private final CertificationService certificationService;

    @GetMapping("/{id}")
    @Operation(summary = "获取认证详情")
    public Result<CertificationResponse> get(@PathVariable Long id) {
        return Result.success(certificationService.getById(id));
    }

    @GetMapping
    @Operation(summary = "分页查询认证列表")
    public Result<PageResult<CertificationResponse>> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String certType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(certificationService.list(status, certType, page, size));
    }

    @PostMapping("/{id}/audit")
    @Operation(summary = "审核认证申请")
    public Result<Void> audit(@PathVariable Long id,
                              @RequestBody Map<String, String> body,
                              @AuthenticationPrincipal UserDetails user) {
        String auditor = user != null ? user.getUsername() : "admin";
        certificationService.audit(id, body.get("action"), body.get("remark"), auditor);
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "认证统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(certificationService.getStats());
    }
}
