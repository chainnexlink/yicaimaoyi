package com.yicai.trade.module.user.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.user.dto.UserResponse;
import com.yicai.trade.module.user.dto.UserUpdateRequest;
import com.yicai.trade.module.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user/profile")
@RequiredArgsConstructor
@Tag(name = "UserProfile")
public class UserProfileController {

    private final UserService userService;

    @GetMapping
    @Operation(summary = "Get profile")
    public Result<UserResponse> getProfile(@AuthenticationPrincipal UserDetails user) {
        Long userId = Long.parseLong(user.getUsername());
        return Result.success(userService.getUserById(userId));
    }

    @PutMapping
    @Operation(summary = "Update profile")
    public Result<UserResponse> updateProfile(@AuthenticationPrincipal UserDetails user,
                                              @RequestBody UserUpdateRequest request) {
        Long userId = Long.parseLong(user.getUsername());
        return Result.success(userService.updateUser(userId, request));
    }
}
