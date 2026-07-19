package com.yicai.trade.module.content.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.content.dto.*;
import java.util.List;

public interface ContentService {
    // Banner
    BannerResponse createBanner(BannerRequest request);
    BannerResponse updateBanner(Long id, BannerRequest request);
    void deleteBanner(Long id);
    BannerResponse getBanner(Long id);
    PageResult<BannerResponse> listBanners(String position, int page, int size);
    List<BannerResponse> getActiveBanners(String position);
    void updateBannerStatus(Long id, String status);
    void updateBannerOrder(Long id, Integer sortOrder);
    
    // News
    NewsResponse createNews(Long authorId, NewsRequest request);
    NewsResponse updateNews(Long id, NewsRequest request);
    void deleteNews(Long id);
    NewsResponse getNews(Long id);
    NewsResponse getNewsByNo(String newsNo);
    PageResult<NewsResponse> listNews(String category, String status, int page, int size);
    List<NewsResponse> getRecommendNews();
    void publishNews(Long id);
    void archiveNews(Long id);
    void incrementViewCount(Long id);
}
