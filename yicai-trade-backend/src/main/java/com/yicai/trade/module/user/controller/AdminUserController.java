package com.yicai.trade.module.user.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.user.dto.UserListRequest;
import com.yicai.trade.module.user.dto.UserResponse;
import com.yicai.trade.module.user.dto.UserUpdateRequest;
import com.yicai.trade.module.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@Tag(name = "AdminUser", description = "Admin user management")
public class AdminUserController {

    private final UserService userService;

    @GetMapping
    @Operation(summary = "List users")
    public Result<PageResult<UserResponse>> listUsers(UserListRequest request) {
        return Result.success(userService.listUsers(request));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get user detail")
    public Result<UserResponse> getUser(@PathVariable Long id) {
        return Result.success(userService.getUserById(id));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update user")
    public Result<UserResponse> updateUser(@PathVariable Long id, @RequestBody UserUpdateRequest request) {
        return Result.success(userService.updateUser(id, request));
    }

    @PutMapping("/{id}/status")
    @Operation(summary = "Update user status")
    public Result<Void> updateUserStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        userService.updateUserStatus(id, body.get("status"));
        return Result.success();
    }

    @PostMapping("/{id}/reset-password")
    @Operation(summary = "Reset password")
    public Result<Void> resetPassword(@PathVariable Long id, @RequestBody Map<String, String> body) {
        userService.resetPassword(id, body.get("newPassword"));
        return Result.success();
    }
}
