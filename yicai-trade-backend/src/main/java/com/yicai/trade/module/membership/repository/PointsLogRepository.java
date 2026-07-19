package com.yicai.trade.module.membership.repository;

import com.yicai.trade.module.membership.entity.PointsLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PointsLogRepository extends JpaRepository<PointsLog, Long> {

    Page<PointsLog> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    List<PointsLog> findBySourceTypeAndSourceId(String sourceType, Long sourceId);

    List<PointsLog> findByUserIdAndSourceTypeAndSourceId(Long userId, String sourceType, Long sourceId);
}
