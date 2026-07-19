package com.yicai.trade.module.aichat.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.ai.client.AIRequest;
import com.yicai.trade.common.ai.client.AIResponse;
import com.yicai.trade.common.ai.client.DeepSeekChatClient;
import com.yicai.trade.module.aichat.dto.ChatRequest;
import com.yicai.trade.module.aichat.dto.ChatResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIChatService {

    private final DeepSeekChatClient deepSeekClient;
    private final ObjectMapper objectMapper;

    // Session storage: sessionId -> conversation history
    private final Map<String, List<AIRequest.Message>> sessions = new ConcurrentHashMap<>();
    private final Map<String, Long> sessionTimestamps = new ConcurrentHashMap<>();
    private static final long SESSION_TTL_MS = 30 * 60 * 1000; // 30 minutes
    private static final int MAX_SESSIONS = 500;
    private static final int MAX_HISTORY = 20; // keep last 20 messages for context

    // ========================= 系统提示词 =========================

    private static final String SYSTEM_PROMPT = """
            你是「易采贸易平台」的AI智能助手「易小采」。你是一位专业、热情、对平台所有功能了如指掌的助手。

            ═══════════════ 平台概述 ═══════════════
            易采贸易平台是一个B2B国际采购供应链平台，连接全球采购商与中国制造商。
            平台核心价值：AI智能匹配 + 反向竞拍 + 全流程代采 + 供应链可视化。
            平台统一服务费为合同金额的2%，无其他隐性收费。

            ═══════════════ 平台完整功能模块 ═══════════════

            【首页 index.html】
            - 平台入口，展示核心功能导航、行业新闻、平台优势
            - 顶部导航可进入所有主要模块

            【智能匹配 smart-match.html】⭐核心功能
            - AI驱动的供应商智能匹配系统
            - 用户输入产品需求 → AI分析 → 推荐最优供应商 → FOB报价 → 生成合同
            - 完整流程：需求描述 → AI推荐供应商 → 查看报价 → 选择后进入合同创建
            - 操作指引："进入智能匹配页面，在输入框描述您要采购的产品，AI会自动推荐匹配的供应商"

            【电子拍卖场 auction-list.html / auction-create.html / auction-detail.html】⭐核心功能
            - 反向竞拍：采购商发布需求，供应商竞价，价低者得
            - auction-list.html: 查看所有拍卖项目（可按状态筛选：全部/进行中/即将开始/已结束）
            - auction-create.html: 发布新的采购反拍需求
            - auction-detail.html: 查看拍卖详情、实时出价记录
            - 操作指引："点击'发布采购反拍'按钮，填写产品名称、数量、起拍价等信息即可创建"

            【合同管理 contract-create.html / contract-detail.html】
            - 从智能匹配流程进入，选择合同模板（基础版/专业版/企业版）
            - 可上传自定义合同模板（平台审核后使用）
            - 合同信息自动从智能匹配数据填充
            - 提交后在采购商中心签署
            - 服务费统一2%，无额外模板费用

            【订单管理 orders.html / order-detail.html】
            - 查看所有采购订单列表
            - 跟踪订单状态：待确认 → 生产中 → 质检 → 已发货 → 已完成
            - 查看订单详情、物流信息

            【采购商中心 user-center.html】👤
            - 采购商个人控制面板
            - 待签合同管理、订单跟踪、历史记录
            - 账户设置、企业认证

            【供应商中心 supplier-center.html / merchant-center.html】🏭
            - supplier-center.html: 供应商控制面板（订单管理、产品管理、数据统计）
            - supplier-apply.html: 供应商入驻申请
            - supplier-product-manage.html: 产品管理（发布/编辑商品）
            - supplier-product-edit.html: 编辑单个产品
            - supplier-order-list.html / supplier-order-detail.html: 供应商订单管理
            - supplier-score-view.html: 查看供应商评分

            【供应商相关页面】
            - suppliers.html: 供应商列表（搜索、筛选）
            - supplier-detail.html: 供应商详情（资质、产品、评价）
            - supplier-map.html: 供应商地图分布（可视化查看供应商地理位置）

            【生产监控 production-monitor.html / production-detail.html】📊
            - 实时查看生产进度
            - 各环节可视化监控（原材料 → 生产 → 质检 → 包装 → 发货）
            - supplier-monitor-upload.html: 供应商上传生产进度
            - monitor-settings.html: 监控预警设置

            【发货确认 delivery-confirm.html】📦
            - 确认收货、验收操作

            【发布需求 publish-demand.html】
            - 发布采购需求，等待供应商报价
            - 填写产品描述、数量、预算、交期等

            【询价 inquiry.html / quote-detail.html】
            - 向供应商发送询价请求
            - 查看报价详情和对比

            【消息中心 messages.html / chat.html】💬
            - messages.html: 消息通知列表
            - chat.html: 与供应商/采购商实时聊天

            【新闻资讯 news.html / news-detail.html】📰
            - 行业新闻、平台公告、供应链资讯
            - 按分类浏览，点击可查看全文

            【企业认证 certification.html】✅
            - 企业资质认证流程
            - 上传营业执照等文件，提升平台信用

            【后台管理 admin.html】🔧（管理员专用）
            - 数据看板、用户管理、订单审核、内容管理
            - 合同模板审核、供应商审核

            【其他页面】
            - login.html: 登录/注册
            - help.html: 帮助中心
            - about.html: 关于平台
            - service.html: 服务介绍
            - dashboard.html: 数据看板
            - terms.html / privacy.html: 条款/隐私政策

            ═══════════════ 常见用户操作指引 ═══════════════

            1. 如何采购产品？
               → 智能匹配（推荐）：进入 smart-match.html，输入需求，AI自动匹配
               → 反向竞拍：进入 auction-create.html，发布需求，等供应商竞价
               → 直接询价：进入 inquiry.html，向指定供应商询价

            2. 如何查看/管理订单？
               → 进入 orders.html 查看所有订单
               → 点击订单号进入 order-detail.html 查看详情

            3. 如何成为供应商？
               → 进入 supplier-apply.html 填写入驻申请
               → 审核通过后进入 supplier-center.html 管理店铺

            4. 如何签署合同？
               → 智能匹配完成后自动跳转 contract-create.html
               → 选择模板 → 填写信息 → 提交 → 在 user-center.html 签署

            5. 如何监控生产？
               → 进入 production-monitor.html 查看实时进度
               → 设置预警通知在 monitor-settings.html

            ═══════════════ 回复规范 ═══════════════

            1. 语言：默认使用中文回复。如果用户使用英文则用英文回复。
            2. 风格：专业、简洁、友好，像一个熟悉平台的客服顾问。
            3. 操作引导：当用户问如何操作时，给出具体步骤和对应页面。
            4. 主动推荐：根据用户需求主动推荐合适的功能模块。
            5. 回复长度：一般控制在200字以内，除非需要展示详细数据。
            6. 当可以通过平台工具函数完成用户请求时，主动调用工具。
            7. 缺少参数时，友好地追问补充。
            8. 始终保持对话上下文记忆。
            """;

    // ========================= 页面上下文映射 =========================

    private static final Map<String, String> PAGE_CONTEXT = Map.ofEntries(
        Map.entry("index.html", "用户在首页浏览，可引导进入智能匹配或拍卖场"),
        Map.entry("smart-match.html", "用户在智能匹配页面，正在进行AI供应商匹配流程"),
        Map.entry("auction-list.html", "用户在电子拍卖场列表页，正在浏览拍卖项目"),
        Map.entry("auction-create.html", "用户在创建反向竞拍页面"),
        Map.entry("auction-detail.html", "用户在查看拍卖详情"),
        Map.entry("contract-create.html", "用户在创建合同页面，正在选择合同模板或填写合同信息"),
        Map.entry("contract-detail.html", "用户在查看合同详情"),
        Map.entry("orders.html", "用户在订单管理列表页"),
        Map.entry("order-detail.html", "用户在查看订单详情"),
        Map.entry("user-center.html", "用户在采购商个人中心"),
        Map.entry("supplier-center.html", "用户在供应商中心控制面板"),
        Map.entry("suppliers.html", "用户在浏览供应商列表"),
        Map.entry("supplier-detail.html", "用户在查看供应商详情"),
        Map.entry("supplier-apply.html", "用户在申请成为供应商"),
        Map.entry("production-monitor.html", "用户在查看生产监控"),
        Map.entry("publish-demand.html", "用户在发布采购需求"),
        Map.entry("inquiry.html", "用户在进行询价"),
        Map.entry("news.html", "用户在浏览新闻资讯"),
        Map.entry("login.html", "用户在登录/注册页面"),
        Map.entry("help.html", "用户在帮助中心"),
        Map.entry("admin.html", "用户在后台管理页面"),
        Map.entry("certification.html", "用户在进行企业认证"),
        Map.entry("messages.html", "用户在查看消息通知"),
        Map.entry("chat.html", "用户在即时通讯页面")
    );

    // ========================= Tool Definitions =========================

    private List<Map<String, Object>> getToolDefinitions() {
        List<Map<String, Object>> tools = new ArrayList<>();

        // 1. Product Search
        tools.add(buildTool("search_products", "搜索平台上的产品，根据名称、类别或关键词查找",
                Map.of(
                        "keyword", Map.of("type", "string", "description", "产品名称或搜索关键词，如'陶瓷杯'、'不锈钢水壶'、'手机壳'"),
                        "category", Map.of("type", "string", "description", "产品类别，如'陶瓷'、'金属'、'塑料'、'电子产品'"),
                        "min_quantity", Map.of("type", "integer", "description", "最小起订量")
                ),
                List.of("keyword")));

        // 2. Factory Matching
        tools.add(buildTool("match_factories", "根据产品和数量需求匹配合适的制造工厂",
                Map.of(
                        "product_name", Map.of("type", "string", "description", "要制造的产品名称"),
                        "quantity", Map.of("type", "integer", "description", "所需生产数量"),
                        "category", Map.of("type", "string", "description", "产品类别"),
                        "requirements", Map.of("type", "string", "description", "特殊要求，如材质、认证等")
                ),
                List.of("product_name")));

        // 3. Create Reverse Auction
        tools.add(buildTool("create_reverse_auction", "创建反向竞拍（采购商发布需求，供应商竞价）",
                Map.of(
                        "product_name", Map.of("type", "string", "description", "拍卖产品名称"),
                        "quantity", Map.of("type", "integer", "description", "采购数量"),
                        "unit", Map.of("type", "string", "description", "计量单位，如'件'、'千克'、'套'"),
                        "max_budget", Map.of("type", "number", "description", "每单位最高预算（人民币）"),
                        "deadline_days", Map.of("type", "integer", "description", "竞拍持续天数"),
                        "description", Map.of("type", "string", "description", "详细产品描述和要求")
                ),
                List.of("product_name", "quantity")));

        // 4. Cost Calculation
        tools.add(buildTool("calculate_cost", "计算产品的FOB/CIF成本，包括制造、内陆物流和海运",
                Map.of(
                        "product_name", Map.of("type", "string", "description", "产品名称"),
                        "quantity", Map.of("type", "integer", "description", "订购数量"),
                        "destination_country", Map.of("type", "string", "description", "目的国，如'美国'、'英国'、'德国'"),
                        "shipping_port", Map.of("type", "string", "description", "发货港口，如'深圳'、'上海'、'宁波'")
                ),
                List.of("product_name", "quantity")));

        // 5. Check Order/Auction Status
        tools.add(buildTool("check_order_status", "查询订单或拍卖的当前状态",
                Map.of(
                        "order_no", Map.of("type", "string", "description", "订单号，如'ORD20260223001'"),
                        "auction_id", Map.of("type", "string", "description", "拍卖ID")
                ),
                List.of()));

        // 6. Navigate Page - 引导用户到指定页面
        tools.add(buildTool("navigate_page", "引导用户前往平台指定页面。当用户需要执行某操作时，告诉他们该去哪个页面以及如何操作",
                Map.of(
                        "page", Map.of("type", "string", "description", "目标页面文件名，如'smart-match.html'、'auction-list.html'、'orders.html'、'user-center.html'、'supplier-apply.html'等"),
                        "action", Map.of("type", "string", "description", "在该页面需要执行的操作说明"),
                        "reason", Map.of("type", "string", "description", "引导用户去该页面的原因")
                ),
                List.of("page")));

        // 7. Explain Feature - 解释平台功能
        tools.add(buildTool("explain_feature", "详细解释平台的某个功能模块，包括用途、操作步骤和注意事项",
                Map.of(
                        "feature_name", Map.of("type", "string", "description", "功能名称，如'智能匹配'、'反向竞拍'、'合同管理'、'生产监控'、'供应商入驻'等"),
                        "detail_level", Map.of("type", "string", "description", "详细程度：'brief'简要说明 或 'detailed'详细步骤")
                ),
                List.of("feature_name")));

        return tools;
    }

    private Map<String, Object> buildTool(String name, String description,
                                           Map<String, Map<String, String>> properties,
                                           List<String> required) {
        Map<String, Object> tool = new LinkedHashMap<>();
        tool.put("type", "function");

        Map<String, Object> function = new LinkedHashMap<>();
        function.put("name", name);
        function.put("description", description);

        Map<String, Object> parameters = new LinkedHashMap<>();
        parameters.put("type", "object");
        parameters.put("properties", properties);
        parameters.put("required", required);
        function.put("parameters", parameters);

        tool.put("function", function);
        return tool;
    }

    // ========================= Chat Entry =========================

    public ChatResponse chat(ChatRequest request) {
        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isEmpty()) {
            sessionId = UUID.randomUUID().toString();
        }

        cleanExpiredSessions();

        // Build context-aware system prompt
        String contextPrompt = buildContextPrompt(request.getCurrentPage());

        // Get or create session history
        final String finalSessionId = sessionId;
        List<AIRequest.Message> history = sessions.computeIfAbsent(finalSessionId, k -> {
            List<AIRequest.Message> h = new ArrayList<>();
            h.add(AIRequest.Message.builder().role("system").content(contextPrompt).build());
            return h;
        });
        sessionTimestamps.put(sessionId, System.currentTimeMillis());

        // Update system prompt if page context changed
        if (request.getCurrentPage() != null && !request.getCurrentPage().isEmpty()) {
            history.set(0, AIRequest.Message.builder().role("system").content(contextPrompt).build());
        }

        // Add user message
        history.add(AIRequest.Message.builder().role("user").content(request.getMessage()).build());

        // Trim history if too long (keep system prompt + last N messages)
        if (history.size() > MAX_HISTORY + 1) {
            AIRequest.Message system = history.get(0);
            List<AIRequest.Message> recent = new ArrayList<>(history.subList(history.size() - MAX_HISTORY, history.size()));
            history.clear();
            history.add(system);
            history.addAll(recent);
        }

        // Build AI request
        AIRequest aiRequest = AIRequest.builder()
                .messages(new ArrayList<>(history))
                .temperature(0.7)
                .maxTokens(2000)
                .build();

        // Call with tools
        AIResponse aiResponse = deepSeekClient.callWithTools(aiRequest, getToolDefinitions());

        if (!aiResponse.getSuccess()) {
            log.error("DeepSeek API error: {}", aiResponse.getErrorMessage());
            return ChatResponse.builder()
                    .sessionId(sessionId)
                    .type("text")
                    .message("抱歉，我暂时无法处理您的请求，请稍后再试。")
                    .build();
        }

        // Check if tool calls were made
        if (aiResponse.getMetadata() != null
                && Boolean.TRUE.equals(aiResponse.getMetadata().get("has_tool_calls"))) {
            return handleToolCalls(sessionId, history, aiResponse);
        }

        // Regular text response
        String reply = aiResponse.getContent();
        history.add(AIRequest.Message.builder().role("assistant").content(reply).build());

        return ChatResponse.builder()
                .sessionId(sessionId)
                .type("text")
                .message(reply)
                .build();
    }

    /**
     * 根据用户当前页面生成增强的系统提示词
     */
    private String buildContextPrompt(String currentPage) {
        if (currentPage == null || currentPage.isEmpty()) {
            return SYSTEM_PROMPT;
        }
        // Extract page filename from URL
        String pageName = currentPage;
        if (pageName.contains("/")) {
            pageName = pageName.substring(pageName.lastIndexOf("/") + 1);
        }
        if (pageName.contains("?")) {
            pageName = pageName.substring(0, pageName.indexOf("?"));
        }
        if (pageName.contains("#")) {
            pageName = pageName.substring(0, pageName.indexOf("#"));
        }

        String pageContext = PAGE_CONTEXT.getOrDefault(pageName, "");
        if (pageContext.isEmpty()) {
            return SYSTEM_PROMPT;
        }

        return SYSTEM_PROMPT + "\n\n═══════════════ 当前页面上下文 ═══════════════\n" +
                "用户当前所在页面：" + pageName + "\n" +
                "页面说明：" + pageContext + "\n" +
                "请根据用户所在页面的上下文，提供更精准的帮助和引导。如果用户的问题与当前页面功能相关，可以给出具体的操作步骤。";
    }

    // ========================= Tool Call Handling =========================

    private ChatResponse handleToolCalls(String sessionId, List<AIRequest.Message> history, AIResponse aiResponse) {
        try {
            String toolCallsJson = (String) aiResponse.getMetadata().get("tool_calls");
            JsonNode toolCalls = objectMapper.readTree(toolCallsJson);
            JsonNode firstCall = toolCalls.get(0);

            String functionName = firstCall.path("function").path("name").asText();
            String argsJson = firstCall.path("function").path("arguments").asText();
            Map<String, Object> args = objectMapper.readValue(argsJson, new TypeReference<>() {});

            log.info("AI tool call: {} with args: {}", functionName, args);

            // Execute the function and get result
            FunctionResult result = executeFunction(functionName, args);
            String resultJson = objectMapper.writeValueAsString(result.data);

            // Add assistant intent + tool result
            history.add(AIRequest.Message.builder()
                    .role("assistant")
                    .content("调用平台功能: " + functionName + "，参数: " + argsJson)
                    .build());
            history.add(AIRequest.Message.builder()
                    .role("user")
                    .content("以下是 " + functionName + " 的结果:\n" + resultJson + "\n\n请用自然、友好的语言总结这些结果给用户。如果有操作建议，请一并给出。")
                    .build());

            // Ask AI to generate a natural language response based on tool result
            AIRequest followUp = AIRequest.builder()
                    .messages(new ArrayList<>(history))
                    .temperature(0.7)
                    .maxTokens(2000)
                    .build();

            AIResponse followUpResponse = deepSeekClient.call(followUp);
            String reply;
            if (followUpResponse.getSuccess() && followUpResponse.getContent() != null) {
                reply = followUpResponse.getContent();
            } else {
                reply = result.fallbackMessage;
            }

            history.add(AIRequest.Message.builder().role("assistant").content(reply).build());

            return ChatResponse.builder()
                    .sessionId(sessionId)
                    .type(result.type)
                    .message(reply)
                    .data(result.data)
                    .extra(result.extra)
                    .build();

        } catch (Exception e) {
            log.error("Error handling tool calls", e);
            return ChatResponse.builder()
                    .sessionId(sessionId)
                    .type("text")
                    .message("我已找到相关信息，但在展示时遇到了问题。您可以换个方式描述您的需求吗？")
                    .build();
        }
    }

    // ========================= Function Implementations =========================

    private record FunctionResult(String type, List<Map<String, Object>> data, Map<String, Object> extra, String fallbackMessage) {}

    private FunctionResult executeFunction(String name, Map<String, Object> args) {
        return switch (name) {
            case "search_products" -> searchProducts(args);
            case "match_factories" -> matchFactories(args);
            case "create_reverse_auction" -> createReverseAuction(args);
            case "calculate_cost" -> calculateCost(args);
            case "check_order_status" -> checkOrderStatus(args);
            case "navigate_page" -> navigatePage(args);
            case "explain_feature" -> explainFeature(args);
            default -> new FunctionResult("text", List.of(), null, "暂时还不支持这个功能，请尝试其他操作。");
        };
    }

    private FunctionResult searchProducts(Map<String, Object> args) {
        String keyword = (String) args.getOrDefault("keyword", "");
        String category = (String) args.getOrDefault("category", "");

        List<Map<String, Object>> products = new ArrayList<>();
        String kw = keyword.toLowerCase();

        if (kw.contains("mug") || kw.contains("cup") || kw.contains("ceramic") || kw.contains("杯") || kw.contains("陶瓷")) {
            products.add(Map.of("name", "定制陶瓷咖啡杯 11oz", "category", "陶瓷", "minOrder", 500, "priceRange", "¥8 - ¥20", "rating", 4.8, "supplier", "潮州裕鑫陶瓷"));
            products.add(Map.of("name", "Logo印花瓷杯", "category", "陶瓷", "minOrder", 1000, "priceRange", "¥6 - ¥15", "rating", 4.6, "supplier", "德化泉裕瓷厂"));
            products.add(Map.of("name", "彩釉陶瓷杯套装", "category", "陶瓷", "minOrder", 200, "priceRange", "¥18 - ¥28", "rating", 4.7, "supplier", "景德镇艺术陶瓷"));
        } else if (kw.contains("bottle") || kw.contains("steel") || kw.contains("water") || kw.contains("水壶") || kw.contains("不锈钢")) {
            products.add(Map.of("name", "304不锈钢保温水壶 500ml", "category", "金属制品", "minOrder", 500, "priceRange", "¥20 - ¥38", "rating", 4.9, "supplier", "永康好钢制品"));
            products.add(Map.of("name", "真空保温运动水杯", "category", "金属制品", "minOrder", 300, "priceRange", "¥25 - ¥50", "rating", 4.7, "supplier", "浙江飞剑工贸"));
        } else if (kw.contains("phone") || kw.contains("case") || kw.contains("手机") || kw.contains("壳")) {
            products.add(Map.of("name", "TPU手机壳定制图案", "category", "电子配件", "minOrder", 100, "priceRange", "¥2 - ¥8", "rating", 4.5, "supplier", "深圳手机配件厂"));
            products.add(Map.of("name", "硅胶防摔手机保护套", "category", "电子配件", "minOrder", 200, "priceRange", "¥3 - ¥12", "rating", 4.6, "supplier", "东莞硅胶科技"));
        } else {
            products.add(Map.of("name", keyword + " - 标准品质", "category", category.isEmpty() ? "综合" : category, "minOrder", 500, "priceRange", "¥7 - ¥35", "rating", 4.5, "supplier", "认证供应商"));
            products.add(Map.of("name", keyword + " - 优质款", "category", category.isEmpty() ? "综合" : category, "minOrder", 200, "priceRange", "¥20 - ¥55", "rating", 4.8, "supplier", "金牌供应商"));
        }

        return new FunctionResult("product_list", products, Map.of("keyword", keyword, "totalResults", products.size()),
                "找到 " + products.size() + " 个与'" + keyword + "'相关的产品。");
    }

    private FunctionResult matchFactories(Map<String, Object> args) {
        String productName = (String) args.getOrDefault("product_name", "");
        int quantity = args.containsKey("quantity") ? ((Number) args.get("quantity")).intValue() : 0;

        List<Map<String, Object>> factories = new ArrayList<>();
        String pn = productName.toLowerCase();

        if (pn.contains("mug") || pn.contains("cup") || pn.contains("ceramic") || pn.contains("杯") || pn.contains("陶瓷")) {
            factories.add(Map.of("name", "潮州裕鑫陶瓷有限公司", "location", "广东潮州", "specialty", "定制陶瓷杯、餐具", "capacity", "50万件/月", "matchScore", 96, "moq", 500, "leadTime", "15-20天"));
            factories.add(Map.of("name", "德化泉裕瓷厂", "location", "福建德化", "specialty", "瓷杯、礼品套装", "capacity", "30万件/月", "matchScore", 92, "moq", 1000, "leadTime", "18-25天"));
            factories.add(Map.of("name", "景德镇皇家陶瓷", "location", "江西景德镇", "specialty", "高端陶瓷制品", "capacity", "10万件/月", "matchScore", 88, "moq", 200, "leadTime", "20-30天"));
        } else if (pn.contains("bottle") || pn.contains("steel") || pn.contains("水壶") || pn.contains("不锈钢")) {
            factories.add(Map.of("name", "永康好钢制品有限公司", "location", "浙江永康", "specialty", "不锈钢水壶保温杯", "capacity", "20万件/月", "matchScore", 95, "moq", 500, "leadTime", "12-18天"));
            factories.add(Map.of("name", "浙江飞剑工贸", "location", "浙江武义", "specialty", "真空保温器皿", "capacity", "40万件/月", "matchScore", 91, "moq", 1000, "leadTime", "15-20天"));
        } else {
            factories.add(Map.of("name", "广东精造制造有限公司", "location", "广东东莞", "specialty", "OEM/ODM制造", "capacity", "弹性产能", "matchScore", 90, "moq", 500, "leadTime", "15-25天"));
            factories.add(Map.of("name", "浙江优品出口有限公司", "location", "浙江义乌", "specialty", "综合商品生产", "capacity", "大批量", "matchScore", 85, "moq", 1000, "leadTime", "20-30天"));
        }

        Map<String, Object> extra = new HashMap<>();
        extra.put("product", productName);
        extra.put("quantity", quantity);
        extra.put("matchCount", factories.size());

        return new FunctionResult("factory_list", factories, extra,
                "为'" + productName + "'匹配到 " + factories.size() + " 家工厂。");
    }

    private FunctionResult createReverseAuction(Map<String, Object> args) {
        String productName = (String) args.getOrDefault("product_name", "");
        int quantity = args.containsKey("quantity") ? ((Number) args.get("quantity")).intValue() : 0;
        String unit = (String) args.getOrDefault("unit", "件");
        int deadlineDays = args.containsKey("deadline_days") ? ((Number) args.get("deadline_days")).intValue() : 7;
        String description = (String) args.getOrDefault("description", "");

        Map<String, Object> auctionData = new LinkedHashMap<>();
        auctionData.put("productName", productName);
        auctionData.put("quantity", quantity);
        auctionData.put("unit", unit);
        auctionData.put("deadlineDays", deadlineDays);
        auctionData.put("description", description.isEmpty() ? productName + " - " + quantity + " " + unit : description);
        auctionData.put("status", "DRAFT");

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("action", "confirm_auction");
        extra.put("formData", auctionData);

        return new FunctionResult("auction_form", List.of(auctionData), extra,
                "已为您准备好 " + quantity + " " + unit + " " + productName + " 的反向竞拍，请确认并提交。");
    }

    private FunctionResult calculateCost(Map<String, Object> args) {
        String productName = (String) args.getOrDefault("product_name", "");
        int quantity = args.containsKey("quantity") ? ((Number) args.get("quantity")).intValue() : 1000;
        String destination = (String) args.getOrDefault("destination_country", "美国");
        String port = (String) args.getOrDefault("shipping_port", "深圳");

        double baseCost;
        String pn = productName.toLowerCase();
        if (pn.contains("mug") || pn.contains("cup") || pn.contains("ceramic") || pn.contains("杯") || pn.contains("陶瓷")) {
            baseCost = 10.0;
        } else if (pn.contains("bottle") || pn.contains("steel") || pn.contains("水壶") || pn.contains("不锈钢")) {
            baseCost = 26.0;
        } else if (pn.contains("phone") || pn.contains("case") || pn.contains("手机")) {
            baseCost = 4.5;
        } else {
            baseCost = 17.0;
        }

        if (quantity >= 10000) baseCost *= 0.85;
        else if (quantity >= 5000) baseCost *= 0.90;
        else if (quantity >= 1000) baseCost *= 0.95;

        double materialCost = Math.round(baseCost * 0.45 * 100.0) / 100.0;
        double processingCost = Math.round(baseCost * 0.35 * 100.0) / 100.0;
        double packagingCost = Math.round(baseCost * 0.12 * 100.0) / 100.0;
        double wasteCost = Math.round(baseCost * 0.08 * 100.0) / 100.0;
        double unitCost = materialCost + processingCost + packagingCost + wasteCost;
        double domesticLogistics = 0.35;
        double oceanFreight = destination.contains("美") ? 1.0 : destination.contains("英") ? 1.2 : 0.8;
        double fobPrice = Math.round((unitCost + domesticLogistics + oceanFreight) * 100.0) / 100.0;
        double totalCost = Math.round(fobPrice * quantity * 100.0) / 100.0;

        Map<String, Object> costData = new LinkedHashMap<>();
        costData.put("product", productName);
        costData.put("quantity", quantity);
        costData.put("destination", destination);
        costData.put("originPort", port);
        costData.put("materialCost", "¥" + materialCost);
        costData.put("processingCost", "¥" + processingCost);
        costData.put("packagingCost", "¥" + packagingCost);
        costData.put("wasteCost", "¥" + wasteCost);
        costData.put("unitManufacturingCost", "¥" + unitCost);
        costData.put("domesticLogistics", "¥" + domesticLogistics);
        costData.put("oceanFreight", "¥" + oceanFreight);
        costData.put("fobPricePerUnit", "¥" + fobPrice);
        costData.put("totalFOBCost", "¥" + totalCost);
        costData.put("currency", "CNY");

        return new FunctionResult("cost_result", List.of(costData), Map.of("fobPrice", fobPrice, "totalCost", totalCost),
                productName + " " + quantity + "件到" + destination + "的FOB成本估算已完成。");
    }

    private FunctionResult checkOrderStatus(Map<String, Object> args) {
        String orderNo = (String) args.getOrDefault("order_no", "");
        String auctionId = (String) args.getOrDefault("auction_id", "");

        List<Map<String, Object>> results = new ArrayList<>();

        if (orderNo != null && !orderNo.isEmpty()) {
            Map<String, Object> order = new LinkedHashMap<>();
            if (orderNo.contains("001")) {
                order.put("orderNo", orderNo);
                order.put("status", "已发货");
                order.put("product", "包装箱");
                order.put("quantity", 50000);
                order.put("totalAmount", "¥265,000");
                order.put("supplier", "东莞精密制造");
                order.put("trackingNo", "SF1234567890");
                order.put("estimatedDelivery", "预计5天内到达");
            } else {
                order.put("orderNo", orderNo);
                order.put("status", "处理中");
                order.put("message", "订单正在处理中");
            }
            results.add(order);
            return new FunctionResult("order_status", results, null, "订单 " + orderNo + " 状态已查询。");
        }

        if (auctionId != null && !auctionId.isEmpty()) {
            Map<String, Object> auction = new LinkedHashMap<>();
            auction.put("auctionId", auctionId);
            auction.put("status", "竞拍中");
            auction.put("bidsReceived", 3);
            auction.put("lowestBid", "¥13/件");
            auction.put("timeRemaining", "剩余2天14小时");
            results.add(auction);
            return new FunctionResult("order_status", results, null, "拍卖 " + auctionId + " 状态已查询。");
        }

        results.add(Map.of("message", "请提供订单号或拍卖ID以查询状态。"));
        return new FunctionResult("text", results, null, "请提供您的订单号或拍卖ID。");
    }

    /**
     * 页面导航引导
     */
    private FunctionResult navigatePage(Map<String, Object> args) {
        String page = (String) args.getOrDefault("page", "");
        String action = (String) args.getOrDefault("action", "");
        String reason = (String) args.getOrDefault("reason", "");

        Map<String, Object> navData = new LinkedHashMap<>();
        navData.put("page", page);
        navData.put("url", page);
        navData.put("action", action);
        navData.put("reason", reason);

        // 页面中文名映射
        Map<String, String> pageNames = Map.ofEntries(
            Map.entry("smart-match.html", "智能匹配"),
            Map.entry("auction-list.html", "电子拍卖场"),
            Map.entry("auction-create.html", "发布竞拍"),
            Map.entry("orders.html", "订单管理"),
            Map.entry("user-center.html", "采购商中心"),
            Map.entry("supplier-center.html", "供应商中心"),
            Map.entry("supplier-apply.html", "供应商入驻"),
            Map.entry("suppliers.html", "供应商列表"),
            Map.entry("production-monitor.html", "生产监控"),
            Map.entry("publish-demand.html", "发布需求"),
            Map.entry("inquiry.html", "询价"),
            Map.entry("contract-create.html", "创建合同"),
            Map.entry("news.html", "新闻资讯"),
            Map.entry("certification.html", "企业认证"),
            Map.entry("help.html", "帮助中心"),
            Map.entry("messages.html", "消息中心"),
            Map.entry("index.html", "首页")
        );

        navData.put("pageName", pageNames.getOrDefault(page, page));

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("navigateTo", page);

        return new FunctionResult("navigation", List.of(navData), extra,
                "建议您前往「" + pageNames.getOrDefault(page, page) + "」页面。");
    }

    /**
     * 功能说明
     */
    private FunctionResult explainFeature(Map<String, Object> args) {
        String featureName = (String) args.getOrDefault("feature_name", "");
        String detailLevel = (String) args.getOrDefault("detail_level", "brief");

        Map<String, Object> featureData = new LinkedHashMap<>();
        featureData.put("featureName", featureName);
        featureData.put("detailLevel", detailLevel);

        // 功能详情映射
        Map<String, Map<String, String>> featureDetails = new LinkedHashMap<>();
        featureDetails.put("智能匹配", Map.of(
            "summary", "AI驱动的供应商智能匹配系统，根据您的采购需求自动推荐最优供应商",
            "steps", "1. 进入智能匹配页面\n2. 描述采购需求（产品名称、数量、规格等）\n3. AI分析需求并推荐匹配供应商\n4. 查看供应商详情和报价\n5. 选择供应商后自动进入FOB报价\n6. 确认后生成采购合同",
            "page", "smart-match.html"
        ));
        featureDetails.put("反向竞拍", Map.of(
            "summary", "采购商发布需求，供应商向下竞价，实现透明高效的采购",
            "steps", "1. 进入电子拍卖场\n2. 点击「发布采购反拍」\n3. 填写产品名称、数量、起拍价、竞拍时长\n4. 发布后等待供应商竞价\n5. 竞拍结束后选择最优供应商\n6. 生成采购合同",
            "page", "auction-create.html"
        ));
        featureDetails.put("合同管理", Map.of(
            "summary", "从智能匹配或拍卖流程进入，选择合同模板，填写信息后签署",
            "steps", "1. 完成智能匹配/拍卖后自动跳转合同页面\n2. 选择合同模板（基础版/专业版/企业版）\n3. 也可上传自定义合同模板（需平台审核）\n4. 确认合同信息\n5. 提交后在采购商中心签署\n注：平台统一收取2%服务费",
            "page", "contract-create.html"
        ));
        featureDetails.put("生产监控", Map.of(
            "summary", "实时可视化监控生产全流程，从原材料到出货",
            "steps", "1. 进入生产监控页面\n2. 选择要监控的订单\n3. 查看各环节进度（原材料→生产→质检→包装→发货）\n4. 可设置预警通知\n5. 供应商上传实时进度更新",
            "page", "production-monitor.html"
        ));
        featureDetails.put("供应商入驻", Map.of(
            "summary", "供应商可申请入驻平台，经审核后开展业务",
            "steps", "1. 进入供应商入驻页面\n2. 填写企业基本信息\n3. 上传营业执照等资质文件\n4. 提交审核\n5. 审核通过后进入供应商中心管理商品和订单",
            "page", "supplier-apply.html"
        ));

        String fn = featureName;
        // 模糊匹配
        for (String key : featureDetails.keySet()) {
            if (featureName.contains(key) || key.contains(featureName)) {
                fn = key;
                break;
            }
        }

        Map<String, String> detail = featureDetails.getOrDefault(fn, Map.of(
            "summary", featureName + " - 平台功能模块",
            "steps", "请前往帮助中心了解更多详情",
            "page", "help.html"
        ));

        featureData.put("summary", detail.get("summary"));
        featureData.put("steps", detail.get("steps"));
        featureData.put("relatedPage", detail.get("page"));

        Map<String, Object> extra = new LinkedHashMap<>();
        extra.put("navigateTo", detail.get("page"));

        return new FunctionResult("feature_explain", List.of(featureData), extra,
                detail.get("summary"));
    }

    private void cleanExpiredSessions() {
        long now = System.currentTimeMillis();
        if (sessions.size() > MAX_SESSIONS) {
            sessionTimestamps.entrySet().removeIf(e -> {
                if (now - e.getValue() > SESSION_TTL_MS) {
                    sessions.remove(e.getKey());
                    return true;
                }
                return false;
            });
        }
    }
}
