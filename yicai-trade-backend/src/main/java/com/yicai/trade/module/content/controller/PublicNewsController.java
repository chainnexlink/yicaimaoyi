package com.yicai.trade.module.content.controller;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.common.response.Result;
import com.yicai.trade.module.content.dto.IndustryResponse;
import com.yicai.trade.module.content.dto.NewsResponse;
import com.yicai.trade.module.content.entity.Industry;
import com.yicai.trade.module.content.entity.News;
import com.yicai.trade.module.content.repository.IndustryRepository;
import com.yicai.trade.module.content.repository.NewsRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 前台新闻公开API（/api/news），用于首页资讯面板 + news.html 列表/详情
 */
@Slf4j
@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
@Tag(name = "PublicNews", description = "平台宣传文案公开接口（SEO用）")
public class PublicNewsController {

    private final NewsRepository newsRepository;
    private final IndustryRepository industryRepository;

    @EventListener(ApplicationReadyEvent.class)
    public void logNewsDataStatus() {
        long total = newsRepository.count();
        long published = newsRepository.findByLangAndStatus("en", "PUBLISHED",
                PageRequest.of(0, 1)).getTotalElements();
        log.info("===== 资讯数据状态: 总计={}条, 英文已发布={}条 =====", total, published);
        if (total == 0) {
            log.warn("===== 警告: t_news表为空，请检查data-h2.sql种子数据是否正确加载 =====");
        }
    }

    @GetMapping("/latest")
    @Operation(summary = "获取最新文章（首页资讯面板）")
    public Result<List<NewsResponse>> getLatestNews(
            @RequestParam(name = "size", defaultValue = "4") int size,
            @RequestParam(name = "lang", defaultValue = "en") String lang) {
        List<News> list = newsRepository.findByLangAndStatusOrderByPublishTimeDesc(
                lang, "PUBLISHED", PageRequest.of(0, size));
        return Result.success(list.stream().map(this::toResponse).collect(Collectors.toList()));
    }

    @GetMapping("/list")
    @Operation(summary = "分页查询文章列表")
    public Result<PageResult<NewsResponse>> listNews(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size,
            @RequestParam(name = "lang", defaultValue = "en") String lang,
            @RequestParam(name = "industryId", required = false) Long industryId) {

        PageRequest pr = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "publishTime"));
        Page<News> newsPage;
        if (industryId != null) {
            newsPage = newsRepository.findByLangAndStatusAndIndustryId(lang, "PUBLISHED", industryId, pr);
        } else {
            newsPage = newsRepository.findByLangAndStatus(lang, "PUBLISHED", pr);
        }
        List<NewsResponse> content = newsPage.getContent().stream()
                .map(this::toResponse).collect(Collectors.toList());
        return Result.success(PageResult.of(content, newsPage.getTotalElements(), page, size));
    }

    @GetMapping("/{id}")
    @Operation(summary = "获取文章详情")
    @Transactional
    public Result<NewsResponse> getNewsDetail(@PathVariable("id") Long id) {
        log.debug("获取文章详情: id={}", id);
        return newsRepository.findById(id)
                .map(news -> {
                    // 增加浏览量
                    news.setViewCount(news.getViewCount() + 1);
                    newsRepository.save(news);
                    return Result.success(toResponse(news));
                })
                .orElseGet(() -> {
                    log.warn("文章不存在: id={}, 数据库总文章数={}", id, newsRepository.count());
                    return Result.notFound("文章不存在");
                });
    }

    @GetMapping("/industries")
    @Operation(summary = "获取行业品类列表（筛选用）")
    public Result<List<IndustryResponse>> getIndustries() {
        List<Industry> list = industryRepository.findByStatusOrderBySortOrderAsc("ACTIVE");
        return Result.success(list.stream().map(this::toIndustryResponse).collect(Collectors.toList()));
    }

    private NewsResponse toResponse(News n) {
        NewsResponse r = new NewsResponse();
        r.setId(n.getId());
        r.setNewsNo(n.getNewsNo());
        r.setTitle(n.getTitle());
        r.setSummary(n.getSummary());
        r.setContent(n.getContent());
        r.setCoverImage(n.getCoverImage());
        r.setCategory(n.getCategory());
        r.setViewCount(n.getViewCount());
        r.setIsTop(n.getIsTop());
        r.setIsRecommend(n.getIsRecommend());
        r.setStatus(n.getStatus());
        r.setPublishTime(n.getPublishTime());
        r.setAuthorName(n.getAuthorName());
        r.setLang(n.getLang());
        r.setIndustryId(n.getIndustryId());
        r.setIndustryName(n.getIndustryName());
        r.setAutoGenerated(n.getAutoGenerated());
        r.setCreatedAt(n.getCreatedAt());
        return r;
    }

    private IndustryResponse toIndustryResponse(Industry i) {
        return IndustryResponse.builder()
                .id(i.getId())
                .name(i.getName())
                .nameEn(i.getNameEn())
                .sortOrder(i.getSortOrder())
                .status(i.getStatus())
                .createdAt(i.getCreatedAt())
                .build();
    }
}
