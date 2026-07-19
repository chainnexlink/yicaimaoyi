package com.yicai.trade.module.user.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.user.dto.UserListRequest;
import com.yicai.trade.module.user.dto.UserResponse;
import com.yicai.trade.module.user.dto.UserUpdateRequest;

public interface UserService {
    PageResult<UserResponse> listUsers(UserListRequest request);
    UserResponse getUserById(Long id);
    UserResponse getUserByUsername(String username);
    UserResponse updateUser(Long id, UserUpdateRequest request);
    void updateUserStatus(Long id, String status);
    void resetPassword(Long id, String newPassword);
}
