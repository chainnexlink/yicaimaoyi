package com.yicai.trade.module.content.service;

import com.yicai.trade.common.ai.client.AIRequest;
import com.yicai.trade.common.ai.client.AIResponse;
import com.yicai.trade.common.ai.client.DoubaoTextClient;
import com.yicai.trade.module.content.entity.Industry;
import com.yicai.trade.module.content.entity.News;
import com.yicai.trade.module.content.repository.IndustryRepository;
import com.yicai.trade.module.content.repository.NewsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * SEO宣传文案自动生成服务
 * 每天定时调用豆包AI，按行业轮播生成英文营销文案，自动发布到新闻表
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SeoContentGeneratorService {

    private final DoubaoTextClient doubaoTextClient;
    private final IndustryRepository industryRepository;
    private final NewsRepository newsRepository;

    /** 轮播索引持久化（简易方案：内存+DB fallback） */
    private int currentIndustryIndex = 0;

    /** 自动发布开关（可通过admin API切换） */
    private volatile boolean autoPublishEnabled = true;

    private static final String SYSTEM_PROMPT = """
            你是一个专业的B2B供应链平台英文营销文案助手。
            
            请围绕我们的跨境供应链平台，创作纯英文宣传文案，用于官网SEO。
            
            内容方向（每次随机选择1-2个方向）：
            - 平台优势
            - 智能匹配工厂
            - 反向竞拍降低成本
            - 全品类供应链服务
            - 帮助海外买家高效采购
            - 安全、透明、省心
            - 如何注册、下单、发起竞拍
            - 平台能为买家带来什么价值
            
            每条格式：
            TITLE: 英文标题（包含SEO关键词）
            CONTENT: 200-400词，营销、正式、适合海外采购商。
            
            用 --- 分隔多条。只输出文案，不要多余内容。
            """;

    /**
     * 定时任务：每天凌晨2点执行
     */
    @Scheduled(cron = "${seo.auto-publish.cron:0 0 2 * * ?}")
    public void scheduledGenerate() {
        if (!autoPublishEnabled) {
            log.info("SEO自动发布已禁用，跳过");
            return;
        }
        if (!doubaoTextClient.isEnabled()) {
            log.warn("豆包文本模型未启用，跳过SEO文案生成");
            return;
        }

        try {
            List<Industry> industries = industryRepository.findByStatusOrderBySortOrderAsc("ACTIVE");
            if (industries.isEmpty()) {
                log.warn("无可用行业品类，跳过SEO文案生成");
                return;
            }

            // 轮播选择当前行业
            if (currentIndustryIndex >= industries.size()) {
                currentIndustryIndex = 0;
            }
            Industry industry = industries.get(currentIndustryIndex);
            currentIndustryIndex++;

            log.info("开始生成SEO文案: industry={} ({})", industry.getNameEn(), industry.getName());

            // 随机1-3条
            int count = 1 + new Random().nextInt(3);
            generateAndPublish(industry, count);

        } catch (Exception e) {
            log.error("SEO文案自动生成异常", e);
        }
    }

    /**
     * 手动触发生成（管理后台调用）
     */
    public int manualGenerate(Long industryId, int count) {
        Industry industry;
        if (industryId != null) {
            industry = industryRepository.findById(industryId)
                    .orElseThrow(() -> new RuntimeException("行业不存在: " + industryId));
        } else {
            List<Industry> all = industryRepository.findByStatusOrderBySortOrderAsc("ACTIVE");
            if (all.isEmpty()) throw new RuntimeException("无可用行业品类");
            industry = all.get(new Random().nextInt(all.size()));
        }
        return generateAndPublish(industry, Math.min(count, 3));
    }

    /**
     * 核心生成+入库逻辑
     */
    private int generateAndPublish(Industry industry, int count) {
        String userPrompt = "当前品类：" + industry.getNameEn() + " (" + industry.getName() + ")\n"
                + "请生成 " + count + " 条英文SEO宣传文案。";

        AIRequest request = AIRequest.builder()
                .messages(List.of(
                        AIRequest.Message.builder().role("system").content(SYSTEM_PROMPT).build(),
                        AIRequest.Message.builder().role("user").content(userPrompt).build()
                ))
                .temperature(0.85)
                .maxTokens(3000)
                .build();

        AIResponse response = doubaoTextClient.call(request);
        if (!Boolean.TRUE.equals(response.getSuccess()) || response.getContent() == null || response.getContent().isBlank()) {
            log.error("豆包AI调用失败: {}", response.getErrorMessage());
            return 0;
        }

        String raw = response.getContent().trim();
        log.debug("AI原始返回:\n{}", raw);

        // 解析多条文案
        List<News> saved = parseAndSave(raw, industry);
        log.info("SEO文案生成完毕: industry={}, saved={} 条", industry.getNameEn(), saved.size());
        return saved.size();
    }

    /**
     * 解析AI返回内容并入库
     */
    private List<News> parseAndSave(String raw, Industry industry) {
        List<News> result = new ArrayList<>();
        // 按 --- 分隔多条
        String[] sections = raw.split("---");
        Pattern titlePattern = Pattern.compile("(?i)TITLE:\\s*(.+)");
        Pattern contentPattern = Pattern.compile("(?i)CONTENT:\\s*([\\s\\S]+?)(?=\\nTITLE:|$)");

        for (String section : sections) {
            section = section.trim();
            if (section.isEmpty()) continue;

            Matcher tm = titlePattern.matcher(section);
            Matcher cm = contentPattern.matcher(section);

            String title = tm.find() ? tm.group(1).trim() : null;
            String content = cm.find() ? cm.group(1).trim() : null;

            // 兜底：如果没有明确格式，取第一行做标题，剩余做内容
            if (title == null && !section.isEmpty()) {
                String[] lines = section.split("\n", 2);
                title = lines[0].replaceAll("^#+\\s*", "").trim();
                content = lines.length > 1 ? lines[1].trim() : "";
            }

            if (title == null || title.length() < 5) continue;

            String newsNo = "SEO" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                    + UUID.randomUUID().toString().substring(0, 4).toUpperCase();

            News news = News.builder()
                    .newsNo(newsNo)
                    .title(title)
                    .summary(content != null && content.length() > 200 ? content.substring(0, 200) + "..." : content)
                    .content(content)
                    .category("SEO")
                    .lang("en")
                    .industryId(industry.getId())
                    .industryName(industry.getNameEn())
                    .autoGenerated(true)
                    .status("PUBLISHED")
                    .publishTime(LocalDateTime.now())
                    .authorName("AI Assistant")
                    .build();

            newsRepository.save(news);
            result.add(news);
        }

        return result;
    }

    // ===== 控制方法 =====

    public void setAutoPublishEnabled(boolean enabled) {
        this.autoPublishEnabled = enabled;
        log.info("SEO自动发布状态变更: {}", enabled ? "启用" : "禁用");
    }

    public boolean isAutoPublishEnabled() {
        return autoPublishEnabled;
    }
}
