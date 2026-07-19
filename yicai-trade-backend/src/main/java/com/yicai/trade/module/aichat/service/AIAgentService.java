package com.yicai.trade.module.aichat.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.module.aichat.dto.AgentRequest;
import com.yicai.trade.module.aichat.dto.AgentResponse;
import com.yicai.trade.module.aichat.dto.ChatRequest;
import com.yicai.trade.module.aichat.dto.ChatResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIAgentService {

    private final AIChatService chatService;
    private final ObjectMapper objectMapper;

    private final Map<String, List<Map<String, Object>>> sessionHistories = new ConcurrentHashMap<>();
    private static final int MAX_SESSION_HISTORY = 50;

    // ========================= 页面上下文 =========================

    private static final Map<String, Map<String, Object>> PAGE_CONTEXTS = Map.ofEntries(
            Map.entry("index.html", Map.of(
                    "title", "首页",
                    "description", "平台入口，展示核心功能导航、行业新闻、平台优势",
                    "suggestedTools", List.of("search_products", "navigate_page")
            )),
            Map.entry("smart-match.html", Map.of(
                    "title", "智能匹配",
                    "description", "AI驱动的供应商智能匹配系统，输入产品需求获得推荐",
                    "suggestedTools", List.of("search_products", "match_factories")
            )),
            Map.entry("auction-list.html", Map.of(
                    "title", "反向竞价列表",
                    "description", "查看所有竞价项目，按状态筛选",
                    "suggestedTools", List.of("create_reverse_auction", "check_order_status")
            )),
            Map.entry("auction-create.html", Map.of(
                    "title", "创建反向竞价",
                    "description", "发布新的采购反向竞价需求",
                    "suggestedTools", List.of("create_reverse_auction", "calculate_cost")
            )),
            Map.entry("auction-detail.html", Map.of(
                    "title", "竞价详情",
                    "description", "查看竞价实时出价记录与详情",
                    "suggestedTools", List.of("check_order_status")
            )),
            Map.entry("orders.html", Map.of(
                    "title", "订单管理",
                    "description", "查看采购订单列表与状态跟踪",
                    "suggestedTools", List.of("check_order_status")
            )),
            Map.entry("order-detail.html", Map.of(
                    "title", "订单详情",
                    "description", "查看订单详情和物流信息",
                    "suggestedTools", List.of("check_order_status")
            )),
            Map.entry("user-center.html", Map.of(
                    "title", "采购商中心",
                    "description", "个人控制面板、待签合同、订单跟踪",
                    "suggestedTools", List.of("check_order_status", "navigate_page")
            )),
            Map.entry("supplier-center.html", Map.of(
                    "title", "供应商中心",
                    "description", "供应商控制面板，管理产品和订单",
                    "suggestedTools", List.of("check_order_status", "navigate_page")
            )),
            Map.entry("contract-create.html", Map.of(
                    "title", "创建合同",
                    "description", "选择合同模板并填写合同信息",
                    "suggestedTools", List.of("calculate_cost")
            ))
    );

    // ========================= 工具定义 =========================

    private static final List<Map<String, Object>> TOOL_DEFINITIONS = List.of(
            Map.of(
                    "name", "search_products",
                    "displayName", "搜索产品",
                    "icon", "\uD83D\uDD0D",
                    "description", "按关键词搜索产品",
                    "defaultParams", Map.of()
            ),
            Map.of(
                    "name", "match_factories",
                    "displayName", "匹配工厂",
                    "icon", "\uD83C\uDFED",
                    "description", "智能匹配供应商",
                    "defaultParams", Map.of()
            ),
            Map.of(
                    "name", "create_reverse_auction",
                    "displayName", "创建竞价",
                    "icon", "\uD83D\uDCB0",
                    "description", "发布反向竞价需求",
                    "defaultParams", Map.of()
            ),
            Map.of(
                    "name", "calculate_cost",
                    "displayName", "成本计算",
                    "icon", "\uD83E\uDDEE",
                    "description", "计算采购总成本",
                    "defaultParams", Map.of()
            ),
            Map.of(
                    "name", "check_order_status",
                    "displayName", "订单状态",
                    "icon", "\uD83D\uDCE6",
                    "description", "查看订单进度",
                    "defaultParams", Map.of()
            ),
            Map.of(
                    "name", "navigate_page",
                    "displayName", "页面导航",
                    "icon", "\uD83E\uDDED",
                    "description", "跳转到功能页面",
                    "defaultParams", Map.of()
            )
    );

    // ========================= 核心处理 =========================

    public AgentResponse processAgentRequest(AgentRequest request) {
        long startTime = System.currentTimeMillis();
        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isEmpty()) {
            sessionId = "agent_" + UUID.randomUUID().toString();
        }

        try {
            // 如果有直接工具调用，优先执行
            if (request.getToolCall() != null && request.getToolCall().getName() != null) {
                AgentResponse toolResponse = executeToolDirectly(
                        request.getToolCall().getName(),
                        request.getToolCall().getArguments()
                );
                toolResponse.setSessionId(sessionId);
                toolResponse.setProcessingTime(System.currentTimeMillis() - startTime);
                recordSession(sessionId, "user", request.getMessage());
                recordSession(sessionId, "assistant", toolResponse.getMessage());
                return toolResponse;
            }

            // 委托给 AIChatService 进行 AI 对话（包含工具调用）
            ChatRequest chatRequest = ChatRequest.builder()
                    .sessionId(sessionId)
                    .message(request.getMessage())
                    .currentPage(request.getCurrentPage())
                    .build();

            ChatResponse chatResponse = chatService.chat(chatRequest);

            // 转换为 AgentResponse
            AgentResponse agentResponse = convertChatToAgentResponse(chatResponse, sessionId);
            agentResponse.setProcessingTime(System.currentTimeMillis() - startTime);
            agentResponse.setTimestamp(System.currentTimeMillis());

            recordSession(sessionId, "user", request.getMessage());
            recordSession(sessionId, "assistant", agentResponse.getMessage());

            return agentResponse;

        } catch (Exception e) {
            log.error("Error processing agent request", e);
            return AgentResponse.builder()
                    .type("error")
                    .message("处理请求时出现错误: " + e.getMessage())
                    .sessionId(sessionId)
                    .timestamp(System.currentTimeMillis())
                    .processingTime(System.currentTimeMillis() - startTime)
                    .build();
        }
    }

    private AgentResponse convertChatToAgentResponse(ChatResponse chatResponse, String sessionId) {
        String type = chatResponse.getType();
        if (type == null) type = "text";

        AgentResponse.AgentResponseBuilder builder = AgentResponse.builder()
                .type(type)
                .message(chatResponse.getMessage())
                .sessionId(sessionId)
                .timestamp(System.currentTimeMillis());

        if (chatResponse.getData() != null) {
            builder.data(chatResponse.getData());
        }
        if (chatResponse.getExtra() != null) {
            builder.extra(chatResponse.getExtra());
        }

        // 对导航类型做特殊处理
        if ("navigation".equals(type) && chatResponse.getData() != null && !chatResponse.getData().isEmpty()) {
            Map<String, Object> navData = chatResponse.getData().get(0);
            builder.navigation(AgentResponse.NavigationInfo.builder()
                    .targetUrl((String) navData.get("targetUrl"))
                    .description((String) navData.get("description"))
                    .shouldRedirect(true)
                    .build());
        }

        return builder.build();
    }

    // ========================= 文件解析 =========================

    public AgentRequest parseRequestWithFiles(String requestJson, List<MultipartFile> files) {
        try {
            AgentRequest request = objectMapper.readValue(requestJson, AgentRequest.class);

            if (files != null && !files.isEmpty()) {
                List<AgentRequest.FileInfo> fileInfos = new ArrayList<>();
                for (MultipartFile file : files) {
                    fileInfos.add(AgentRequest.FileInfo.builder()
                            .name(file.getOriginalFilename())
                            .type(file.getContentType())
                            .size(file.getSize())
                            .build());
                }
                request.setFiles(fileInfos);

                // 将文件信息附加到消息中
                StringBuilder fileDesc = new StringBuilder();
                for (MultipartFile file : files) {
                    fileDesc.append("\n[附件: ").append(file.getOriginalFilename())
                            .append(" (").append(formatFileSize(file.getSize())).append(")]");
                }
                if (request.getMessage() != null) {
                    request.setMessage(request.getMessage() + fileDesc);
                } else {
                    request.setMessage("用户上传了文件:" + fileDesc);
                }
            }

            return request;
        } catch (Exception e) {
            log.error("Error parsing agent request with files", e);
            throw new RuntimeException("请求解析失败: " + e.getMessage());
        }
    }

    private String formatFileSize(long bytes) {
        if (bytes < 1024) return bytes + "B";
        if (bytes < 1024 * 1024) return String.format("%.1fKB", bytes / 1024.0);
        return String.format("%.1fMB", bytes / (1024.0 * 1024.0));
    }

    // ========================= 工具执行 =========================

    public AgentResponse executeToolDirectly(String toolName, Map<String, Object> params) {
        if (toolName == null || toolName.isEmpty()) {
            return AgentResponse.error("工具名称不能为空", null);
        }
        if (params == null) params = new HashMap<>();

        try {
            // 委托给 AIChatService 对应的消息处理
            String message = buildToolMessage(toolName, params);
            ChatRequest chatRequest = ChatRequest.builder()
                    .sessionId("tool_" + UUID.randomUUID().toString())
                    .message(message)
                    .build();

            ChatResponse chatResponse = chatService.chat(chatRequest);
            return convertChatToAgentResponse(chatResponse, null);

        } catch (Exception e) {
            log.error("Error executing tool directly: {}", toolName, e);
            return AgentResponse.error("工具执行失败: " + e.getMessage(), null);
        }
    }

    private String buildToolMessage(String toolName, Map<String, Object> params) {
        return switch (toolName) {
            case "search_products" -> "搜索产品: " + params.getOrDefault("keyword", "");
            case "match_factories" -> "匹配工厂: " + params.getOrDefault("product_name", "");
            case "create_reverse_auction" -> "创建反向竞价: " + params.getOrDefault("product_name", "") +
                    ", 数量: " + params.getOrDefault("quantity", "");
            case "calculate_cost" -> "计算成本: " + params.getOrDefault("product_name", "") +
                    ", 数量: " + params.getOrDefault("quantity", "");
            case "check_order_status" -> "查询订单状态: " + params.getOrDefault("order_no", params.getOrDefault("auction_id", ""));
            case "navigate_page" -> "导航到页面: " + params.getOrDefault("page", "");
            default -> "执行工具 " + toolName + ": " + params;
        };
    }

    // ========================= 工具列表 =========================

    public List<Map<String, Object>> getAvailableTools() {
        return TOOL_DEFINITIONS;
    }

    public Map<String, Object> getToolDetails(String toolName) {
        return TOOL_DEFINITIONS.stream()
                .filter(tool -> toolName.equals(tool.get("name")))
                .findFirst()
                .orElse(null);
    }

    // ========================= 页面上下文 =========================

    public Map<String, Object> getPageContext(String pageName) {
        Map<String, Object> context = PAGE_CONTEXTS.get(pageName);
        if (context != null) {
            return context;
        }
        return Map.of(
                "title", pageName,
                "description", "页面上下文信息不可用",
                "suggestedTools", List.of("navigate_page")
        );
    }

    // ========================= 会话管理 =========================

    private void recordSession(String sessionId, String role, String content) {
        List<Map<String, Object>> history = sessionHistories.computeIfAbsent(sessionId, k -> new ArrayList<>());
        history.add(Map.of(
                "role", role,
                "content", content != null ? content : "",
                "timestamp", System.currentTimeMillis()
        ));
        // 限制历史长度
        if (history.size() > MAX_SESSION_HISTORY) {
            history.subList(0, history.size() - MAX_SESSION_HISTORY).clear();
        }
    }

    public List<Map<String, Object>> getSessionHistory(String sessionId) {
        return sessionHistories.getOrDefault(sessionId, List.of());
    }

    public void clearSession(String sessionId) {
        sessionHistories.remove(sessionId);
    }

    // ========================= 意图分析 =========================

    public Map<String, Object> analyzeUserIntent(String message, String currentPage) {
        if (message == null || message.isEmpty()) {
            return Map.of("intent", "unknown", "confidence", 0.0, "suggestedTool", "");
        }

        String msg = message.toLowerCase();
        String intent;
        String suggestedTool;
        double confidence;

        if (msg.contains("搜索") || msg.contains("找") || msg.contains("查找") || msg.contains("search")) {
            intent = "search";
            suggestedTool = "search_products";
            confidence = 0.9;
        } else if (msg.contains("匹配") || msg.contains("供应商") || msg.contains("工厂") || msg.contains("match")) {
            intent = "match";
            suggestedTool = "match_factories";
            confidence = 0.85;
        } else if (msg.contains("竞价") || msg.contains("竞拍") || msg.contains("拍卖") || msg.contains("auction")) {
            intent = "auction";
            suggestedTool = "create_reverse_auction";
            confidence = 0.85;
        } else if (msg.contains("成本") || msg.contains("价格") || msg.contains("计算") || msg.contains("cost")) {
            intent = "cost";
            suggestedTool = "calculate_cost";
            confidence = 0.8;
        } else if (msg.contains("订单") || msg.contains("状态") || msg.contains("物流") || msg.contains("order")) {
            intent = "order";
            suggestedTool = "check_order_status";
            confidence = 0.85;
        } else if (msg.contains("导航") || msg.contains("跳转") || msg.contains("去") || msg.contains("打开")) {
            intent = "navigate";
            suggestedTool = "navigate_page";
            confidence = 0.75;
        } else {
            intent = "general_chat";
            suggestedTool = "";
            confidence = 0.6;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("intent", intent);
        result.put("confidence", confidence);
        result.put("suggestedTool", suggestedTool);
        result.put("currentPage", currentPage);
        return result;
    }
}
