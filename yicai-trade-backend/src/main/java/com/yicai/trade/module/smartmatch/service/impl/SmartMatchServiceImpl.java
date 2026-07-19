package com.yicai.trade.module.smartmatch.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.yicai.trade.common.ai.client.*;
import com.yicai.trade.common.ai.util.AIRetryHelper;
import com.yicai.trade.module.smartmatch.dto.*;
import com.yicai.trade.module.smartmatch.service.SmartMatchService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class SmartMatchServiceImpl implements SmartMatchService {

    private final DoubaoVisionClient visionClient;
    private final DoubaoTextClient textClient;
    private final ZhipuAIClient zhipuClient;
    private final ObjectMapper objectMapper;
    private final AIRetryHelper aiRetryHelper;
    
    /** 会话缓存，带TTL自动清理 */
    private final Map<String, SessionEntry> sessionCache = new ConcurrentHashMap<>();
    /** 会话最大存活时间: 30分钟 */
    private static final long SESSION_TTL_MS = 30 * 60 * 1000;
    /** 会话缓存最大容量 */
    private static final int SESSION_MAX_SIZE = 500;
    /** 定时清理线程 */
    private final ScheduledExecutorService sessionCleaner = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread t = new Thread(r, "session-cleaner");
        t.setDaemon(true);
        return t;
    });
    
    /** 会话条目（带创建时间） */
    private static class SessionEntry {
        final Map<String, Object> data;
        final long createdAt;
        
        SessionEntry(Map<String, Object> data) {
            this.data = data;
            this.createdAt = System.currentTimeMillis();
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() - createdAt > SESSION_TTL_MS;
        }
    }

    public SmartMatchServiceImpl(DoubaoVisionClient visionClient, 
                                  DoubaoTextClient textClient,
                                  ZhipuAIClient zhipuClient,
                                  ObjectMapper objectMapper,
                                  AIRetryHelper aiRetryHelper) {
        this.visionClient = visionClient;
        this.textClient = textClient;
        this.zhipuClient = zhipuClient;
        this.objectMapper = objectMapper;
        this.aiRetryHelper = aiRetryHelper;
        
        // 每5分钟清理一次过期会话
        sessionCleaner.scheduleAtFixedRate(this::cleanExpiredSessions, 5, 5, TimeUnit.MINUTES);
    }
    
    /** 定时清理过期会话 */
    private void cleanExpiredSessions() {
        int before = sessionCache.size();
        sessionCache.entrySet().removeIf(e -> e.getValue().isExpired());
        int removed = before - sessionCache.size();
        if (removed > 0) {
            log.info("清理过期会话: 移除{}个, 剩余{}个", removed, sessionCache.size());
        }
    }
    
    /** 获取会话数据，自动校验有效性 */
    private Map<String, Object> getSession(String sessionId) {
        SessionEntry entry = sessionCache.get(sessionId);
        if (entry == null) {
            throw new RuntimeException("会话不存在或已过期,请重新开始匹配 (sessionId: " + sessionId + ")");
        }
        if (entry.isExpired()) {
            sessionCache.remove(sessionId);
            throw new RuntimeException("会话已过期(超过30分钟),请重新开始匹配");
        }
        return entry.data;
    }
    
    /** 创建新会话 */
    private String createSession(Map<String, Object> data) {
        // 超容量时强制清理
        if (sessionCache.size() >= SESSION_MAX_SIZE) {
            cleanExpiredSessions();
            if (sessionCache.size() >= SESSION_MAX_SIZE) {
                log.warn("会话缓存已满({}),移除最早的会话", SESSION_MAX_SIZE);
                sessionCache.entrySet().stream()
                    .min(Comparator.comparingLong(e -> e.getValue().createdAt))
                    .ifPresent(e -> sessionCache.remove(e.getKey()));
            }
        }
        String sessionId = UUID.randomUUID().toString();
        sessionCache.put(sessionId, new SessionEntry(data));
        return sessionId;
    }
    
    // ====== JSON 安全解析工具方法 ======
    
    /** 安全获取JSON文本字段 */
    private String safeText(JsonNode node, String field, String defaultValue) {
        if (node == null || !node.has(field) || node.get(field).isNull()) return defaultValue;
        return node.get(field).asText(defaultValue);
    }
    
    /** 安全获取JSON数值字段 */
    private double safeDouble(JsonNode node, String field, double defaultValue) {
        if (node == null || !node.has(field) || node.get(field).isNull()) return defaultValue;
        try {
            return node.get(field).asDouble(defaultValue);
        } catch (Exception e) {
            return defaultValue;
        }
    }
    
    /** 安全获取JSON整数字段 */
    private int safeInt(JsonNode node, String field, int defaultValue) {
        if (node == null || !node.has(field) || node.get(field).isNull()) return defaultValue;
        try {
            return node.get(field).asInt(defaultValue);
        } catch (Exception e) {
            return defaultValue;
        }
    }
    
    /** 安全获取JSON布尔字段 */
    private boolean safeBoolean(JsonNode node, String field, boolean defaultValue) {
        if (node == null || !node.has(field) || node.get(field).isNull()) return defaultValue;
        return node.get(field).asBoolean(defaultValue);
    }
    
    /** 安全解析BigDecimal,支持带逗号/空格/货币符号的数值 */
    private BigDecimal safeBigDecimal(JsonNode node, String field, BigDecimal defaultValue) {
        if (node == null || !node.has(field) || node.get(field).isNull()) return defaultValue;
        String text = node.get(field).asText("").trim();
        if (text.isEmpty()) return defaultValue;
        try {
            // 移除常见的非数字字符(货币符号、空格、逗号)
            text = text.replaceAll("[¥$€£,\\s]", "");
            return new BigDecimal(text);
        } catch (NumberFormatException e) {
            log.warn("BigDecimal解析失败: field={}, value='{}', 使用默认值: {}", field, text, defaultValue);
            return defaultValue;
        }
    }

    // ====== 多语言辅助方法 ======
    
    /** 规范化语言代码 */
    private String normalizeLang(String lang) {
        if (lang == null || lang.isEmpty()) return "zh";
        lang = lang.toLowerCase().trim();
        if (lang.startsWith("en")) return "en";
        if (lang.startsWith("es")) return "es";
        return "zh";
    }
    
    /** 获取AI输出语言指令前缀 */
    private String langInstruction(String lang) {
        switch (normalizeLang(lang)) {
            case "en": return "IMPORTANT: You MUST respond entirely in English. All text values in the JSON (names, descriptions, options, notes) must be in English.\n\n";
            case "es": return "IMPORTANTE: DEBES responder completamente en español. Todos los valores de texto en el JSON (nombres, descripciones, opciones, notas) deben estar en español.\n\n";
            default: return "";
        }
    }
    
    /** 根据语言返回"其他"选项文本 */
    private String otherLabel(String lang) {
        switch (normalizeLang(lang)) {
            case "en": return "Other";
            case "es": return "Otro";
            default: return "其他";
        }
    }

    @Override
    public CategoryMatchResponse matchCategories(String productName, String imageUrl, String lang) {
        Map<String, Object> session = new HashMap<>();
        session.put("productName", productName);
        session.put("imageUrl", imageUrl);
        
        if (imageUrl != null && !imageUrl.isEmpty()) {
            AIRequest visionRequest = AIRequest.builder()
                    .messages(Arrays.asList(
                            AIRequest.Message.builder()
                                    .role("user")
                                    .contentParts(Arrays.asList(
                                            AIRequest.ContentPart.builder()
                                                    .type("text")
                                                    .text(langInstruction(lang) + "请识别这张产品图片,提取产品名称、品类、材质、工艺、尺寸等信息,以JSON格式返回")
                                                    .build(),
                                            AIRequest.ContentPart.builder()
                                                    .type("image_url")
                                                    .imageUrl(AIRequest.ImageUrl.builder().url(imageUrl).build())
                                                    .build()
                                    ))
                                    .build()
                    ))
                    .temperature(0.1)
                    .build();
            
            AIResponse visionResponse = aiRetryHelper.callWithRetry(visionClient, visionRequest);
            if (visionResponse.getSuccess()) {
                session.put("imageRecognition", visionResponse.getContent());
            }
        }
        
        String prompt = langInstruction(lang) + String.format(
                "用户输入的产品名称是: %s\n" +
                "请根据这个产品名称,匹配3-5个相关的标准品类。\n" +
                "返回JSON数组,每个品类包含: categoryName(品类名), categoryCode(品类代码), matchScore(匹配分数0-100), description(描述)\n" +
                "最后必须添加一个\"%s\"选项,categoryCode为\"OTHER\"\n" +
                "只返回JSON数组,不要其他文字",
                productName, otherLabel(lang)
        );
        
        AIRequest textRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(prompt)
                                .build()
                ))
                .temperature(0.3)
                .build();
        
        AIResponse textResponse = aiRetryHelper.callWithRetry(textClient, textRequest);
        
        List<ProductCategory> categories = new ArrayList<>();
        if (textResponse.getSuccess()) {
            try {
                String jsonContent = cleanAIJsonResponse(textResponse.getContent());
                JsonNode categoriesNode = objectMapper.readTree(jsonContent);
                for (JsonNode node : categoriesNode) {
                    ProductCategory category = ProductCategory.builder()
                            .categoryName(safeText(node, "categoryName", "未知品类"))
                            .categoryCode(safeText(node, "categoryCode", "UNKNOWN"))
                            .matchScore(safeDouble(node, "matchScore", 0.0))
                            .description(safeText(node, "description", ""))
                            .build();
                    categories.add(category);
                }
            } catch (Exception e) {
                log.error("品类匹配JSON解析失败, 原始内容: {}", textResponse.getContent(), e);
                categories.add(ProductCategory.builder()
                        .categoryName(otherLabel(lang))
                        .categoryCode("OTHER")
                        .matchScore(0.0)
                        .description("en".equals(normalizeLang(lang)) ? "AI auto match" : "es".equals(normalizeLang(lang)) ? "Coincidencia automática de IA" : "AI自动匹配")
                        .build());
            }
        }
        
        session.put("matchedCategories", categories);
        String sessionId = createSession(session);
        
        return CategoryMatchResponse.builder()
                .productName(productName)
                .matchedCategories(categories)
                .sessionId(sessionId)
                .build();
    }

    @Override
    public ParameterResponse getCostParameters(ParameterRequest request, String lang) {
        log.info("=== 获取成本参数开始 === sessionId={}, categoryCode={}", request.getSessionId(), request.getCategoryCode());
        
        Map<String, Object> session = getSession(request.getSessionId());
        
        String categoryCode = request.getCategoryCode();
        String productName = (String) session.get("productName");
        session.put("selectedCategory", categoryCode);
        
        // 从会话中查找用户选中品类的中文名称，用于增强AI Prompt上下文
        String categoryName = categoryCode;
        @SuppressWarnings("unchecked")
        List<ProductCategory> matchedCategories = (List<ProductCategory>) session.get("matchedCategories");
        if (matchedCategories != null) {
            categoryName = matchedCategories.stream()
                    .filter(c -> categoryCode.equals(c.getCategoryCode()))
                    .map(ProductCategory::getCategoryName)
                    .findFirst().orElse(categoryCode);
        }
        session.put("selectedCategoryName", categoryName);
        
        log.info("产品名称: {}, 选中品类: {}({})", productName, categoryName, categoryCode);
        
        List<ProductParameter> parameters = null;
        
        // 始终调用AI生成产品专属参数（三模型架构核心：豆包Text负责参数生成）
        log.info("=== 调用豆包AI生成产品专属成本参数 ===");
        
        String prompt = langInstruction(lang) + String.format(
                "产品名称: %s\n" +
                "品类: %s\n" +
                "品类代码: %s\n\n" +
                "请作为一个专业的外贸采购专家,分析这个产品,生成成本预估所需的关键参数列表。\n\n" +
                "要求:\n" +
                "1. 根据该产品在所选品类下的具体特性,智能推荐5-10个最关键的成本影响因素\n" +
                "2. **材质选项必须与产品品类高度相关**,例如陶瓷杯必须包含陶瓷/骨瓷/炻瓷等选项,不锈钢杯必须包含304不锈钢/316不锈钢等选项\n" +
                "3. 参数应该涵盖: 材质/工艺/尺寸/数量/定制需求等\n" +
                "4. 每个参数都要提供合理的选项范围\n" +
                "5. 专业参数允许用户选择'不清楚,由AI按行业常规预估'\n\n" +
                "返回JSON数组格式,每个参数对象包含:\n" +
                "{\n" +
                "  \"parameterName\": \"参数名称\",\n" +
                "  \"parameterCode\": \"参数代码(英文小写+下划线)\",\n" +
                "  \"parameterType\": \"select\",\n" +
                "  \"options\": [\"选项1\", \"选项2\", \"选项3\"],\n" +
                "  \"allowAIEstimate\": true,\n" +
                "  \"aiEstimateOption\": \"不清楚,由AI按行业常规预估\",\n" +
                "  \"required\": true,\n" +
                "  \"unit\": \"单位(可选)\",\n" +
                "  \"description\": \"参数说明\"\n" +
                "}\n\n" +
                "只返回JSON数组,不要任何其他文字说明。",
                productName, categoryName, categoryCode
        );
        
        AIRequest textRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(prompt)
                                .build()
                ))
                .temperature(0.3)
                .build();
        
        log.info("开始调用豆包AI生成参数...");
        long startTime = System.currentTimeMillis();
        
        AIResponse textResponse = null;
        try {
            textResponse = aiRetryHelper.callWithRetry(textClient, textRequest);
            long duration = System.currentTimeMillis() - startTime;
            log.info("豆包AI调用完成,耗时: {}ms, 成功: {}", duration, textResponse.getSuccess());
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("豆包AI调用异常,耗时: {}ms", duration, e);
            throw new RuntimeException("AI服务调用失败: " + e.getMessage(), e);
        }
        
        parameters = new ArrayList<>();
        if (textResponse.getSuccess()) {
            try {
                String jsonContent = cleanAIJsonResponse(textResponse.getContent());
                JsonNode parametersNode = objectMapper.readTree(jsonContent);
                log.info("成功解析参数JSON,参数数量: {}", parametersNode.size());
                for (JsonNode node : parametersNode) {
                    ProductParameter param = ProductParameter.builder()
                            .parameterName(safeText(node, "parameterName", "未知参数"))
                            .parameterCode(safeText(node, "parameterCode", "unknown_" + parameters.size()))
                            .parameterType(safeText(node, "parameterType", "select"))
                            .options(node.has("options") ? objectMapper.convertValue(node.get("options"), new TypeReference<List<String>>() {}) : null)
                            .allowAIEstimate(safeBoolean(node, "allowAIEstimate", true))
                            .aiEstimateOption(safeText(node, "aiEstimateOption", null))
                            .required(safeBoolean(node, "required", true))
                            .unit(safeText(node, "unit", null))
                            .description(safeText(node, "description", ""))
                            .build();
                    parameters.add(param);
                }
            } catch (Exception e) {
                throw new RuntimeException("参数解析失败: " + e.getMessage(), e);
            }
        } else {
            log.error("AI未能成功生成参数,错误: {}", textResponse.getErrorMessage());
            throw new RuntimeException("AI未能生成参数: " + textResponse.getErrorMessage());
        }
        
        session.put("costParameters", parameters);
        
        log.info("=== 获取成本参数完成,共{}个参数 ===", parameters.size());
        
        return ParameterResponse.builder()
                .sessionId(request.getSessionId())
                .categoryCode(categoryCode)
                .stage("COST")
                .parameters(parameters)
                .build();
    }

    @Override
    public ParameterResponse getFOBParameters(ParameterRequest request, String lang) {
        log.info("=== 获取FOB参数开始 === sessionId={}", request.getSessionId());
        
        Map<String, Object> session = getSession(request.getSessionId());
        
        String productName = (String) session.get("productName");
        String categoryCode = (String) session.get("selectedCategory");
        String categoryName = (String) session.getOrDefault("selectedCategoryName", categoryCode);
        log.info("产品名称: {}, 品类: {}({})", productName, categoryName, categoryCode);
        
        List<ProductParameter> parameters = null;
        
        // 始终调用AI生成产品专属FOB参数（三模型架构核心：豆包Text负责参数生成）
        log.info("=== 调用豆包AI生成产品专属FOB参数 ===");
        
        String prompt = langInstruction(lang) + String.format(
                "产品名称: %s\n" +
                "品类: %s\n" +
                "品类代码: %s\n\n" +
                "请作为一个专业的外贸物流专家,为FOB价格计算生成必要的参数列表。\n\n" +
                "要求:\n" +
                "1. 根据产品特性,推荐5-7个影响FOB价格的关键参数\n" +
                "2. **必须包括**: \n" +
                "   - 供应商所在地/发货地(城市,如深圳/义乌/潮州等,用于计算国内运费)\n" +
                "   - 采购数量\n" +
                "   - 起运港(如深圳港/宁波港/上海港/广州港等)\n" +
                "   - 包装规格\n" +
                "3. 可选包括: 运输方式/交货期/定制包装要求/保险需求等\n" +
                "4. 提供实际的选项值(如真实的城市名和港口名称)\n" +
                "5. 发货地的选项应该是中国主要生产基地城市\n\n" +
                "返回JSON数组格式,每个参数对象包含:\n" +
                "{\n" +
                "  \"parameterName\": \"参数名称\",\n" +
                "  \"parameterCode\": \"参数代码(英文小写+下划线)\",\n" +
                "  \"parameterType\": \"select\",\n" +
                "  \"options\": [\"选项1\", \"选项2\", \"选项3\"],\n" +
                "  \"required\": true,\n" +
                "  \"unit\": \"单位(可选)\",\n" +
                "  \"description\": \"参数说明\"\n" +
                "}\n\n" +
                "只返回JSON数组,不要任何其他文字说明。",
                productName, categoryName, categoryCode
        );
        
        AIRequest textRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(prompt)
                                .build()
                ))
                .temperature(0.3)
                .build();
        
        log.info("开始调用豆包AI生成FOB参数...");
        long startTime = System.currentTimeMillis();
        
        AIResponse textResponse = null;
        try {
            textResponse = aiRetryHelper.callWithRetry(textClient, textRequest);
            long duration = System.currentTimeMillis() - startTime;
            log.info("豆包AI调用完成,耗时: {}ms, 成功: {}", duration, textResponse.getSuccess());
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("豆包AI调用异常,耗时: {}ms", duration, e);
            throw new RuntimeException("AI服务调用失败: " + e.getMessage(), e);
        }
        
        parameters = new ArrayList<>();
        if (textResponse.getSuccess()) {
            try {
                String jsonContent = cleanAIJsonResponse(textResponse.getContent());
                JsonNode parametersNode = objectMapper.readTree(jsonContent);
                log.info("成功解析FOB参数JSON,参数数量: {}", parametersNode.size());
                for (JsonNode node : parametersNode) {
                    ProductParameter param = ProductParameter.builder()
                            .parameterName(safeText(node, "parameterName", "未知参数"))
                            .parameterCode(safeText(node, "parameterCode", "unknown_" + parameters.size()))
                            .parameterType(safeText(node, "parameterType", "select"))
                            .options(node.has("options") ? objectMapper.convertValue(node.get("options"), new TypeReference<List<String>>() {}) : null)
                            .required(safeBoolean(node, "required", true))
                            .unit(safeText(node, "unit", null))
                            .description(safeText(node, "description", ""))
                            .build();
                    parameters.add(param);
                }
            } catch (Exception e) {
                log.error("FOB参数解析失败, 原始内容: {}", textResponse.getContent(), e);
                throw new RuntimeException("FOB参数解析失败: " + e.getMessage(), e);
            }
        } else {
            log.error("AI未能成功生成FOB参数,错误: {}", textResponse.getErrorMessage());
            throw new RuntimeException("AI未能生成FOB参数: " + textResponse.getErrorMessage());
        }
        
        session.put("fobParameters", parameters);
        
        log.info("=== 获取FOB参数完成,共{}个参数 ===", parameters.size());
        
        return ParameterResponse.builder()
                .sessionId(request.getSessionId())
                .categoryCode((String) session.get("selectedCategory"))
                .stage("FOB")
                .parameters(parameters)
                .build();
    }

    @Override
    @SuppressWarnings("null")
    public CostEstimateResponse estimateCost(CostEstimateRequest request, String lang) {
        Map<String, Object> session = getSession(request.getSessionId());
        
        session.put("costParameterValues", request.getParameters());
        
        StringBuilder promptBuilder = new StringBuilder();
        promptBuilder.append(langInstruction(lang));
        promptBuilder.append("请根据以下信息计算产品成本并生成可生产该产品的供应商列表:\n\n");
        promptBuilder.append("品类: ").append(request.getCategoryCode()).append("\n");
        promptBuilder.append("参数:\n");
        request.getParameters().forEach((key, value) -> 
                promptBuilder.append("- ").append(key).append(": ").append(value).append("\n"));
        
        if (session.containsKey("imageRecognition")) {
            promptBuilder.append("\n图片识别信息:\n").append(session.get("imageRecognition")).append("\n");
        }
        
        promptBuilder.append("\n**核心要求 - 必须严格遵守**:\n");
        promptBuilder.append("1. **市场价格校准(最重要)**:\n");
        promptBuilder.append("   - 在计算任何成本之前,必须先查询阿里巴巴(1688.com)上相同或相似产品的实际市场价格\n");
        promptBuilder.append("   - 找到该产品的市场价格区间(最低价、常见价、最高价)\n");
        promptBuilder.append("   - 成本价应该是市场零售价的60%-75%区间(批发成本通常是零售价的这个比例)\n");
        promptBuilder.append("   - **如果阿里巴巴上的产品最低价是10元,那么成本价应该在6-8元左右,绝不能高于10元**\n");
        promptBuilder.append("2. **成本拆解原则**:\n");
        promptBuilder.append("   - 先确定合理的总成本(基于市场价反推),再拆解各项成本\n");
        promptBuilder.append("   - 材料成本: 总成本的40%-50%\n");
        promptBuilder.append("   - 加工成本: 总成本的30%-40%\n");
        promptBuilder.append("   - 损耗成本: 总成本的5%-10%\n");
        promptBuilder.append("   - 包装成本: 总成本的5%-10%\n");
        promptBuilder.append("   - 各项成本之和必须等于总成本\n");
        promptBuilder.append("3. **数据真实性**:\n");
        promptBuilder.append("   - 在alibabaReferenceNote字段中必须说明参考的阿里巴巴价格范围\n");
        promptBuilder.append("   - 例如: '参考阿里巴巴同类产品价格10-25元/双,按批发成本60%计算'\n");
        promptBuilder.append("4. **供应商价格一致性**:\n");
        promptBuilder.append("   - 所有供应商的estimatedCostPrice应该在总成本±10%的范围内\n");
        promptBuilder.append("   - 不同供应商的价格差异主要体现在FOB阶段的运费差异\n\n");
        
        promptBuilder.append("请返回JSON格式,包含:\n");
        promptBuilder.append("1. costBreakdown: {materialCost, processingCost, wasteCost, packagingCost, totalCost, currency, unit, alibabaReferenceNote(必填,说明参考的阿里巴巴价格)}\n");
        promptBuilder.append("2. suppliers: 数组,每个包含 {factoryName, city, industrialBelt, mainProducts, matchScore(0-100), matchReason, estimatedCostPrice, supplierCode}\n");
        promptBuilder.append("只返回JSON,不要其他文字");
        
        AIRequest zhipuRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(promptBuilder.toString())
                                .build()
                ))
                .temperature(0.1)  // 降低temperature以提高价格计算的准确性和一致性
                .build();
        
        AIResponse zhipuResponse = aiRetryHelper.callWithRetry(zhipuClient, zhipuRequest);
        
        if (zhipuResponse.getSuccess()) {
            try {
                // 清理AI返回的JSON内容,移除Markdown代码块标记
                String jsonContent = cleanAIJsonResponse(zhipuResponse.getContent());
                log.info("清理后的JSON内容长度: {}", jsonContent.length());
                
                JsonNode resultNode = objectMapper.readTree(jsonContent);
                
                JsonNode costNode = resultNode.get("costBreakdown");
                if (costNode == null) {
                    throw new RuntimeException("AI响应缺少costBreakdown字段");
                }
                CostEstimateResponse.CostBreakdown costBreakdown = CostEstimateResponse.CostBreakdown.builder()
                        .materialCost(safeBigDecimal(costNode, "materialCost", BigDecimal.ZERO))
                        .processingCost(safeBigDecimal(costNode, "processingCost", BigDecimal.ZERO))
                        .wasteCost(safeBigDecimal(costNode, "wasteCost", BigDecimal.ZERO))
                        .packagingCost(safeBigDecimal(costNode, "packagingCost", BigDecimal.ZERO))
                        .totalCost(safeBigDecimal(costNode, "totalCost", BigDecimal.ZERO))
                        .currency(safeText(costNode, "currency", "CNY"))
                        .unit(safeText(costNode, "unit", "个"))
                        .alibabaReferenceNote(safeText(costNode, "alibabaReferenceNote", "暂无参考价格"))
                        .platformPriceLow(safeBigDecimal(costNode, "platformPriceLow", BigDecimal.ZERO))
                        .platformPriceHigh(safeBigDecimal(costNode, "platformPriceHigh", BigDecimal.ZERO))
                        .build();
                
                // totalCost为0时自动计算
                if (costBreakdown.getTotalCost().compareTo(BigDecimal.ZERO) == 0) {
                    BigDecimal autoTotal = costBreakdown.getMaterialCost()
                            .add(costBreakdown.getProcessingCost())
                            .add(costBreakdown.getWasteCost())
                            .add(costBreakdown.getPackagingCost());
                    costBreakdown.setTotalCost(autoTotal);
                    log.info("totalCost为0,自动计算: {}", autoTotal);
                }
                
                List<CostEstimateResponse.SupplierMatch> suppliers = new ArrayList<>();
                JsonNode suppliersNode = resultNode.get("suppliers");
                if (suppliersNode != null && suppliersNode.isArray()) {
                    for (JsonNode supplierNode : suppliersNode) {
                        CostEstimateResponse.SupplierMatch supplier = CostEstimateResponse.SupplierMatch.builder()
                                .factoryName(safeText(supplierNode, "factoryName", "未知工厂"))
                                .city(safeText(supplierNode, "city", "未知城市"))
                                .industrialBelt(safeText(supplierNode, "industrialBelt", ""))
                                .mainProducts(safeText(supplierNode, "mainProducts", ""))
                                .matchScore(safeInt(supplierNode, "matchScore", 80))
                                .matchReason(safeText(supplierNode, "matchReason", "AI推荐"))
                                .estimatedCostPrice(safeBigDecimal(supplierNode, "estimatedCostPrice", costBreakdown.getTotalCost()))
                                .supplierCode(safeText(supplierNode, "supplierCode", "SUP_" + suppliers.size()))
                                .build();
                        suppliers.add(supplier);
                    }
                }
                
                session.put("costBreakdown", costBreakdown);
                session.put("suppliers", suppliers);
                
                // 价格合理性校验和日志
                log.info("=== 成本预估结果校验 ===");
                log.info("总成本: {} {}/{}", costBreakdown.getTotalCost(), costBreakdown.getCurrency(), costBreakdown.getUnit());
                log.info("阿里巴巴参考价格: {}", costBreakdown.getAlibabaReferenceNote());
                log.info("供应商数量: {}", suppliers.size());
                suppliers.forEach(s -> {
                    log.info("供应商[{}] 预估成本价: {} CNY", s.getFactoryName(), s.getEstimatedCostPrice());
                    // 检查供应商价格是否与总成本偏差过大
                    BigDecimal deviation = s.getEstimatedCostPrice().subtract(costBreakdown.getTotalCost())
                            .abs().divide(costBreakdown.getTotalCost(), 4, RoundingMode.HALF_UP);
                    if (deviation.compareTo(new BigDecimal("0.2")) > 0) {
                        log.warn("供应商[{}]价格偏差超过20%: {}%", s.getFactoryName(), deviation.multiply(new BigDecimal("100")));
                    }
                });
                
                return CostEstimateResponse.builder()
                        .sessionId(request.getSessionId())
                        .costBreakdown(costBreakdown)
                        .suggestedSuppliers(suppliers)
                        .build();
                        
            } catch (Exception e) {
                log.error("Failed to parse cost estimate response", e);
                throw new RuntimeException("Failed to estimate cost", e);
            }
        }
        
        throw new RuntimeException("AI request failed");
    }

    @Override
    @SuppressWarnings("null")
    public FOBEstimateResponse estimateFOB(FOBEstimateRequest request, String lang) {
        Map<String, Object> session = getSession(request.getSessionId());
        
        CostEstimateResponse.CostBreakdown costBreakdown = 
                (CostEstimateResponse.CostBreakdown) session.get("costBreakdown");
        
        if (costBreakdown == null) {
            throw new RuntimeException("会话中缺少成本数据,请先完成成本预估步骤");
        }
        
        @SuppressWarnings("unchecked")
        List<CostEstimateResponse.SupplierMatch> suppliers = 
                (List<CostEstimateResponse.SupplierMatch>) session.get("suppliers");
        
        if (suppliers == null || suppliers.isEmpty()) {
            throw new RuntimeException("会话中缺少供应商数据,请先完成成本预估步骤");
        }
        
        Optional<CostEstimateResponse.SupplierMatch> selectedSupplier = suppliers.stream()
                .filter(s -> s.getSupplierCode().equals(request.getSupplierCode()))
                .findFirst();
        
        if (!selectedSupplier.isPresent()) {
            throw new RuntimeException("Supplier not found: " + request.getSupplierCode());
        }
        
        // 获取第4步工厂报价数据,FOB基于工厂报价而非原始成本
        @SuppressWarnings("unchecked")
        List<FactoryQuoteResponse.SupplierQuote> supplierQuotes = 
                (List<FactoryQuoteResponse.SupplierQuote>) session.get("supplierQuotes");
        FactoryQuoteResponse.QuoteBreakdown quoteBreakdown = 
                (FactoryQuoteResponse.QuoteBreakdown) session.get("quoteBreakdown");
        
        // 查找所选供应商的工厂报价(取中间价)
        BigDecimal factoryQuotePrice = costBreakdown.getTotalCost(); // 兜底用成本价
        String quoteCurrency = costBreakdown.getCurrency();
        if (supplierQuotes != null) {
            Optional<FactoryQuoteResponse.SupplierQuote> matchedQuote = supplierQuotes.stream()
                    .filter(q -> q.getSupplierCode().equals(request.getSupplierCode()))
                    .findFirst();
            if (matchedQuote.isPresent()) {
                FactoryQuoteResponse.SupplierQuote sq = matchedQuote.get();
                factoryQuotePrice = sq.getQuoteLow().add(sq.getQuoteHigh())
                        .divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP);
                log.info("使用供应商工厂报价中间价: {} (区间: {} ~ {})", factoryQuotePrice, sq.getQuoteLow(), sq.getQuoteHigh());
            } else if (quoteBreakdown != null) {
                factoryQuotePrice = quoteBreakdown.getFactoryQuoteLow().add(quoteBreakdown.getFactoryQuoteHigh())
                        .divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP);
                quoteCurrency = quoteBreakdown.getCurrency();
                log.info("未找到供应商报价,使用整体工厂报价中间价: {}", factoryQuotePrice);
            }
        }
        
        // 确保fobParameters不为null
        Map<String, String> fobParams = request.getFobParameters();
        if (fobParams == null) {
            fobParams = new java.util.HashMap<>();
        }
        
        // 从FOB参数中提取发货地信息
        String shipFromCity = fobParams.getOrDefault("ship_from_city", 
                fobParams.getOrDefault("supplier_location", 
                selectedSupplier.get().getCity()));
        
        String toPort = fobParams.getOrDefault("departure_port", "深圳港");
        
        log.info("FOB计算: 发货地={}, 起运港={}, 工厂报价={}", shipFromCity, toPort, factoryQuotePrice);
        
        StringBuilder promptBuilder = new StringBuilder();
        promptBuilder.append(langInstruction(lang));
        promptBuilder.append("请计算FOB价格:\n\n");
        promptBuilder.append("工厂报价单价: ").append(factoryQuotePrice).append(" ").append(quoteCurrency).append("\n");
        promptBuilder.append("发货地/供应商城市: ").append(shipFromCity).append("\n");
        promptBuilder.append("起运港: ").append(toPort).append("\n");
        promptBuilder.append("FOB参数:\n");
        fobParams.forEach((key, value) -> 
                promptBuilder.append("- ").append(key).append(": ").append(value).append("\n"));
        
        promptBuilder.append("\n**重要说明**:\n");
        promptBuilder.append("- FOB价格 = 工厂报价单价 + 国内运费 + 港口费用 + 报关费用\n");
        promptBuilder.append("- **出口退税不纳入FOB计算**,仅作为文字说明提示客户\n");
        promptBuilder.append("- FOB价格必须大于工厂报价单价\n\n");
        
        promptBuilder.append("请返回JSON格式,包含:\n");
        promptBuilder.append("1. fobBreakdown: {costPrice(即工厂报价单价,必须等于").append(factoryQuotePrice).append("), domesticFreight(从").append(shipFromCity).append("到").append(toPort).append("的国内运费), portCharges, customsClearance, exportTaxRebateNote(退税说明文字,不计入价格), fobPrice, currency, unit, fromCity, toPort}\n");
        promptBuilder.append("2. supplierFOBPrices: 所有供应商的FOB报价数组 {supplierCode, factoryName, city, fobPrice, domesticFreight, estimatedDeliveryDays}\n");
        promptBuilder.append("只返回JSON,不要其他文字");
        
        AIRequest zhipuRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(promptBuilder.toString())
                                .build()
                ))
                .temperature(0.2)
                .build();
        
        AIResponse zhipuResponse = aiRetryHelper.callWithRetry(zhipuClient, zhipuRequest);
        
        if (zhipuResponse.getSuccess()) {
            try {
                // 清理AI返回的JSON内容,移除Markdown代码块标记
                String jsonContent = cleanAIJsonResponse(zhipuResponse.getContent());
                log.info("FOB预估-清理后的JSON内容长度: {}", jsonContent.length());
                
                JsonNode resultNode = objectMapper.readTree(jsonContent);
                
                JsonNode fobNode = resultNode.get("fobBreakdown");
                if (fobNode == null) {
                    throw new RuntimeException("AI响应缺少fobBreakdown字段");
                }
                FOBEstimateResponse.FOBBreakdown fobBreakdown = FOBEstimateResponse.FOBBreakdown.builder()
                        .costPrice(safeBigDecimal(fobNode, "costPrice", BigDecimal.ZERO))
                        .domesticFreight(safeBigDecimal(fobNode, "domesticFreight", BigDecimal.ZERO))
                        .portCharges(safeBigDecimal(fobNode, "portCharges", BigDecimal.ZERO))
                        .customsClearance(safeBigDecimal(fobNode, "customsClearance", BigDecimal.ZERO))
                        .exportTaxRebate(BigDecimal.ZERO)  // 退税不计入金额,设为0
                        .fobPrice(safeBigDecimal(fobNode, "fobPrice", BigDecimal.ZERO))
                        .currency(safeText(fobNode, "currency", "CNY"))
                        .unit(safeText(fobNode, "unit", "个"))
                        .fromCity(safeText(fobNode, "fromCity", shipFromCity))
                        .toPort(safeText(fobNode, "toPort", toPort))
                        .build();
                
                // 强制costPrice使用工厂报价(第4步),而非AI可能返回的成本价(第3步)
                fobBreakdown.setCostPrice(factoryQuotePrice);
                
                // fobPrice为0时自动计算
                if (fobBreakdown.getFobPrice().compareTo(BigDecimal.ZERO) == 0) {
                    BigDecimal autoFob = fobBreakdown.getCostPrice()
                            .add(fobBreakdown.getDomesticFreight())
                            .add(fobBreakdown.getPortCharges())
                            .add(fobBreakdown.getCustomsClearance());
                    fobBreakdown.setFobPrice(autoFob);
                    log.info("fobPrice为0,自动计算: {}", autoFob);
                }
                
                // 确保fobPrice不低于工厂报价
                if (fobBreakdown.getFobPrice().compareTo(factoryQuotePrice) < 0) {
                    BigDecimal correctedFob = factoryQuotePrice
                            .add(fobBreakdown.getDomesticFreight())
                            .add(fobBreakdown.getPortCharges())
                            .add(fobBreakdown.getCustomsClearance());
                    log.info("FOB价格{}低于工厂报价{},重新计算: {}", fobBreakdown.getFobPrice(), factoryQuotePrice, correctedFob);
                    fobBreakdown.setFobPrice(correctedFob);
                }
                
                List<FOBEstimateResponse.SupplierFOB> supplierFOBs = new ArrayList<>();
                JsonNode supplierFOBsNode = resultNode.get("supplierFOBPrices");
                if (supplierFOBsNode != null && supplierFOBsNode.isArray()) {
                    for (JsonNode supplierFOBNode : supplierFOBsNode) {
                        FOBEstimateResponse.SupplierFOB supplierFOB = FOBEstimateResponse.SupplierFOB.builder()
                                .supplierCode(safeText(supplierFOBNode, "supplierCode", "SUP_" + supplierFOBs.size()))
                                .factoryName(safeText(supplierFOBNode, "factoryName", "未知工厂"))
                                .city(safeText(supplierFOBNode, "city", "未知城市"))
                                .fobPrice(safeBigDecimal(supplierFOBNode, "fobPrice", fobBreakdown.getFobPrice()))
                                .domesticFreight(safeBigDecimal(supplierFOBNode, "domesticFreight", fobBreakdown.getDomesticFreight()))
                                .estimatedDeliveryDays(safeText(supplierFOBNode, "estimatedDeliveryDays", "7-15天"))
                                .build();
                        supplierFOBs.add(supplierFOB);
                    }
                }
                
                return FOBEstimateResponse.builder()
                        .sessionId(request.getSessionId())
                        .supplierCode(request.getSupplierCode())
                        .fobBreakdown(fobBreakdown)
                        .supplierFOBPrices(supplierFOBs)
                        .build();
                        
            } catch (Exception e) {
                log.error("Failed to parse FOB estimate response", e);
                throw new RuntimeException("Failed to estimate FOB", e);
            }
        }
        
        throw new RuntimeException("AI request failed");
    }
    
    @Override
    @SuppressWarnings("unchecked")
    public FactoryQuoteResponse estimateFactoryQuote(String sessionId, String categoryCode, String lang) {
        log.info("=== 工厂预估报价开始 === sessionId={}, categoryCode={}", sessionId, categoryCode);
        
        Map<String, Object> session = getSession(sessionId);
        
        CostEstimateResponse.CostBreakdown costBreakdown = 
                (CostEstimateResponse.CostBreakdown) session.get("costBreakdown");
        if (costBreakdown == null) {
            throw new RuntimeException("请先完成成本预估");
        }
        
        List<CostEstimateResponse.SupplierMatch> suppliers = 
                (List<CostEstimateResponse.SupplierMatch>) session.get("suppliers");
        
        String productName = (String) session.get("productName");
        String categoryName = (String) session.getOrDefault("selectedCategoryName", categoryCode);
        
        BigDecimal totalCost = costBreakdown.getTotalCost();
        BigDecimal platformPriceLow = costBreakdown.getPlatformPriceLow();
        BigDecimal platformPriceHigh = costBreakdown.getPlatformPriceHigh();
        
        // 如果平台价格为空，尝试从alibabaReferenceNote中提取
        if ((platformPriceLow == null || platformPriceLow.compareTo(BigDecimal.ZERO) == 0) 
                && costBreakdown.getAlibabaReferenceNote() != null) {
            extractPlatformPriceFromNote(costBreakdown);
            platformPriceLow = costBreakdown.getPlatformPriceLow();
            platformPriceHigh = costBreakdown.getPlatformPriceHigh();
        }
        
        log.info("成本价: {} {}/{}, 品类: {}", totalCost, costBreakdown.getCurrency(), costBreakdown.getUnit(), categoryName);
        log.info("同平台参考价格: {} - {}", platformPriceLow, platformPriceHigh);
        
        // 使用豆包Text模型分析行业利润率
        String prompt = langInstruction(lang) + String.format(
                "产品名称: %s\n" +
                "品类: %s\n" +
                "生产成本: %s %s/%s\n\n" +
                "请作为一个专业的外贸行业分析师,分析该品类产品在中国工厂的行业利润率水平。\n\n" +
                "要求:\n" +
                "1. 参考1688等B2B平台同类产品的实际售价与成本关系\n" +
                "2. 给出该品类工厂的合理利润率区间(百分比)\n" +
                "3. 利润率区间应该反映行业真实水平,一般在8%%-35%%之间\n" +
                "4. 低利润率代表薄利多销/竞争激烈的品类,高利润率代表技术壁垒/品牌溢价的品类\n" +
                "5. 提供简短的行业参考说明\n\n" +
                "返回JSON格式:\n" +
                "{\n" +
                "  \"industryProfitMarginLow\": 数字(百分比,如10表示10%%),\n" +
                "  \"industryProfitMarginHigh\": 数字(百分比,如25表示25%%),\n" +
                "  \"industryReferenceNote\": \"行业参考说明(50字以内)\"\n" +
                "}\n\n" +
                "只返回JSON,不要任何其他文字。",
                productName, categoryName,
                totalCost.toPlainString(), costBreakdown.getCurrency(), costBreakdown.getUnit()
        );
        
        AIRequest textRequest = AIRequest.builder()
                .messages(Arrays.asList(
                        AIRequest.Message.builder()
                                .role("user")
                                .content(prompt)
                                .build()
                ))
                .temperature(0.2)
                .build();
        
        log.info("开始调用豆包AI分析行业利润率...");
        long startTime = System.currentTimeMillis();
        
        AIResponse textResponse;
        try {
            textResponse = aiRetryHelper.callWithRetry(textClient, textRequest);
            long duration = System.currentTimeMillis() - startTime;
            log.info("豆包AI调用完成,耗时: {}ms, 成功: {}", duration, textResponse.getSuccess());
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("豆包AI调用异常,耗时: {}ms", duration, e);
            throw new RuntimeException("AI服务调用失败: " + e.getMessage(), e);
        }
        
        BigDecimal profitMarginLow;
        BigDecimal profitMarginHigh;
        String industryReferenceNote;
        
        if (textResponse.getSuccess()) {
            try {
                String jsonContent = cleanAIJsonResponse(textResponse.getContent());
                JsonNode resultNode = objectMapper.readTree(jsonContent);
                
                profitMarginLow = safeBigDecimal(resultNode, "industryProfitMarginLow", new BigDecimal("10"));
                profitMarginHigh = safeBigDecimal(resultNode, "industryProfitMarginHigh", new BigDecimal("25"));
                industryReferenceNote = safeText(resultNode, "industryReferenceNote", "参考同平台同类产品行业利润率");
                
                log.info("行业利润率区间: {}% - {}%, 说明: {}", profitMarginLow, profitMarginHigh, industryReferenceNote);
            } catch (Exception e) {
                log.error("行业利润率解析失败,使用默认值", e);
                profitMarginLow = new BigDecimal("10");
                profitMarginHigh = new BigDecimal("25");
                industryReferenceNote = "参考同平台同类产品行业利润率(默认值)";
            }
        } else {
            log.warn("AI未能成功分析利润率,使用默认值");
            profitMarginLow = new BigDecimal("10");
            profitMarginHigh = new BigDecimal("25");
            industryReferenceNote = "参考同平台同类产品行业利润率(默认值)";
        }
        
        // 计算工厂报价区间: 成本 × (1 + 利润率%)
        BigDecimal factoryQuoteLow = totalCost.multiply(
                BigDecimal.ONE.add(profitMarginLow.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP))
        ).setScale(2, RoundingMode.HALF_UP);
        
        BigDecimal factoryQuoteHigh = totalCost.multiply(
                BigDecimal.ONE.add(profitMarginHigh.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP))
        ).setScale(2, RoundingMode.HALF_UP);
        
        // 关键约束: 工厂报价不能低于同平台参考最低价
        if (platformPriceLow != null && platformPriceLow.compareTo(BigDecimal.ZERO) > 0) {
            if (factoryQuoteLow.compareTo(platformPriceLow) < 0) {
                log.info("工厂报价下限 {} 低于同平台最低价 {}, 上调至同平台最低价", factoryQuoteLow, platformPriceLow);
                factoryQuoteLow = platformPriceLow;
            }
            if (factoryQuoteHigh.compareTo(platformPriceLow) < 0) {
                log.info("工厂报价上限 {} 低于同平台最低价 {}, 上调至同平台最低价", factoryQuoteHigh, platformPriceLow);
                factoryQuoteHigh = platformPriceLow;
            }
        }
        
        log.info("工厂报价区间: {} - {} {}/{}", factoryQuoteLow, factoryQuoteHigh, costBreakdown.getCurrency(), costBreakdown.getUnit());
        
        FactoryQuoteResponse.QuoteBreakdown quoteBreakdown = FactoryQuoteResponse.QuoteBreakdown.builder()
                .costPrice(totalCost)
                .industryProfitMarginLow(profitMarginLow)
                .industryProfitMarginHigh(profitMarginHigh)
                .factoryQuoteLow(factoryQuoteLow)
                .factoryQuoteHigh(factoryQuoteHigh)
                .currency(costBreakdown.getCurrency())
                .unit(costBreakdown.getUnit())
                .industryReferenceNote(industryReferenceNote)
                .build();
        
        // 为每个供应商生成报价区间
        List<FactoryQuoteResponse.SupplierQuote> supplierQuotes = new ArrayList<>();
        if (suppliers != null) {
            for (CostEstimateResponse.SupplierMatch supplier : suppliers) {
                BigDecimal supplierCost = supplier.getEstimatedCostPrice();
                BigDecimal sQuoteLow = supplierCost.multiply(
                        BigDecimal.ONE.add(profitMarginLow.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP))
                ).setScale(2, RoundingMode.HALF_UP);
                BigDecimal sQuoteHigh = supplierCost.multiply(
                        BigDecimal.ONE.add(profitMarginHigh.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP))
                ).setScale(2, RoundingMode.HALF_UP);
                
                // 供应商报价同样不能低于同平台最低价
                if (platformPriceLow != null && platformPriceLow.compareTo(BigDecimal.ZERO) > 0) {
                    if (sQuoteLow.compareTo(platformPriceLow) < 0) {
                        sQuoteLow = platformPriceLow;
                    }
                    if (sQuoteHigh.compareTo(platformPriceLow) < 0) {
                        sQuoteHigh = platformPriceLow;
                    }
                }
                
                supplierQuotes.add(FactoryQuoteResponse.SupplierQuote.builder()
                        .supplierCode(supplier.getSupplierCode())
                        .factoryName(supplier.getFactoryName())
                        .city(supplier.getCity())
                        .industrialBelt(supplier.getIndustrialBelt())
                        .mainProducts(supplier.getMainProducts())
                        .matchScore(supplier.getMatchScore())
                        .matchReason(supplier.getMatchReason())
                        .estimatedCostPrice(supplier.getEstimatedCostPrice())
                        .quoteLow(sQuoteLow)
                        .quoteHigh(sQuoteHigh)
                        .quoteReason(supplier.getMatchReason())
                        .build());
            }
        }
        
        // 保存到会话
        session.put("quoteBreakdown", quoteBreakdown);
        session.put("supplierQuotes", supplierQuotes);
        
        log.info("=== 工厂预估报价完成 === 报价区间: {} - {}, 供应商数: {}", 
                factoryQuoteLow, factoryQuoteHigh, supplierQuotes.size());
        
        return FactoryQuoteResponse.builder()
                .sessionId(sessionId)
                .quoteBreakdown(quoteBreakdown)
                .supplierQuotes(supplierQuotes)
                .build();
    }

    /**
     * 从alibabaReferenceNote文本中提取同平台参考价格区间
     * 匹配类似: "价格10-25元" "价格区间8.5~15元" "售价3.5-12.8元/个" 等模式
     */
    private void extractPlatformPriceFromNote(CostEstimateResponse.CostBreakdown breakdown) {
        String note = breakdown.getAlibabaReferenceNote();
        if (note == null || note.isEmpty()) return;
        
        // 匹配价格区间: 数字-数字 或 数字~数字 或 数字～数字
        Pattern pattern = Pattern.compile("(\\d+\\.?\\d*)\\s*[-~～至到]\\s*(\\d+\\.?\\d*)\\s*元");
        Matcher matcher = pattern.matcher(note);
        if (matcher.find()) {
            try {
                BigDecimal low = new BigDecimal(matcher.group(1));
                BigDecimal high = new BigDecimal(matcher.group(2));
                if (low.compareTo(high) > 0) {
                    BigDecimal temp = low; low = high; high = temp;
                }
                breakdown.setPlatformPriceLow(low);
                breakdown.setPlatformPriceHigh(high);
                log.info("从参考说明中提取同平台价格: {} ~ {} 元", low, high);
            } catch (NumberFormatException e) {
                log.warn("解析参考价格数字失败: {}", e.getMessage());
            }
        }
    }

    /**
     * 清理AI返回的JSON响应,移除Markdown代码块标记
     */
    private String cleanAIJsonResponse(String aiResponse) {
        if (aiResponse == null || aiResponse.trim().isEmpty()) {
            return aiResponse;
        }
        
        String cleaned = aiResponse.trim();
        
        // 移除开头的Markdown代码块标记: ```json 或 ```
        if (cleaned.startsWith("```json")) {
            cleaned = cleaned.substring(7).trim();
        } else if (cleaned.startsWith("```")) {
            cleaned = cleaned.substring(3).trim();
        }
        
        // 移除结尾的Markdown代码块标记: ```
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
        }
        
        log.debug("清理前长度: {}, 清理后长度: {}", aiResponse.length(), cleaned.length());
        
        return cleaned;
    }
}
