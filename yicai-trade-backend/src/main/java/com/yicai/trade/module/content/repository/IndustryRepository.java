package com.yicai.trade.module.content.repository;

import com.yicai.trade.module.content.entity.Industry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IndustryRepository extends JpaRepository<Industry, Long> {
    List<Industry> findByStatusOrderBySortOrderAsc(String status);
    long countByStatus(String status);
}
