package com.yicai.trade.module.auth.service.impl;

import com.yicai.trade.common.constant.UserRoleEnum;
import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.security.JwtTokenProvider;
import com.yicai.trade.module.auth.dto.*;
import com.yicai.trade.module.auth.entity.RefreshToken;
import com.yicai.trade.module.auth.entity.User;
import com.yicai.trade.module.auth.entity.UserRole;
import com.yicai.trade.module.auth.repository.RefreshTokenRepository;
import com.yicai.trade.module.auth.repository.UserRepository;
import com.yicai.trade.module.auth.service.AuthService;
import com.yicai.trade.module.auction.service.AuctionDepositService;
import com.yicai.trade.module.buyer.entity.Buyer;
import com.yicai.trade.module.buyer.repository.BuyerRepository;
import com.yicai.trade.module.notification.email.EmailService;
import com.yicai.trade.module.notification.sms.SmsGateway;
import com.yicai.trade.module.notification.verification.VerificationCodeService;
import com.yicai.trade.module.supplier.entity.Supplier;
import com.yicai.trade.module.supplier.repository.SupplierRepository;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    
    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final BuyerRepository buyerRepository;
    private final SupplierRepository supplierRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final AuctionDepositService auctionDepositService;
    private final VerificationCodeService verificationCodeService;
    private final SmsGateway smsGateway;
    private final EmailService emailService;
    @Autowired(required = false)
    private StringRedisTemplate stringRedisTemplate;

    @Value("${wechat.oauth.app-id:}")
    private String wechatAppId;

    @Value("${wechat.oauth.app-secret:}")
    private String wechatAppSecret;

    @Value("${wechat.oauth.enabled:false}")
    private boolean wechatEnabled;
    
    // ==================== 原有方法 ====================

    @Override
    @Transactional
    @SuppressWarnings("null")
    public TokenResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getAccount(), request.getPassword())
        );
        
        User user = userRepository.findByUsername(request.getAccount())
                .or(() -> userRepository.findByEmail(request.getAccount()))
                .or(() -> userRepository.findByPhone(request.getAccount()))
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        
        if (!"ACTIVE".equals(user.getStatus())) {
            throw new BusinessException(ErrorCode.AUTH_USER_DISABLED);
        }
        
        String accessToken = jwtTokenProvider.generateAccessToken(authentication);
        String refreshToken = createRefreshToken(user.getId());
        
        return buildTokenResponse(user, accessToken, refreshToken);
    }
    
    @Override
    @Transactional
    @SuppressWarnings("null")
    public TokenResponse register(RegisterRequest request) {
        String userType = request.getUserType().toUpperCase(java.util.Locale.ROOT);
        if (!"BUYER".equals(userType) && !"SUPPLIER".equals(userType)) {
            throw new BusinessException(ErrorCode.INVALID_PARAMETER);
        }
        // 验证码校验（邮箱或手机注册时）
        if (request.getVerificationCode() != null && !request.getVerificationCode().isEmpty()) {
            String verifyTarget = null;
            String verifyType = null;

            if ("EMAIL".equalsIgnoreCase(request.getLoginType()) && request.getEmail() != null) {
                verifyTarget = request.getEmail();
                verifyType = "EMAIL";
            } else if ("PHONE".equalsIgnoreCase(request.getLoginType()) && request.getPhone() != null) {
                verifyTarget = request.getPhone();
                verifyType = "SMS";
            }

            if (verifyTarget != null) {
                boolean valid = verificationCodeService.verifyCode(verifyTarget, verifyType, request.getVerificationCode());
                if (!valid) {
                    throw new BusinessException(ErrorCode.AUTH_VERIFICATION_FAILED);
                }
            }
        }

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BusinessException(ErrorCode.AUTH_USER_EXISTS);
        }
        if (request.getEmail() != null && userRepository.existsByEmail(request.getEmail())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_EXISTS);
        }
        if (request.getPhone() != null && userRepository.existsByPhone(request.getPhone())) {
            throw new BusinessException(ErrorCode.AUTH_PHONE_EXISTS);
        }
        
        User user = User.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .email(request.getEmail())
                .phone(request.getPhone())
                .realName(request.getRealName())
                .userType(userType)
                .status("ACTIVE")
                .emailVerified("EMAIL".equalsIgnoreCase(request.getLoginType()))
                .phoneVerified("PHONE".equalsIgnoreCase(request.getLoginType()))
                .loginType(request.getLoginType() != null ? request.getLoginType() : "PASSWORD")
                .build();
        
        UserRole role = UserRole.builder()
                .roleCode(getRoleCode(userType))
                .build();
        user.addRole(role);
        
        user = userRepository.save(user);

        // 如果是采购商，创建对应的 Buyer 记录
        if ("BUYER".equalsIgnoreCase(user.getUserType())) {
            createBuyerProfile(user);
        }
        // 如果是供应商，创建对应的 Supplier 记录
        if ("SUPPLIER".equalsIgnoreCase(user.getUserType())) {
            createSupplierProfile(user, request.getCompanyName());
        }

        // 注册赠送押金抵用券
        try {
            auctionDepositService.issueRegisterVouchers(user.getId(), userType);
        } catch (Exception e) {
            log.warn("注册赠送抵用券失败: {}", e.getMessage());
        }

        // 发送欢迎邮件
        if (user.getEmail() != null && !user.getEmail().isEmpty()) {
            try {
                emailService.sendWelcomeEmail(user.getEmail(), user.getUsername());
            } catch (Exception e) {
                log.warn("发送欢迎邮件失败: {}", e.getMessage());
            }
        }
        
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId().toString());
        String refreshToken = createRefreshToken(user.getId());
        
        return buildTokenResponse(user, accessToken, refreshToken, true);
    }
    
    @Override
    @Transactional
    @SuppressWarnings("null")
    public TokenResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken storedToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_TOKEN_INVALID));
        
        if (storedToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            refreshTokenRepository.delete(storedToken);
            throw new BusinessException(ErrorCode.AUTH_TOKEN_EXPIRED);
        }
        
        User user = userRepository.findById(Objects.requireNonNull(storedToken.getUserId()))
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        
        refreshTokenRepository.delete(storedToken);
        
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId().toString());
        String newRefreshToken = createRefreshToken(user.getId());
        
        return buildTokenResponse(user, accessToken, newRefreshToken);
    }
    
    @Override
    @Transactional
    public void logout(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
        }
        if (token != null) {
            try {
                String subject = jwtTokenProvider.getUsernameFromToken(token);
                User user;
                try {
                    user = userRepository.findById(Long.parseLong(subject)).orElse(null);
                } catch (NumberFormatException ignored) {
                    user = userRepository.findByUsername(subject).orElse(null);
                }
                if (user != null) {
                    refreshTokenRepository.deleteByUserId(user.getId());
                }
            } catch (Exception e) {
                log.warn("登出失败: {}", e.getMessage());
            }
        }
    }

    // ==================== 新增方法 ====================

    @Override
    public void sendVerificationCode(SendCodeRequest request) {
        String target = request.getTarget();
        String type = request.getType().toUpperCase();

        String code = verificationCodeService.generateCode(target, type);

        if ("SMS".equals(type)) {
            SmsGateway.SmsResult result = smsGateway.sendVerificationCode(target, code);
            if (!result.success()) {
                throw new BusinessException(ErrorCode.AUTH_SMS_SEND_FAILED);
            }
            log.info("短信验证码已发送: phone={}", target);
        } else if ("EMAIL".equals(type)) {
            boolean sent = emailService.sendVerificationCode(target, code);
            if (!sent) {
                throw new BusinessException(ErrorCode.AUTH_EMAIL_SEND_FAILED);
            }
            log.info("邮箱验证码已发送: email={}", target);
        } else {
            throw new BusinessException(ErrorCode.INVALID_PARAMETER);
        }
    }

    @Override
    @Transactional
    public TokenResponse codeLogin(CodeLoginRequest request) {
        String account = request.getAccount();
        String type = request.getType() != null ? request.getType().toUpperCase() : "SMS";

        // 验证验证码
        boolean valid = verificationCodeService.verifyCode(account, type, request.getCode());
        if (!valid) {
            throw new BusinessException(ErrorCode.AUTH_VERIFICATION_FAILED);
        }

        // 查找用户
        User user;
        if ("SMS".equals(type)) {
            user = userRepository.findByPhone(account).orElse(null);
        } else {
            user = userRepository.findByEmail(account).orElse(null);
        }

        // 用户不存在则自动注册，标记为新用户以触发前端引导流程
        boolean isNewUser = false;
        if (user == null) {
            isNewUser = true;
            String userType = request.getUserType() != null ? request.getUserType() : "BUYER";
            user = User.builder()
                    .username(generateUsername(account, type))
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .phone("SMS".equals(type) ? account : null)
                    .email("EMAIL".equals(type) ? account : null)
                    .userType(userType)
                    .status("ACTIVE")
                    .phoneVerified("SMS".equals(type))
                    .emailVerified("EMAIL".equals(type))
                    .loginType(type.equals("SMS") ? "PHONE" : "EMAIL")
                    .build();

            UserRole role = UserRole.builder()
                    .roleCode(getRoleCode(userType))
                    .build();
            user.addRole(role);
            user = userRepository.save(user);

            // 如果是采购商，创建对应的 Buyer 记录
            if ("BUYER".equalsIgnoreCase(userType)) {
                createBuyerProfile(user);
            }
            // 如果是供应商，创建对应的 Supplier 记录
            if ("SUPPLIER".equalsIgnoreCase(userType)) {
                createSupplierProfile(user, null);
            }

            try {
                auctionDepositService.issueRegisterVouchers(user.getId(), userType);
            } catch (Exception e) {
                log.warn("注册赠送抵用券失败: {}", e.getMessage());
            }

            log.info("验证码登录自动注册用户: account={}, type={}", account, type);
        }

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new BusinessException(ErrorCode.AUTH_USER_DISABLED);
        }

        // 更新验证状态
        if ("SMS".equals(type) && !Boolean.TRUE.equals(user.getPhoneVerified())) {
            user.setPhoneVerified(true);
            userRepository.save(user);
        } else if ("EMAIL".equals(type) && !Boolean.TRUE.equals(user.getEmailVerified())) {
            user.setEmailVerified(true);
            userRepository.save(user);
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user.getId().toString());
        String refreshToken = createRefreshToken(user.getId());
        return buildTokenResponse(user, accessToken, refreshToken, isNewUser);
    }

    @Override
    @Transactional
    public TokenResponse wechatLogin(WechatLoginRequest request) {
        if (!wechatEnabled || wechatAppId.isEmpty()) {
            throw new BusinessException(ErrorCode.AUTH_WECHAT_AUTH_FAILED);
        }

        // 用微信code换取access_token和openid
        WechatTokenInfo tokenInfo = getWechatAccessToken(request.getCode());
        if (tokenInfo == null || tokenInfo.openId == null) {
            throw new BusinessException(ErrorCode.AUTH_WECHAT_AUTH_FAILED);
        }

        // 查找已绑定微信的用户
        User user = userRepository.findByWechatOpenId(tokenInfo.openId).orElse(null);

        if (user != null && user.getPhone() != null && !user.getPhone().isEmpty()) {
            // 已有用户且已绑定手机号，直接登录
            if (!"ACTIVE".equals(user.getStatus())) {
                throw new BusinessException(ErrorCode.AUTH_USER_DISABLED);
            }
            String accessToken = jwtTokenProvider.generateAccessToken(user.getId().toString());
            String refreshToken = createRefreshToken(user.getId());
            return buildTokenResponse(user, accessToken, refreshToken);
        }

        // 未绑定手机号：生成临时wechatToken，存入Redis，要求前端绑定手机号
        WechatUserInfo userInfo = getWechatUserInfo(tokenInfo.accessToken, tokenInfo.openId);
        String wechatTempToken = UUID.randomUUID().toString().replace("-", "");

        if (stringRedisTemplate == null) {
            throw new BusinessException(ErrorCode.AUTH_WECHAT_AUTH_FAILED, "微信登录缓存服务暂不可用");
        }

        String redisKey = "wechat:bindphone:" + wechatTempToken;
        String redisValue = tokenInfo.openId + "|" + (tokenInfo.unionId != null ? tokenInfo.unionId : "")
                + "|" + (userInfo != null && userInfo.nickname != null ? userInfo.nickname : "")
                + "|" + (userInfo != null && userInfo.headImgUrl != null ? userInfo.headImgUrl : "")
                + "|" + (user != null ? user.getId() : "");
        stringRedisTemplate.opsForValue().set(redisKey, redisValue, 10, java.util.concurrent.TimeUnit.MINUTES);

        log.info("微信登录需绑定手机号: openId={}", tokenInfo.openId);

        return TokenResponse.builder()
                .needBindPhone(true)
                .wechatToken(wechatTempToken)
                .build();
    }

    @Override
    @Transactional
    public TokenResponse wechatBindPhone(WechatBindPhoneRequest request) {
        if (stringRedisTemplate == null) {
            throw new BusinessException(ErrorCode.AUTH_WECHAT_AUTH_FAILED, "微信登录缓存服务暂不可用");
        }
        String redisKey = "wechat:bindphone:" + request.getWechatToken();
        String redisValue = stringRedisTemplate.opsForValue().get(redisKey);
        if (redisValue == null) {
            throw new BusinessException(ErrorCode.AUTH_WECHAT_AUTH_FAILED, "微信授权已过期，请重新扫码");
        }

        // 验证短信验证码
        if (!verificationCodeService.verifyCode(request.getPhone(), "SMS", request.getCode())) {
            throw new BusinessException(ErrorCode.AUTH_VERIFICATION_FAILED);
        }

        String[] parts = redisValue.split("\\|", -1);
        String openId = parts[0];
        String unionId = parts.length > 1 ? parts[1] : null;
        String nickname = parts.length > 2 ? parts[2] : null;
        String headImgUrl = parts.length > 3 ? parts[3] : null;
        String existingUserId = parts.length > 4 ? parts[4] : "";

        User user;
        User phoneUser = userRepository.findByPhone(request.getPhone()).orElse(null);
        boolean isNewUser = false;

        if (!existingUserId.isEmpty()) {
            user = userRepository.findById(Long.parseLong(existingUserId))
                    .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
            user.setPhone(request.getPhone());
            user.setPhoneVerified(true);
            user = userRepository.save(user);
        } else if (phoneUser != null) {
            user = phoneUser;
            user.setWechatOpenId(openId);
            if (unionId != null && !unionId.isEmpty()) user.setWechatUnionId(unionId);
            if (nickname != null && !nickname.isEmpty() && user.getRealName() == null) user.setRealName(nickname);
            if (headImgUrl != null && !headImgUrl.isEmpty() && user.getAvatarUrl() == null) user.setAvatarUrl(headImgUrl);
            user = userRepository.save(user);
        } else {
            isNewUser = true;
            String userType = request.getUserType() != null ? request.getUserType() : "BUYER";
            user = User.builder()
                    .username("wx_" + openId.substring(0, Math.min(8, openId.length())) + "_" + System.currentTimeMillis() % 10000)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .phone(request.getPhone())
                    .phoneVerified(true)
                    .realName(nickname != null && !nickname.isEmpty() ? nickname : null)
                    .avatarUrl(headImgUrl != null && !headImgUrl.isEmpty() ? headImgUrl : null)
                    .wechatOpenId(openId)
                    .wechatUnionId(unionId != null && !unionId.isEmpty() ? unionId : null)
                    .userType(userType)
                    .status("ACTIVE")
                    .loginType("WECHAT")
                    .build();
            UserRole role = UserRole.builder().roleCode(getRoleCode(userType)).build();
            user.addRole(role);
            user = userRepository.save(user);
            if ("BUYER".equalsIgnoreCase(userType)) createBuyerProfile(user);
            if ("SUPPLIER".equalsIgnoreCase(userType)) createSupplierProfile(user, null);

            // 注册赠送押金抵用券
            try {
                auctionDepositService.issueRegisterVouchers(user.getId(), userType);
            } catch (Exception e) {
                log.warn("微信注册赠送抵用券失败: {}", e.getMessage());
            }

            log.info("微信绑定手机号创建新用户: openId={}, phone={}", openId, request.getPhone());
        }

        stringRedisTemplate.delete(redisKey);

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new BusinessException(ErrorCode.AUTH_USER_DISABLED);
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user.getId().toString());
        String refreshToken = createRefreshToken(user.getId());
        return buildTokenResponse(user, accessToken, refreshToken, isNewUser);
    }

    @Override
    public String getWechatAuthUrl(String redirectUri) {
        if (!wechatEnabled || wechatAppId.isEmpty()) {
            return null;
        }
        String encodedUri;
        try {
            encodedUri = java.net.URLEncoder.encode(redirectUri, "UTF-8");
        } catch (java.io.UnsupportedEncodingException e) {
            encodedUri = redirectUri;
        }
        return "https://open.weixin.qq.com/connect/qrconnect"
                + "?appid=" + wechatAppId
                + "&redirect_uri=" + encodedUri
                + "&response_type=code"
                + "&scope=snsapi_login"
                + "&state=" + UUID.randomUUID().toString().substring(0, 8)
                + "#wechat_redirect";
    }

    // ==================== 微信OAuth辅助方法 ====================

    private record WechatTokenInfo(String accessToken, String openId, String unionId) {}
    private record WechatUserInfo(String nickname, String headImgUrl) {}

    private WechatTokenInfo getWechatAccessToken(String code) {
        try {
            String url = "https://api.weixin.qq.com/sns/oauth2/access_token"
                    + "?appid=" + wechatAppId
                    + "&secret=" + wechatAppSecret
                    + "&code=" + code
                    + "&grant_type=authorization_code";

            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            String response = restTemplate.getForObject(url, String.class);

            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(response);

            if (root.has("errcode")) {
                log.error("微信获取token失败: {}", response);
                return null;
            }

            return new WechatTokenInfo(
                    root.path("access_token").asText(),
                    root.path("openid").asText(),
                    root.path("unionid").asText(null)
            );
        } catch (Exception e) {
            log.error("微信OAuth获取token异常: {}", e.getMessage(), e);
            return null;
        }
    }

    private WechatUserInfo getWechatUserInfo(String accessToken, String openId) {
        try {
            String url = "https://api.weixin.qq.com/sns/userinfo"
                    + "?access_token=" + accessToken
                    + "&openid=" + openId;

            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            String response = restTemplate.getForObject(url, String.class);

            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(response);

            return new WechatUserInfo(
                    root.path("nickname").asText(null),
                    root.path("headimgurl").asText(null)
            );
        } catch (Exception e) {
            log.warn("获取微信用户信息失败: {}", e.getMessage());
            return null;
        }
    }

    // ==================== 私有辅助方法 ====================
    
    @SuppressWarnings("null")
    private String createRefreshToken(Long userId) {
        refreshTokenRepository.deleteByUserId(userId);
        
        @lombok.NonNull RefreshToken refreshToken = RefreshToken.builder()
                .userId(userId)
                .token(UUID.randomUUID().toString())
                .expiresAt(LocalDateTime.now().plusDays(7))
                .createdAt(LocalDateTime.now())
                .build();
        
        @NonNull RefreshToken saved = refreshTokenRepository.save(refreshToken);
        return saved.getToken();
    }
    
    private TokenResponse buildTokenResponse(User user, String accessToken, String refreshToken) {
        return buildTokenResponse(user, accessToken, refreshToken, false);
    }

    /**
     * 构建Token响应
     * @param isNewUser 是否为新注册用户，true时前端触发引导页和抵用券赠送提示
     */
    private TokenResponse buildTokenResponse(User user, String accessToken, String refreshToken, boolean isNewUser) {
        Long buyerId = buyerRepository.findByUserId(user.getId()).map(Buyer::getId).orElse(null);
        Long supplierId = supplierRepository.findByUserId(user.getId()).map(Supplier::getId).orElse(null);
        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getAccessTokenExpiration() / 1000)
                .isNewUser(isNewUser ? true : null)
                .user(TokenResponse.UserInfo.builder()
                        .id(user.getId())
                        .username(user.getUsername())
                        .email(user.getEmail())
                        .phone(user.getPhone())
                        .realName(user.getRealName())
                        .avatarUrl(user.getAvatarUrl())
                        .userType(user.getUserType())
                        .buyerId(buyerId)
                        .supplierId(supplierId)
                        .build())
                .build();
    }
    
    private String getRoleCode(String userType) {
        return switch (userType.toUpperCase()) {
            case "SUPPLIER" -> UserRoleEnum.ROLE_SUPPLIER.getCode();
            case "BUYER" -> UserRoleEnum.ROLE_BUYER.getCode();
            default -> throw new BusinessException(ErrorCode.INVALID_PARAMETER);
        };
    }

    private String generateUsername(String account, String type) {
        String prefix = "SMS".equals(type) ? "m_" : "e_";
        String suffix = account.length() > 6 ? account.substring(account.length() - 6) : account;
        return prefix + suffix + "_" + System.currentTimeMillis() % 100000;
    }

    /**
     * 为采购商用户创建 Buyer 记录
     */
    private void createBuyerProfile(User user) {
        try {
            Buyer buyer = Buyer.builder()
                    .userId(user.getId())
                    .contactPerson(user.getRealName())
                    .contactPhone(user.getPhone())
                    .build();
            buyerRepository.save(buyer);
            log.info("已创建采购商资料: userId={}", user.getId());
        } catch (Exception e) {
            log.warn("创建采购商资料失败: userId={}, error={}", user.getId(), e.getMessage());
        }
    }

    /**
     * 为供应商用户创建 Supplier 记录
     */
    private void createSupplierProfile(User user, String companyName) {
        try {
            Supplier supplier = Supplier.builder()
                    .userId(user.getId())
                    .companyName(companyName != null ? companyName : (user.getUsername() + "的公司"))
                    .contactPerson(user.getRealName())
                    .contactPhone(user.getPhone())
                    .status("PENDING")
                    .build();
            supplierRepository.save(supplier);
            log.info("已创建供应商资料: userId={}", user.getId());
        } catch (Exception e) {
            log.warn("创建供应商资料失败: userId={}, error={}", user.getId(), e.getMessage());
        }
    }
}
