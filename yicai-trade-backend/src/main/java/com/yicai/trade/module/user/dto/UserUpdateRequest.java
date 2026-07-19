package com.yicai.trade.module.user.dto;

import lombok.Data;

@Data
public class UserUpdateRequest {
    private String email;
    private String phone;
    private String realName;
    private String avatarUrl;
}
