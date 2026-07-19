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
public class AgentRequest {
    
    /**
     * 用户消息内容
     */
    private String message;
    
    /**
     * 当前页面URL
     */
    private String currentPage;
    
    /**
     * 会话ID
     */
    private String sessionId;
    
    /**
     * 工具调用信息（可选）
     */
    private ToolCall toolCall;
    
    /**
     * 文件信息列表
     */
    private List<FileInfo> files;
    
    /**
     * 额外参数
     */
    private Map<String, Object> parameters;
    
    /**
     * 用户上下文信息
     */
    private UserContext userContext;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ToolCall {
        private String name;
        private Map<String, Object> arguments;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FileInfo {
        private String name;
        private String type;
        private Long size;
        private String url; // 文件访问URL（如果有）
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserContext {
        private String userId;
        private String userType; // buyer, supplier, admin
        private String companyName;
        private List<String> permissions;
        private Map<String, Object> preferences;
    }
}