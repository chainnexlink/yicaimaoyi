package com.yicai.trade.module.content.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.content.dto.*;
import com.yicai.trade.module.content.entity.Banner;
import com.yicai.trade.module.content.entity.News;
import com.yicai.trade.module.content.repository.BannerRepository;
import com.yicai.trade.module.content.repository.NewsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentServiceImpl implements ContentService {

    private final BannerRepository bannerRepository;
    private final NewsRepository newsRepository;

    // ==================== Banner ====================

    @Override
    @Transactional
    public BannerResponse createBanner(BannerRequest request) {
        Banner banner = Banner.builder()
                .title(request.getTitle())
                .imageUrl(request.getImageUrl())
                .linkUrl(request.getLinkUrl())
                .position(request.getPosition())
                .sortOrder(request.getSortOrder())
                .status(request.getStatus())
                .startTime(request.getStartTime())
                .endTime(request.getEndTime())
                .build();
        return toBannerResponse(bannerRepository.save(banner));
    }

    @Override
    @Transactional
    public BannerResponse updateBanner(Long id, BannerRequest request) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner不存在: " + id));
        banner.setTitle(request.getTitle());
        banner.setImageUrl(request.getImageUrl());
        banner.setLinkUrl(request.getLinkUrl());
        banner.setPosition(request.getPosition());
        banner.setSortOrder(request.getSortOrder());
        banner.setStatus(request.getStatus());
        banner.setStartTime(request.getStartTime());
        banner.setEndTime(request.getEndTime());
        return toBannerResponse(bannerRepository.save(banner));
    }

    @Override
    @Transactional
    public void deleteBanner(Long id) {
        bannerRepository.deleteById(id);
    }

    @Override
    public BannerResponse getBanner(Long id) {
        return bannerRepository.findById(id)
                .map(this::toBannerResponse)
                .orElseThrow(() -> new RuntimeException("Banner不存在: " + id));
    }

    @Override
    public PageResult<BannerResponse> listBanners(String position, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Banner> bannerPage;
        if (position != null && !position.isEmpty()) {
            bannerPage = bannerRepository.findByPositionOrderBySortOrderAsc(position, pageable);
        } else {
            bannerPage = bannerRepository.findAll(pageable);
        }
        List<BannerResponse> content = bannerPage.getContent().stream()
                .map(this::toBannerResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, bannerPage.getTotalElements(), page, size);
    }

    @Override
    public List<BannerResponse> getActiveBanners(String position) {
        return bannerRepository.findByPositionAndStatusOrderBySortOrderAsc(position, "ACTIVE")
                .stream()
                .map(this::toBannerResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void updateBannerStatus(Long id, String status) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner不存在: " + id));
        banner.setStatus(status);
        bannerRepository.save(banner);
    }

    @Override
    @Transactional
    public void updateBannerOrder(Long id, Integer sortOrder) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Banner不存在: " + id));
        banner.setSortOrder(sortOrder);
        bannerRepository.save(banner);
    }

    private BannerResponse toBannerResponse(Banner banner) {
        BannerResponse response = new BannerResponse();
        response.setId(banner.getId());
        response.setTitle(banner.getTitle());
        response.setImageUrl(banner.getImageUrl());
        response.setLinkUrl(banner.getLinkUrl());
        response.setPosition(banner.getPosition());
        response.setSortOrder(banner.getSortOrder());
        response.setStatus(banner.getStatus());
        response.setStartTime(banner.getStartTime());
        response.setEndTime(banner.getEndTime());
        response.setCreatedAt(banner.getCreatedAt());
        return response;
    }

    // ==================== News ====================

    @Override
    @Transactional
    public NewsResponse createNews(Long authorId, NewsRequest request) {
        String newsNo = "NEWS" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
        News news = News.builder()
                .newsNo(newsNo)
                .title(request.getTitle())
                .summary(request.getSummary())
                .content(request.getContent())
                .coverImage(request.getCoverImage())
                .category(request.getCategory())
                .isTop(request.getIsTop())
                .isRecommend(request.getIsRecommend())
                .status(request.getStatus())
                .authorId(authorId)
                .authorName("管理员")
                .build();
        return toNewsResponse(newsRepository.save(news));
    }

    @Override
    @Transactional
    public NewsResponse updateNews(Long id, NewsRequest request) {
        News news = newsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + id));
        news.setTitle(request.getTitle());
        news.setSummary(request.getSummary());
        news.setContent(request.getContent());
        news.setCoverImage(request.getCoverImage());
        news.setCategory(request.getCategory());
        news.setIsTop(request.getIsTop());
        news.setIsRecommend(request.getIsRecommend());
        news.setStatus(request.getStatus());
        return toNewsResponse(newsRepository.save(news));
    }

    @Override
    @Transactional
    public void deleteNews(Long id) {
        newsRepository.deleteById(id);
    }

    @Override
    public NewsResponse getNews(Long id) {
        return newsRepository.findById(id)
                .map(this::toNewsResponse)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + id));
    }

    @Override
    public NewsResponse getNewsByNo(String newsNo) {
        return newsRepository.findByNewsNo(newsNo)
                .map(this::toNewsResponse)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + newsNo));
    }

    @Override
    public PageResult<NewsResponse> listNews(String category, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<News> newsPage;
        if (category != null && !category.isEmpty() && status != null && !status.isEmpty()) {
            newsPage = newsRepository.findByCategoryAndStatus(category, status, pageable);
        } else if (status != null && !status.isEmpty()) {
            newsPage = newsRepository.findByStatus(status, pageable);
        } else {
            newsPage = newsRepository.findAll(pageable);
        }
        List<NewsResponse> content = newsPage.getContent().stream()
                .map(this::toNewsResponse)
                .collect(Collectors.toList());
        return PageResult.of(content, newsPage.getTotalElements(), page, size);
    }

    @Override
    public List<NewsResponse> getRecommendNews() {
        return newsRepository.findByStatusAndIsRecommendTrueOrderByPublishTimeDesc("PUBLISHED")
                .stream()
                .map(this::toNewsResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void publishNews(Long id) {
        News news = newsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + id));
        news.setStatus("PUBLISHED");
        news.setPublishTime(LocalDateTime.now());
        newsRepository.save(news);
    }

    @Override
    @Transactional
    public void archiveNews(Long id) {
        News news = newsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + id));
        news.setStatus("ARCHIVED");
        newsRepository.save(news);
    }

    @Override
    @Transactional
    public void incrementViewCount(Long id) {
        News news = newsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("资讯不存在: " + id));
        news.setViewCount(news.getViewCount() + 1);
        newsRepository.save(news);
    }

    private NewsResponse toNewsResponse(News news) {
        NewsResponse response = new NewsResponse();
        response.setId(news.getId());
        response.setNewsNo(news.getNewsNo());
        response.setTitle(news.getTitle());
        response.setSummary(news.getSummary());
        response.setContent(news.getContent());
        response.setCoverImage(news.getCoverImage());
        response.setCategory(news.getCategory());
        response.setViewCount(news.getViewCount());
        response.setIsTop(news.getIsTop());
        response.setIsRecommend(news.getIsRecommend());
        response.setStatus(news.getStatus());
        response.setPublishTime(news.getPublishTime());
        response.setAuthorName(news.getAuthorName());
        response.setLang(news.getLang());
        response.setIndustryId(news.getIndustryId());
        response.setIndustryName(news.getIndustryName());
        response.setAutoGenerated(news.getAutoGenerated());
        response.setCreatedAt(news.getCreatedAt());
        return response;
    }
}
