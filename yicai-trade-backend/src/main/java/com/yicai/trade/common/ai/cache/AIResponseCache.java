package com.yicai.trade.common.ai.cache;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * AI响应缓存服务
 * 支持Redis缓存（生产环境）和内存缓存（开发环境）
 * 自动检测Redis可用性，不可用时降级为内存缓存
 */
@Slf4j
@Component
public class AIResponseCache {

    private static final String CACHE_PREFIX = "ai:response:";
    private static final long DEFAULT_TTL_MINUTES = 60; // 默认1小时
    private static final long ESTIMATE_TTL_MINUTES = 30; // 估算结果30分钟
    
    private final RedisTemplate<String, Object> redisTemplate;
    private final ObjectMapper objectMapper;
    private final boolean redisEnabled;
    
    // 内存缓存作为降级方案
    private final Map<String, CacheEntry> memoryCache = new ConcurrentHashMap<>();
    
    public AIResponseCache(@Nullable RedisTemplate<String, Object> redisTemplate, 
                          ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.redisEnabled = testRedisConnection();
        
        if (redisEnabled) {
            log.info("AI缓存服务: Redis缓存已启用");
        } else {
            log.info("AI缓存服务: 使用内存缓存 (Redis不可用)");
        }
    }
    
    private boolean testRedisConnection() {
        if (redisTemplate == null) {
            return false;
        }
        try {
            var connectionFactory = redisTemplate.getConnectionFactory();
            if (connectionFactory == null) {
                log.warn("Redis连接工厂未配置");
                return false;
            }
            connectionFactory.getConnection().ping();
            return true;
        } catch (Exception e) {
            log.warn("Redis连接测试失败: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * 缓存品类匹配结果
     */
    public void cacheCategoryMatch(String productName, Object result) {
        String key = buildKey("category", productName);
        put(key, result, DEFAULT_TTL_MINUTES);
    }
    
    /**
     * 获取品类匹配缓存
     */
    public <T> T getCategoryMatch(String productName, Class<T> type) {
        String key = buildKey("category", productName);
        return get(key, type);
    }
    
    /**
     * 缓存参数模板
     */
    public void cacheParameters(String categoryCode, String stage, Object parameters) {
        String key = buildKey("params", categoryCode + "_" + stage);
        put(key, parameters, DEFAULT_TTL_MINUTES);
    }
    
    /**
     * 获取参数模板缓存
     */
    public <T> T getParameters(String categoryCode, String stage, Class<T> type) {
        String key = buildKey("params", categoryCode + "_" + stage);
        return get(key, type);
    }
    
    /**
     * 缓存成本估算结果
     */
    public void cacheCostEstimate(String sessionId, Object estimate) {
        String key = buildKey("cost", sessionId);
        put(key, estimate, ESTIMATE_TTL_MINUTES);
    }
    
    /**
     * 获取成本估算缓存
     */
    public <T> T getCostEstimate(String sessionId, Class<T> type) {
        String key = buildKey("cost", sessionId);
        return get(key, type);
    }
    
    /**
     * 缓存FOB估算结果
     */
    public void cacheFOBEstimate(String sessionId, Object estimate) {
        String key = buildKey("fob", sessionId);
        put(key, estimate, ESTIMATE_TTL_MINUTES);
    }
    
    /**
     * 获取FOB估算缓存
     */
    public <T> T getFOBEstimate(String sessionId, Class<T> type) {
        String key = buildKey("fob", sessionId);
        return get(key, type);
    }
    
    /**
     * 通用缓存方法
     */
    public void put(String key, Object value, long ttlMinutes) {
        try {
            String json = objectMapper.writeValueAsString(value);
            
            if (redisEnabled) {
                redisTemplate.opsForValue().set(key, json, ttlMinutes, TimeUnit.MINUTES);
                log.debug("Redis缓存写入: key={}", key);
            } else {
                long expireAt = System.currentTimeMillis() + ttlMinutes * 60 * 1000;
                memoryCache.put(key, new CacheEntry(json, expireAt));
                cleanExpiredMemoryCache();
                log.debug("内存缓存写入: key={}", key);
            }
        } catch (JsonProcessingException e) {
            log.error("缓存序列化失败: {}", e.getMessage());
        }
    }
    
    /**
     * 通用获取方法
     */
    public <T> T get(String key, Class<T> type) {
        try {
            String json = null;
            
            if (redisEnabled) {
                Object value = redisTemplate.opsForValue().get(key);
                json = value != null ? value.toString() : null;
            } else {
                CacheEntry entry = memoryCache.get(key);
                if (entry != null && !entry.isExpired()) {
                    json = entry.value;
                } else if (entry != null) {
                    memoryCache.remove(key);
                }
            }
            
            if (json != null) {
                log.debug("缓存命中: key={}", key);
                return objectMapper.readValue(json, type);
            }
        } catch (Exception e) {
            log.error("缓存读取失败: key={}, error={}", key, e.getMessage());
        }
        
        log.debug("缓存未命中: key={}", key);
        return null;
    }
    
    /**
     * 通用获取方法 (泛型类型)
     */
    public <T> T get(String key, TypeReference<T> typeRef) {
        try {
            String json = null;
            
            if (redisEnabled) {
                Object value = redisTemplate.opsForValue().get(key);
                json = value != null ? value.toString() : null;
            } else {
                CacheEntry entry = memoryCache.get(key);
                if (entry != null && !entry.isExpired()) {
                    json = entry.value;
                }
            }
            
            if (json != null) {
                return objectMapper.readValue(json, typeRef);
            }
        } catch (Exception e) {
            log.error("缓存读取失败: key={}, error={}", key, e.getMessage());
        }
        return null;
    }
    
    /**
     * 删除缓存
     */
    public void evict(String key) {
        if (redisEnabled) {
            redisTemplate.delete(key);
        } else {
            memoryCache.remove(key);
        }
        log.debug("缓存删除: key={}", key);
    }
    
    /**
     * 清除所有AI相关缓存
     */
    public void clearAll() {
        if (redisEnabled) {
            redisTemplate.delete(redisTemplate.keys(CACHE_PREFIX + "*"));
        } else {
            memoryCache.clear();
        }
        log.info("AI缓存已清空");
    }
    
    private String buildKey(String type, String identifier) {
        return CACHE_PREFIX + type + ":" + identifier.toLowerCase().replaceAll("\\s+", "_");
    }
    
    private void cleanExpiredMemoryCache() {
        if (memoryCache.size() > 1000) {
            memoryCache.entrySet().removeIf(e -> e.getValue().isExpired());
        }
    }
    
    /**
     * 内存缓存条目
     */
    private static class CacheEntry {
        final String value;
        final long expireAt;
        
        CacheEntry(String value, long expireAt) {
            this.value = value;
            this.expireAt = expireAt;
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() > expireAt;
        }
    }
}
