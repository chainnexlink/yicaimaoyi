package com.yicai.trade.module.user.service.impl;

import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.entity.UserRole;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.user.dto.UserListRequest;
import com.yicai.trade.module.user.dto.UserResponse;
import com.yicai.trade.module.user.dto.UserUpdateRequest;
import com.yicai.trade.module.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public PageResult<UserResponse> listUsers(UserListRequest request) {
        PageRequest pageRequest = PageRequest.of(request.getPage(), request.getSize(),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<User> users = userRepository.findAll(pageRequest);
        return PageResult.of(
                users.getContent().stream().map(this::toResponse).collect(Collectors.toList()),
                users.getTotalElements(), request.getPage(), request.getSize());
    }

    @Override
    @SuppressWarnings("null")
    public UserResponse getUserById(@lombok.NonNull Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return toResponse(user);
    }

    @Override
    public UserResponse getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        return toResponse(user);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public UserResponse updateUser(@lombok.NonNull Long id, UserUpdateRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        if (request.getEmail() != null) user.setEmail(request.getEmail());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        if (request.getRealName() != null) user.setRealName(request.getRealName());
        if (request.getAvatarUrl() != null) user.setAvatarUrl(request.getAvatarUrl());
        return toResponse(userRepository.save(user));
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void updateUserStatus(@lombok.NonNull Long id, String status) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        user.setStatus(status);
        userRepository.save(user);
    }

    @Override
    @Transactional
    @SuppressWarnings("null")
    public void resetPassword(@lombok.NonNull Long id, String newPassword) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    private UserResponse toResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .phone(user.getPhone())
                .realName(user.getRealName())
                .avatarUrl(user.getAvatarUrl())
                .userType(user.getUserType())
                .status(user.getStatus())
                .roles(user.getRoles().stream().map(UserRole::getRoleCode).collect(Collectors.toList()))
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
