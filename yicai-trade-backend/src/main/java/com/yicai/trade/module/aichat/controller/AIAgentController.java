package com.yicai.trade.module.aichat.controller;

import com.yicai.trade.module.aichat.dto.AgentRequest;
import com.yicai.trade.module.aichat.dto.AgentResponse;
import com.yicai.trade.module.aichat.dto.ChatRequest;
import com.yicai.trade.module.aichat.dto.ChatResponse;
import com.yicai.trade.module.aichat.service.AIAgentService;
import com.yicai.trade.module.aichat.service.AIChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Tag(name = "AI Agent", description = "AI智能体增强接口")
@RestController
@RequestMapping("/api/ai-agent")
@RequiredArgsConstructor
public class AIAgentController {

    private final AIAgentService agentService;
    private final AIChatService chatService;

    @Operation(summary = "智能体对话接口")
    @PostMapping("/message")
    public ResponseEntity<AgentResponse> agentMessage(@RequestBody AgentRequest request) {
        AgentResponse response = agentService.processAgentRequest(request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "带文件上传的智能体对话")
    @PostMapping(value = "/message-with-files", consumes = "multipart/form-data")
    public ResponseEntity<AgentResponse> agentMessageWithFiles(
            @RequestPart("request") String requestJson,
            @RequestPart(value = "files", required = false) List<MultipartFile> files) {
        try {
            AgentRequest request = agentService.parseRequestWithFiles(requestJson, files);
            AgentResponse response = agentService.processAgentRequest(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    AgentResponse.builder()
                            .type("error")
                            .message("请求处理失败: " + e.getMessage())
                            .build()
            );
        }
    }

    @Operation(summary = "直接执行工具调用")
    @PostMapping("/execute-tool")
    public ResponseEntity<AgentResponse> executeTool(@RequestBody Map<String, Object> toolRequest) {
        String toolName = (String) toolRequest.get("toolName");
        Map<String, Object> params = (Map<String, Object>) toolRequest.get("params");
        
        AgentResponse response = agentService.executeToolDirectly(toolName, params);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "获取可用工具列表")
    @GetMapping("/tools")
    public ResponseEntity<List<Map<String, Object>>> getAvailableTools() {
        List<Map<String, Object>> tools = agentService.getAvailableTools();
        return ResponseEntity.ok(tools);
    }

    @Operation(summary = "获取工具详情")
    @GetMapping("/tools/{toolName}")
    public ResponseEntity<Map<String, Object>> getToolDetails(@PathVariable String toolName) {
        Map<String, Object> toolDetails = agentService.getToolDetails(toolName);
        if (toolDetails == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(toolDetails);
    }

    @Operation(summary = "获取当前页面上下文")
    @GetMapping("/context/{pageName}")
    public ResponseEntity<Map<String, Object>> getPageContext(@PathVariable String pageName) {
        Map<String, Object> context = agentService.getPageContext(pageName);
        return ResponseEntity.ok(context);
    }

    @Operation(summary = "智能体健康检查")
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> healthInfo = Map.of(
                "status", "running",
                "service", "AI Agent Enhanced",
                "version", "1.0.0",
                "timestamp", System.currentTimeMillis(),
                "toolsAvailable", agentService.getAvailableTools().size()
        );
        return ResponseEntity.ok(healthInfo);
    }

    @Operation(summary = "获取会话历史")
    @GetMapping("/session/{sessionId}")
    public ResponseEntity<List<Map<String, Object>>> getSessionHistory(@PathVariable String sessionId) {
        List<Map<String, Object>> history = agentService.getSessionHistory(sessionId);
        return ResponseEntity.ok(history);
    }

    @Operation(summary = "清除会话历史")
    @DeleteMapping("/session/{sessionId}")
    public ResponseEntity<Void> clearSession(@PathVariable String sessionId) {
        agentService.clearSession(sessionId);
        return ResponseEntity.ok().build();
    }

    @Operation(summary = "向后兼容的聊天接口")
    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        // 向后兼容，调用原有的聊天服务
        ChatResponse response = chatService.chat(request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "分析用户意图")
    @PostMapping("/analyze-intent")
    public ResponseEntity<Map<String, Object>> analyzeIntent(@RequestBody Map<String, String> request) {
        String message = request.get("message");
        String currentPage = request.get("currentPage");
        
        Map<String, Object> intentAnalysis = agentService.analyzeUserIntent(message, currentPage);
        return ResponseEntity.ok(intentAnalysis);
    }

    @Operation(summary = "获取智能体配置")
    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getAgentConfig() {
        Map<String, Object> config = Map.of(
                "name", "易小采智能助手",
                "version", "2.0.0",
                "description", "易采贸易平台AI智能助手，支持项目功能调用",
                "capabilities", List.of(
                        "自然语言对话",
                        "工具调用执行",
                        "页面上下文感知",
                        "文件上传处理",
                        "智能导航引导",
                        "实时数据查询"
                ),
                "settings", Map.of(
                        "maxResponseTime", 45000,
                        "maxHistoryLength", 20,
                        "sessionTimeout", 1800000,
                        "fileUploadEnabled", true,
                        "toolExecutionEnabled", true
                )
        );
        return ResponseEntity.ok(config);
    }
}