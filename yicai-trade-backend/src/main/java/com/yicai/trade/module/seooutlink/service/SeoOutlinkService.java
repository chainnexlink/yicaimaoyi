package com.yicai.trade.module.seooutlink.service;

import com.yicai.trade.common.ai.client.AIRequest;
import com.yicai.trade.common.ai.client.AIResponse;
import com.yicai.trade.common.ai.client.DoubaoTextClient;
import com.yicai.trade.common.exception.BusinessException;
import com.yicai.trade.common.exception.ErrorCode;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.product.entity.Product;
import com.yicai.trade.module.product.repository.ProductRepository;
import com.yicai.trade.module.seooutlink.dto.*;
import com.yicai.trade.module.seooutlink.entity.SeoBlogBinding;
import com.yicai.trade.module.seooutlink.entity.SeoBlogPublishLog;
import com.yicai.trade.module.seooutlink.publisher.BlogPublishResult;
import com.yicai.trade.module.seooutlink.publisher.BlogPublisher;
import com.yicai.trade.module.seooutlink.repository.SeoBlogBindingRepository;
import com.yicai.trade.module.seooutlink.repository.SeoBlogPublishLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class SeoOutlinkService {

    private final SeoBlogBindingRepository bindingRepository;
    private final SeoBlogPublishLogRepository logRepository;
    private final ProductRepository productRepository;
    private final DoubaoTextClient doubaoTextClient;
    private final Map<String, BlogPublisher> publisherMap;

    /** 全局外链功能开关（后台可控） */
    private volatile boolean outlinkEnabled = true;

    /** 全局每日最大发文限制 */
    private volatile int globalDailyLimit = 3;

    /** 豆包 AI SEO 外链提示词模板 */
    private static final String SEO_OUTLINK_PROMPT = """
            你是专业的跨境电商Google SEO写手，只输出地道、自然、原创的英文博客文章。

            产品名称：%s
            目标关键词：%s
            产品链接：%s

            要求：
            1. 语言：美式纯正英文
            2. 字数：500–800词
            3. 原创、自然、有价值，不生硬推广
            4. 文中自然插入1条外链指向产品URL
            5. 锚文本使用目标关键词
            6. 只返回文章正文，不要任何多余内容
            """;

    public SeoOutlinkService(
            SeoBlogBindingRepository bindingRepository,
            SeoBlogPublishLogRepository logRepository,
            ProductRepository productRepository,
            DoubaoTextClient doubaoTextClient,
            List<BlogPublisher> publishers) {
        this.bindingRepository = bindingRepository;
        this.logRepository = logRepository;
        this.productRepository = productRepository;
        this.doubaoTextClient = doubaoTextClient;
        this.publisherMap = publishers.stream()
                .collect(Collectors.toMap(BlogPublisher::getPlatform, p -> p));
    }

    // ==================== 供应商绑定管理 ====================

    public List<SeoBlogBindingResponse> getSupplierBindings(Long supplierId) {
        return bindingRepository.findBySupplierId(supplierId).stream()
                .map(this::toBindingResponse).collect(Collectors.toList());
    }

    @Transactional
    public SeoBlogBindingResponse createOrUpdateBinding(Long supplierId, SeoBlogBindingRequest request) {
        String platform = request.getPlatform().toUpperCase();
        SeoBlogBinding binding = bindingRepository.findBySupplierIdAndPlatform(supplierId, platform)
                .orElse(SeoBlogBinding.builder()
                        .supplierId(supplierId)
                        .platform(platform)
                        .build());

        binding.setBlogUrl(request.getBlogUrl());
        binding.setUsername(request.getUsername());
        if (request.getAppPassword() != null && !request.getAppPassword().isBlank()) {
            binding.setAppPassword(request.getAppPassword());
        }
        binding.setAutoPublish(request.getAutoPublish() != null ? request.getAutoPublish() : true);
        binding.setDailyLimit(Math.min(Math.max(request.getDailyLimit() != null ? request.getDailyLimit() : 1, 1), globalDailyLimit));
        binding.setStatus("ACTIVE");

        return toBindingResponse(bindingRepository.save(binding));
    }

    @Transactional
    public void deleteBinding(Long supplierId, Long bindingId) {
        SeoBlogBinding binding = bindingRepository.findById(bindingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "绑定记录不存在"));
        if (!binding.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无权操作此绑定");
        }
        bindingRepository.delete(binding);
    }

    @Transactional
    public Map<String, Object> testBinding(Long supplierId, Long bindingId) {
        SeoBlogBinding binding = bindingRepository.findById(bindingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "绑定记录不存在"));
        if (!binding.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN, "无权操作此绑定");
        }

        BlogPublisher publisher = publisherMap.get(binding.getPlatform());
        if (publisher == null) {
            binding.setLastTestAt(LocalDateTime.now());
            binding.setLastTestOk(false);
            bindingRepository.save(binding);
            return Map.of("success", false, "message", "不支持的平台: " + binding.getPlatform());
        }

        BlogPublishResult result = publisher.testConnection(binding);
        binding.setLastTestAt(LocalDateTime.now());
        binding.setLastTestOk(result.success());
        binding.setStatus(result.success() ? "ACTIVE" : "ERROR");
        bindingRepository.save(binding);

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("success", result.success());
        resp.put("message", result.success() ? "连接成功" : result.errorMessage());
        return resp;
    }

    @Transactional
    public void toggleAutoPublish(Long supplierId, Long bindingId, boolean enabled) {
        SeoBlogBinding binding = bindingRepository.findById(bindingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        if (!binding.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }
        binding.setAutoPublish(enabled);
        bindingRepository.save(binding);
    }

    // ==================== 文章生成与发布 ====================

    /**
     * 手动触发发布一篇测试文章（供应商端调用）
     */
    @Transactional
    public SeoBlogPublishLogResponse publishTestArticle(Long supplierId, Long bindingId) {
        SeoBlogBinding binding = bindingRepository.findById(bindingId)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "绑定不存在"));
        if (!binding.getSupplierId().equals(supplierId)) {
            throw new BusinessException(ErrorCode.FORBIDDEN);
        }

        // 随机选一个产品
        List<Product> products = productRepository.findByAuditStatus("APPROVED",
                PageRequest.of(0, 20, Sort.by(Sort.Direction.DESC, "createdAt"))).getContent();

        // 过滤当前供应商的产品
        List<Product> supplierProducts = products.stream()
                .filter(p -> supplierId.equals(p.getSupplierId()))
                .collect(Collectors.toList());

        if (supplierProducts.isEmpty()) {
            // 如果该供应商没有已审批产品，用通用产品作为示例
            if (!products.isEmpty()) {
                supplierProducts = List.of(products.get(0));
            }
        }

        Product product = supplierProducts.isEmpty() ? null : supplierProducts.get(new Random().nextInt(supplierProducts.size()));

        String productName = product != null ? product.getName() : "High Quality Industrial Products";
        String keyword = product != null ? product.getCategory() : "industrial supplies";
        String productUrl = product != null
                ? "https://www.yicai-trade.com/product/" + product.getProductNo()
                : "https://www.yicai-trade.com";

        return generateAndPublish(binding, product, productName, keyword, productUrl);
    }

    /**
     * 定时任务：每天凌晨3点执行外链自动发布
     */
    @Scheduled(cron = "${seo.outlink.cron:0 0 3 * * ?}")
    public void scheduledOutlinkPublish() {
        if (!outlinkEnabled) {
            log.info("[SEO外链] 全局功能已禁用，跳过");
            return;
        }
        if (!doubaoTextClient.isEnabled()) {
            log.warn("[SEO外链] 豆包AI未启用，跳过");
            return;
        }

        List<SeoBlogBinding> activeBindings = bindingRepository.findByAutoPublishTrueAndStatus("ACTIVE");
        if (activeBindings.isEmpty()) {
            log.info("[SEO外链] 无活跃绑定，跳过");
            return;
        }

        log.info("[SEO外链] 开始定时发布，活跃绑定数: {}", activeBindings.size());
        LocalDateTime todayStart = LocalDate.now().atTime(LocalTime.MIN);

        for (SeoBlogBinding binding : activeBindings) {
            try {
                // 检查今日已发数量
                long todayPublished = logRepository.countByBindingIdAndStatusAndCreatedAtAfter(
                        binding.getId(), "PUBLISHED", todayStart);
                int limit = Math.min(binding.getDailyLimit(), globalDailyLimit);

                if (todayPublished >= limit) {
                    log.debug("[SEO外链] binding={} 今日已达上限 {}/{}", binding.getId(), todayPublished, limit);
                    continue;
                }

                int toPublish = (int) (limit - todayPublished);

                // 获取供应商的产品
                List<Product> products = productRepository.findByAuditStatus("APPROVED",
                                PageRequest.of(0, 50, Sort.by(Sort.Direction.DESC, "createdAt"))).getContent()
                        .stream()
                        .filter(p -> binding.getSupplierId().equals(p.getSupplierId()))
                        .collect(Collectors.toList());

                if (products.isEmpty()) {
                    log.info("[SEO外链] binding={} supplierId={} 无已审批产品，跳过", binding.getId(), binding.getSupplierId());
                    continue;
                }

                Collections.shuffle(products);
                for (int i = 0; i < toPublish && i < products.size(); i++) {
                    Product product = products.get(i);
                    String productUrl = "https://www.yicai-trade.com/product/" + product.getProductNo();
                    String keyword = product.getCategory() != null ? product.getCategory() : product.getName();

                    try {
                        generateAndPublish(binding, product, product.getName(), keyword, productUrl);
                        log.info("[SEO外链] 发布成功: binding={} product={}", binding.getId(), product.getProductNo());
                    } catch (Exception e) {
                        log.error("[SEO外链] 发布失败: binding={} product={}", binding.getId(), product.getProductNo(), e);
                    }

                    // 每篇之间间隔一小段时间（避免API限流）
                    Thread.sleep(2000);
                }

            } catch (Exception e) {
                log.error("[SEO外链] 处理绑定异常: bindingId={}", binding.getId(), e);
            }
        }

        log.info("[SEO外链] 定时发布完成");
    }

    /**
     * 核心逻辑：AI生成文章 + 调用博客API发布
     */
    private SeoBlogPublishLogResponse generateAndPublish(SeoBlogBinding binding, Product product,
                                                          String productName, String keyword, String productUrl) {
        // 1. 创建日志记录（PENDING）
        SeoBlogPublishLog publishLog = SeoBlogPublishLog.builder()
                .bindingId(binding.getId())
                .supplierId(binding.getSupplierId())
                .platform(binding.getPlatform())
                .productId(product != null ? product.getId() : null)
                .productName(productName)
                .keyword(keyword)
                .productUrl(productUrl)
                .status("PENDING")
                .build();
        logRepository.save(publishLog);

        try {
            // 2. 调用豆包AI生成文章
            String prompt = String.format(SEO_OUTLINK_PROMPT, productName, keyword, productUrl);
            AIRequest aiRequest = AIRequest.builder()
                    .messages(List.of(
                            AIRequest.Message.builder().role("user").content(prompt).build()
                    ))
                    .temperature(0.85)
                    .maxTokens(3000)
                    .build();

            AIResponse aiResponse = doubaoTextClient.call(aiRequest);
            if (!Boolean.TRUE.equals(aiResponse.getSuccess()) || aiResponse.getContent() == null || aiResponse.getContent().isBlank()) {
                String err = "AI生成失败: " + (aiResponse.getErrorMessage() != null ? aiResponse.getErrorMessage() : "空响应");
                publishLog.setStatus("FAILED");
                publishLog.setErrorMessage(err);
                logRepository.save(publishLog);
                return toLogResponse(publishLog);
            }

            String articleBody = aiResponse.getContent().trim();

            // 从内容中提取标题（取第一行或生成标题）
            String articleTitle = extractTitle(articleBody, productName, keyword);
            String htmlContent = convertToHtml(articleBody);

            publishLog.setArticleTitle(articleTitle);
            publishLog.setArticleContent(articleBody);

            // 3. 调用博客API发布
            BlogPublisher publisher = publisherMap.get(binding.getPlatform());
            if (publisher == null) {
                publishLog.setStatus("FAILED");
                publishLog.setErrorMessage("不支持的平台: " + binding.getPlatform());
                logRepository.save(publishLog);
                return toLogResponse(publishLog);
            }

            BlogPublishResult result = publisher.publish(binding, articleTitle, htmlContent);

            if (result.success()) {
                publishLog.setStatus("PUBLISHED");
                publishLog.setPublishUrl(result.publishUrl());
                publishLog.setPublishedAt(LocalDateTime.now());
            } else {
                publishLog.setStatus("FAILED");
                publishLog.setErrorMessage(result.errorMessage());
            }

        } catch (Exception e) {
            publishLog.setStatus("FAILED");
            publishLog.setErrorMessage(e.getMessage());
            log.error("[SEO外链] 生成发布异常", e);
        }

        logRepository.save(publishLog);
        return toLogResponse(publishLog);
    }

    /**
     * 从AI生成内容中提取标题
     */
    private String extractTitle(String content, String productName, String keyword) {
        String[] lines = content.split("\n");
        for (String line : lines) {
            String trimmed = line.trim().replaceAll("^#+\\s*", "").replaceAll("\\*+", "");
            if (trimmed.length() >= 10 && trimmed.length() <= 200) {
                return trimmed;
            }
        }
        return "The Ultimate Guide to " + keyword + " - " + productName;
    }

    /**
     * 将纯文本/Markdown转为简单HTML
     */
    private String convertToHtml(String content) {
        StringBuilder html = new StringBuilder();
        for (String line : content.split("\n")) {
            String trimmed = line.trim();
            if (trimmed.isEmpty()) continue;
            if (trimmed.startsWith("# ")) {
                html.append("<h1>").append(trimmed.substring(2)).append("</h1>\n");
            } else if (trimmed.startsWith("## ")) {
                html.append("<h2>").append(trimmed.substring(3)).append("</h2>\n");
            } else if (trimmed.startsWith("### ")) {
                html.append("<h3>").append(trimmed.substring(4)).append("</h3>\n");
            } else {
                html.append("<p>").append(trimmed).append("</p>\n");
            }
        }
        return html.toString();
    }

    // ==================== 查询日志 ====================

    public PageResult<SeoBlogPublishLogResponse> getSupplierLogs(Long supplierId, String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<SeoBlogPublishLog> p;
        if (status != null && !status.isBlank()) {
            p = logRepository.findBySupplierIdAndStatus(supplierId, status, pr);
        } else {
            p = logRepository.findBySupplierId(supplierId, pr);
        }
        return PageResult.of(
                p.getContent().stream().map(this::toLogResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    // ==================== 后台管理 ====================

    public List<SeoBlogBindingResponse> getAllBindings() {
        return bindingRepository.findAll().stream()
                .map(this::toBindingResponse).collect(Collectors.toList());
    }

    public PageResult<SeoBlogPublishLogResponse> getAllLogs(String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<SeoBlogPublishLog> p;
        if (status != null && !status.isBlank()) {
            p = logRepository.findByStatus(status, pr);
        } else {
            p = logRepository.findAll(pr);
        }
        return PageResult.of(
                p.getContent().stream().map(this::toLogResponse).collect(Collectors.toList()),
                p.getTotalElements(), page, size);
    }

    public boolean isOutlinkEnabled() {
        return outlinkEnabled;
    }

    public void setOutlinkEnabled(boolean enabled) {
        this.outlinkEnabled = enabled;
        log.info("[SEO外链] 全局功能状态变更: {}", enabled ? "启用" : "禁用");
    }

    public int getGlobalDailyLimit() {
        return globalDailyLimit;
    }

    public void setGlobalDailyLimit(int limit) {
        this.globalDailyLimit = Math.min(Math.max(limit, 1), 10);
        log.info("[SEO外链] 全局每日限制变更: {}", this.globalDailyLimit);
    }

    public Map<String, Object> getOutlinkStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("outlinkEnabled", outlinkEnabled);
        stats.put("globalDailyLimit", globalDailyLimit);
        stats.put("totalBindings", bindingRepository.count());
        stats.put("activeBindings", bindingRepository.findByAutoPublishTrueAndStatus("ACTIVE").size());

        LocalDateTime todayStart = LocalDate.now().atTime(LocalTime.MIN);
        List<SeoBlogPublishLog> todayLogs = logRepository.findAll().stream()
                .filter(l -> l.getCreatedAt() != null && l.getCreatedAt().isAfter(todayStart))
                .collect(Collectors.toList());

        stats.put("todayTotal", todayLogs.size());
        stats.put("todayPublished", todayLogs.stream().filter(l -> "PUBLISHED".equals(l.getStatus())).count());
        stats.put("todayFailed", todayLogs.stream().filter(l -> "FAILED".equals(l.getStatus())).count());

        return stats;
    }

    // ==================== 转换方法 ====================

    private SeoBlogBindingResponse toBindingResponse(SeoBlogBinding b) {
        return SeoBlogBindingResponse.builder()
                .id(b.getId())
                .supplierId(b.getSupplierId())
                .platform(b.getPlatform())
                .blogUrl(b.getBlogUrl())
                .username(b.getUsername())
                .autoPublish(b.getAutoPublish())
                .dailyLimit(b.getDailyLimit())
                .status(b.getStatus())
                .lastTestAt(b.getLastTestAt())
                .lastTestOk(b.getLastTestOk())
                .createdAt(b.getCreatedAt())
                .updatedAt(b.getUpdatedAt())
                .build();
    }

    private SeoBlogPublishLogResponse toLogResponse(SeoBlogPublishLog l) {
        return SeoBlogPublishLogResponse.builder()
                .id(l.getId())
                .bindingId(l.getBindingId())
                .supplierId(l.getSupplierId())
                .platform(l.getPlatform())
                .productId(l.getProductId())
                .productName(l.getProductName())
                .keyword(l.getKeyword())
                .productUrl(l.getProductUrl())
                .articleTitle(l.getArticleTitle())
                .articleContent(l.getArticleContent())
                .publishUrl(l.getPublishUrl())
                .status(l.getStatus())
                .errorMessage(l.getErrorMessage())
                .publishedAt(l.getPublishedAt())
                .createdAt(l.getCreatedAt())
                .build();
    }
}
