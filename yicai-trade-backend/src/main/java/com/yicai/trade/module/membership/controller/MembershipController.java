package com.yicai.trade.module.membership.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.membership.dto.MembershipResponse;
import com.yicai.trade.module.membership.service.MembershipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/membership")
@RequiredArgsConstructor
@Tag(name = "会员管理", description = "会员等级与积分管理接口")
public class MembershipController {

    private final MembershipService membershipService;

    @GetMapping("/user/{userId}")
    @Operation(summary = "获取用户会员信息")
    public Result<MembershipResponse> getByUser(@PathVariable Long userId) {
        return Result.success(membershipService.getByUserId(userId));
    }

    @GetMapping
    @Operation(summary = "分页查询会员列表")
    public Result<PageResult<MembershipResponse>> list(
            @RequestParam(required = false) String level,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(membershipService.list(level, page, size));
    }

    @PatchMapping("/{id}/level")
    @Operation(summary = "更新会员等级")
    public Result<Void> updateLevel(@PathVariable Long id, @RequestBody Map<String, String> body) {
        membershipService.updateLevel(id, body.get("level"));
        return Result.success(null);
    }

    @PostMapping("/{id}/points")
    @Operation(summary = "增加积分")
    public Result<Void> addPoints(@PathVariable Long id, @RequestBody Map<String, Integer> body) {
        membershipService.addPoints(id, body.get("points"));
        return Result.success(null);
    }

    @GetMapping("/stats")
    @Operation(summary = "会员统计")
    public Result<Map<String, Long>> stats() {
        return Result.success(membershipService.getStats());
    }
}
