package com.yicai.trade.module.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileResponse {
    private Long id;
    private String username;
    private String email;
    private String phone;
    private String realName;
    private String avatarUrl;
    private String userType;
    private String status;
    private Boolean emailVerified;
    private Boolean phoneVerified;
    private String loginType;
    private Boolean wechatBound;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
