package com.yicai.trade.module.notification.verification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * 验证码服务实现
 * 优先使用 Redis；Redis 不可用时降级为内存缓存
 */
@Slf4j
@Service
public class VerificationCodeServiceImpl implements VerificationCodeService {

    private static final String REDIS_PREFIX = "verify:code:";
    private static final long EXPIRE_MINUTES = 5;
    private static final int CODE_LENGTH = 6;

    private final Random random = new Random();

    @Autowired(required = false)
    private StringRedisTemplate stringRedisTemplate;

    /** 内存降级缓存: key -> code:expireTimestamp */
    private final Map<String, String> memoryCache = new ConcurrentHashMap<>();

    @Override
    public String generateCode(String target, String type) {
        String code = generateRandomCode();
        String key = buildKey(target, type);

        if (isRedisAvailable()) {
            stringRedisTemplate.opsForValue().set(key, code, EXPIRE_MINUTES, TimeUnit.MINUTES);
            log.info("验证码已缓存到Redis: key={}", key);
        } else {
            long expireAt = System.currentTimeMillis() + EXPIRE_MINUTES * 60 * 1000;
            memoryCache.put(key, code + ":" + expireAt);
            log.info("验证码已缓存到内存: key={}", key);
        }

        return code;
    }

    @Override
    public boolean verifyCode(String target, String type, String code) {
        if (code == null || code.isEmpty()) {
            return false;
        }

        String key = buildKey(target, type);
        String storedCode;

        if (isRedisAvailable()) {
            storedCode = stringRedisTemplate.opsForValue().get(key);
            if (code.equals(storedCode)) {
                stringRedisTemplate.delete(key); // 验证成功后删除
                return true;
            }
        } else {
            String cached = memoryCache.get(key);
            if (cached != null) {
                String[] parts = cached.split(":");
                storedCode = parts[0];
                long expireAt = Long.parseLong(parts[1]);
                if (System.currentTimeMillis() > expireAt) {
                    memoryCache.remove(key);
                    return false;
                }
                if (code.equals(storedCode)) {
                    memoryCache.remove(key);
                    return true;
                }
            }
        }

        return false;
    }

    private String generateRandomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(random.nextInt(10));
        }
        return sb.toString();
    }

    private String buildKey(String target, String type) {
        return REDIS_PREFIX + type.toLowerCase() + ":" + target;
    }

    private boolean isRedisAvailable() {
        if (stringRedisTemplate == null) return false;
        try {
            stringRedisTemplate.hasKey("_health_check_");
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
