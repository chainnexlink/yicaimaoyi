package com.yicai.trade.module.content.controller;

import com.yicai.trade.common.response.Result;
import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.content.dto.*;
import com.yicai.trade.module.content.service.ContentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/content")
@RequiredArgsConstructor
@Tag(name = "内容管理", description = "Banner和资讯管理接口")
public class ContentController {

    private final ContentService contentService;

    // ==================== Banner ====================

    @PostMapping("/banners")
    @Operation(summary = "创建Banner")
    public Result<BannerResponse> createBanner(@Valid @RequestBody BannerRequest request) {
        return Result.success(contentService.createBanner(request));
    }

    @PutMapping("/banners/{id}")
    @Operation(summary = "更新Banner")
    public Result<BannerResponse> updateBanner(@PathVariable Long id, @Valid @RequestBody BannerRequest request) {
        return Result.success(contentService.updateBanner(id, request));
    }

    @DeleteMapping("/banners/{id}")
    @Operation(summary = "删除Banner")
    public Result<Void> deleteBanner(@PathVariable Long id) {
        contentService.deleteBanner(id);
        return Result.success(null);
    }

    @GetMapping("/banners/{id}")
    @Operation(summary = "获取Banner详情")
    public Result<BannerResponse> getBanner(@PathVariable Long id) {
        return Result.success(contentService.getBanner(id));
    }

    @GetMapping("/banners")
    @Operation(summary = "分页查询Banner列表")
    public Result<PageResult<BannerResponse>> listBanners(
            @RequestParam(required = false) String position,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(contentService.listBanners(position, page, size));
    }

    @GetMapping("/banners/active")
    @Operation(summary = "获取活动中的Banner")
    public Result<List<BannerResponse>> getActiveBanners(
            @RequestParam(defaultValue = "HOME") String position) {
        return Result.success(contentService.getActiveBanners(position));
    }

    @PatchMapping("/banners/{id}/status")
    @Operation(summary = "更新Banner状态")
    public Result<Void> updateBannerStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        contentService.updateBannerStatus(id, body.get("status"));
        return Result.success(null);
    }

    @PatchMapping("/banners/{id}/order")
    @Operation(summary = "更新Banner排序")
    public Result<Void> updateBannerOrder(@PathVariable Long id, @RequestBody Map<String, Integer> body) {
        contentService.updateBannerOrder(id, body.get("sortOrder"));
        return Result.success(null);
    }

    // ==================== News ====================

    @PostMapping("/news")
    @Operation(summary = "创建资讯")
    public Result<NewsResponse> createNews(@Valid @RequestBody NewsRequest request) {
        return Result.success(contentService.createNews(1L, request));
    }

    @PutMapping("/news/{id}")
    @Operation(summary = "更新资讯")
    public Result<NewsResponse> updateNews(@PathVariable Long id, @Valid @RequestBody NewsRequest request) {
        return Result.success(contentService.updateNews(id, request));
    }

    @DeleteMapping("/news/{id}")
    @Operation(summary = "删除资讯")
    public Result<Void> deleteNews(@PathVariable Long id) {
        contentService.deleteNews(id);
        return Result.success(null);
    }

    @GetMapping("/news/{id}")
    @Operation(summary = "获取资讯详情")
    public Result<NewsResponse> getNews(@PathVariable Long id) {
        return Result.success(contentService.getNews(id));
    }

    @GetMapping("/news/no/{newsNo}")
    @Operation(summary = "根据编号获取资讯")
    public Result<NewsResponse> getNewsByNo(@PathVariable String newsNo) {
        return Result.success(contentService.getNewsByNo(newsNo));
    }

    @GetMapping("/news")
    @Operation(summary = "分页查询资讯列表")
    public Result<PageResult<NewsResponse>> listNews(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(contentService.listNews(category, status, page, size));
    }

    @GetMapping("/news/recommend")
    @Operation(summary = "获取推荐资讯")
    public Result<List<NewsResponse>> getRecommendNews() {
        return Result.success(contentService.getRecommendNews());
    }

    @PostMapping("/news/{id}/publish")
    @Operation(summary = "发布资讯")
    public Result<Void> publishNews(@PathVariable Long id) {
        contentService.publishNews(id);
        return Result.success(null);
    }

    @PostMapping("/news/{id}/archive")
    @Operation(summary = "归档资讯")
    public Result<Void> archiveNews(@PathVariable Long id) {
        contentService.archiveNews(id);
        return Result.success(null);
    }

    @PostMapping("/news/{id}/view")
    @Operation(summary = "增加浏览量")
    public Result<Void> incrementViewCount(@PathVariable Long id) {
        contentService.incrementViewCount(id);
        return Result.success(null);
    }
}
