package com.yicai.trade.module.user.dto;

import lombok.Data;

@Data
public class UserListRequest {
    private int page = 0;
    private int size = 10;
    private String keyword;
    private String status;
    private String userType;
}
