package com.yicai.trade.common.ai.util;

import com.yicai.trade.common.ai.client.AIClient;
import com.yicai.trade.common.ai.client.AIRequest;
import com.yicai.trade.common.ai.client.AIResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.function.Supplier;

/**
 * AI调用重试和降级辅助工具
 * 提供重试机制和多模型降级策略
 */
@Slf4j
@Component
public class AIRetryHelper {

    private static final int DEFAULT_MAX_RETRIES = 3;
    private static final long DEFAULT_RETRY_DELAY_MS = 1000;
    private static final double RETRY_DELAY_MULTIPLIER = 1.5;

    /**
     * 带重试的AI调用
     * @param client AI客户端
     * @param request 请求
     * @return AI响应
     */
    public AIResponse callWithRetry(AIClient client, AIRequest request) {
        return callWithRetry(client, request, DEFAULT_MAX_RETRIES);
    }

    /**
     * 带重试的AI调用
     * @param client AI客户端
     * @param request 请求
     * @param maxRetries 最大重试次数
     * @return AI响应
     */
    public AIResponse callWithRetry(AIClient client, AIRequest request, int maxRetries) {
        AIResponse response = null;
        long delay = DEFAULT_RETRY_DELAY_MS;
        
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                log.info("AI调用尝试 {}/{} - 模型: {}", attempt, maxRetries, client.getModelName());
                response = client.call(request);
                
                if (response != null && response.getSuccess()) {
                    log.info("AI调用成功 - 模型: {}, 尝试次数: {}", client.getModelName(), attempt);
                    return response;
                }
                
                log.warn("AI调用返回失败 - 模型: {}, 错误: {}", 
                        client.getModelName(), 
                        response != null ? response.getErrorMessage() : "空响应");
                
            } catch (Exception e) {
                log.error("AI调用异常 - 模型: {}, 尝试次数: {}, 错误: {}", 
                        client.getModelName(), attempt, e.getMessage());
            }
            
            // 如果不是最后一次尝试，等待后重试
            if (attempt < maxRetries) {
                try {
                    log.info("等待 {}ms 后重试...", delay);
                    Thread.sleep(delay);
                    delay = (long) (delay * RETRY_DELAY_MULTIPLIER);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }
        
        // 返回最后一次的响应或构建失败响应
        if (response == null) {
            response = AIResponse.builder()
                    .success(false)
                    .errorMessage("AI调用失败: 已达到最大重试次数 " + maxRetries)
                    .build();
        }
        return response;
    }

    /**
     * 带降级的AI调用 - 依次尝试多个客户端
     * @param clients AI客户端列表（按优先级排序）
     * @param request 请求
     * @return AI响应
     */
    public AIResponse callWithFallback(List<AIClient> clients, AIRequest request) {
        for (AIClient client : clients) {
            if (!client.isEnabled()) {
                log.info("跳过已禁用的AI模型: {}", client.getModelName());
                continue;
            }
            
            log.info("尝试AI模型: {}", client.getModelName());
            AIResponse response = callWithRetry(client, request, 2);
            
            if (response != null && response.getSuccess()) {
                return response;
            }
            
            log.warn("AI模型 {} 调用失败，尝试下一个备选模型", client.getModelName());
        }
        
        return AIResponse.builder()
                .success(false)
                .errorMessage("所有AI模型调用均失败")
                .build();
    }

    /**
     * 带重试的通用操作
     * @param operation 要执行的操作
     * @param operationName 操作名称（用于日志）
     * @param maxRetries 最大重试次数
     * @return 操作结果
     */
    public <T> T executeWithRetry(Supplier<T> operation, String operationName, int maxRetries) {
        long delay = DEFAULT_RETRY_DELAY_MS;
        Exception lastException = null;
        
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                log.info("{} - 尝试 {}/{}", operationName, attempt, maxRetries);
                T result = operation.get();
                if (result != null) {
                    log.info("{} - 成功，尝试次数: {}", operationName, attempt);
                    return result;
                }
            } catch (Exception e) {
                lastException = e;
                log.error("{} - 异常: {}", operationName, e.getMessage());
            }
            
            if (attempt < maxRetries) {
                try {
                    Thread.sleep(delay);
                    delay = (long) (delay * RETRY_DELAY_MULTIPLIER);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }
        
        if (lastException != null) {
            throw new RuntimeException(operationName + " 失败: " + lastException.getMessage(), lastException);
        }
        return null;
    }
}
