package com.yicai.trade.module.aichat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgentResponse {
    
    /**
     * 响应类型：
     * - text: 普通文本回复
     * - tool_result: 工具执行结果
     * - navigation: 页面导航
     * - data: 数据展示
     * - error: 错误信息
     * - confirmation: 确认请求
     */
    private String type;
    
    /**
     * 回复消息内容
     */
    private String message;
    
    /**
     * 会话ID
     */
    private String sessionId;
    
    /**
     * 响应数据（工具执行结果等）
     */
    private List<Map<String, Object>> data;
    
    /**
     * 额外信息
     */
    private Map<String, Object> extra;
    
    /**
     * 建议的下一步操作
     */
    private List<SuggestedAction> suggestedActions;
    
    /**
     * 工具调用信息（如果有）
     */
    private ToolExecution toolExecution;
    
    /**
     * 导航信息
     */
    private NavigationInfo navigation;
    
    /**
     * 响应时间戳
     */
    private Long timestamp;
    
    /**
     * 处理耗时（毫秒）
     */
    private Long processingTime;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SuggestedAction {
        private String type; // tool, navigation, question, confirmation
        private String label;
        private String description;
        private Map<String, Object> parameters;
        private Integer priority; // 优先级，1-10，越高越优先
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ToolExecution {
        private String toolName;
        private Map<String, Object> parameters;
        private String status; // success, partial_success, failed
        private String executionId;
        private Long executionTime;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NavigationInfo {
        private String targetPage;
        private String targetUrl;
        private String description;
        private Map<String, String> queryParams;
        private Boolean shouldRedirect;
        private Boolean openInNewTab;
    }
    
    /**
     * 创建成功响应
     */
    public static AgentResponse success(String message, String sessionId) {
        return AgentResponse.builder()
                .type("text")
                .message(message)
                .sessionId(sessionId)
                .timestamp(System.currentTimeMillis())
                .build();
    }
    
    /**
     * 创建工具执行结果响应
     */
    public static AgentResponse toolResult(String message, List<Map<String, Object>> data, 
                                          Map<String, Object> extra, String sessionId) {
        return AgentResponse.builder()
                .type("tool_result")
                .message(message)
                .data(data)
                .extra(extra)
                .sessionId(sessionId)
                .timestamp(System.currentTimeMillis())
                .build();
    }
    
    /**
     * 创建导航响应
     */
    public static AgentResponse navigation(String targetUrl, String description, 
                                          String sessionId) {
        return AgentResponse.builder()
                .type("navigation")
                .message(description)
                .sessionId(sessionId)
                .navigation(NavigationInfo.builder()
                        .targetUrl(targetUrl)
                        .description(description)
                        .shouldRedirect(true)
                        .build())
                .timestamp(System.currentTimeMillis())
                .build();
    }
    
    /**
     * 创建错误响应
     */
    public static AgentResponse error(String message, String sessionId) {
        return AgentResponse.builder()
                .type("error")
                .message(message)
                .sessionId(sessionId)
                .timestamp(System.currentTimeMillis())
                .build();
    }
    
    /**
     * 创建数据响应
     */
    public static AgentResponse data(List<Map<String, Object>> data, String message, 
                                    String sessionId) {
        return AgentResponse.builder()
                .type("data")
                .message(message)
                .data(data)
                .sessionId(sessionId)
                .timestamp(System.currentTimeMillis())
                .build();
    }
}