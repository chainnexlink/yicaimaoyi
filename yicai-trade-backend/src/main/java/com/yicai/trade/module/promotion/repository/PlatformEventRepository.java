package com.yicai.trade.module.promotion.repository;

import com.yicai.trade.module.promotion.entity.PlatformEvent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatformEventRepository extends JpaRepository<PlatformEvent, Long> {
    Page<PlatformEvent> findByStatus(String status, Pageable pageable);
    Page<PlatformEvent> findByEventType(String eventType, Pageable pageable);
    long countByStatus(String status);
}
