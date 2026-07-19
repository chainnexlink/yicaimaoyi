package com.yicai.trade.module.inquiry.repository;

import com.yicai.trade.module.inquiry.entity.Inquiry;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface InquiryRepository extends JpaRepository<Inquiry, Long> {
    Page<Inquiry> findByBuyerId(Long buyerId, Pageable pageable);
    Page<Inquiry> findByStatus(String status, Pageable pageable);
    long countByStatus(String status);

    // ===== 管理后台多维筛选 =====

    @Query("SELECT i FROM Inquiry i WHERE " +
            "(:status IS NULL OR i.status = :status) AND " +
            "(:category IS NULL OR i.productCategory = :category) AND " +
            "(:keyword IS NULL OR i.title LIKE CONCAT('%',:keyword,'%')) AND " +
            "(:startTime IS NULL OR i.createdAt >= :startTime) AND " +
            "(:endTime IS NULL OR i.createdAt <= :endTime)")
    Page<Inquiry> findByAdminFilters(
            @Param("status") String status,
            @Param("category") String category,
            @Param("keyword") String keyword,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime,
            Pageable pageable);

    @Query("SELECT DISTINCT i.productCategory FROM Inquiry i WHERE i.productCategory IS NOT NULL ORDER BY i.productCategory")
    List<String> findDistinctCategories();

    @Query("SELECT i.productCategory, COUNT(i) FROM Inquiry i WHERE i.productCategory IS NOT NULL GROUP BY i.productCategory ORDER BY COUNT(i) DESC")
    List<Object[]> countByCategory();

    @Query("SELECT i.status, COUNT(i) FROM Inquiry i GROUP BY i.status")
    List<Object[]> countGroupByStatus();

    // 定时任务: 查找已过期但仍为OPEN的询价
    List<Inquiry> findByStatusAndDeadlineBefore(String status, LocalDateTime deadline);
}
