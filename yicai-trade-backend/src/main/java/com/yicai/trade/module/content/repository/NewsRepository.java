package com.yicai.trade.module.content.repository;

import com.yicai.trade.module.content.entity.News;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NewsRepository extends JpaRepository<News, Long> {
    Optional<News> findByNewsNo(String newsNo);
    Page<News> findByCategoryAndStatus(String category, String status, Pageable pageable);
    Page<News> findByStatus(String status, Pageable pageable);
    List<News> findByStatusAndIsRecommendTrueOrderByPublishTimeDesc(String status);
    long countByCategory(String category);
    long countByStatus(String status);

    /** 按语言查询已发布新闻（首页资讯面板用） */
    List<News> findByLangAndStatusOrderByPublishTimeDesc(String lang, String status, Pageable pageable);

    /** 按语言和行业查询已发布新闻 */
    Page<News> findByLangAndStatusAndIndustryId(String lang, String status, Long industryId, Pageable pageable);

    /** 按语言查询已发布新闻分页 */
    Page<News> findByLangAndStatus(String lang, String status, Pageable pageable);
}
