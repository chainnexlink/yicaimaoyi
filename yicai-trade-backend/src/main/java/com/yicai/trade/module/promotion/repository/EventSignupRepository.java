package com.yicai.trade.module.promotion.repository;

import com.yicai.trade.module.promotion.entity.EventSignup;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventSignupRepository extends JpaRepository<EventSignup, Long> {
    Page<EventSignup> findByEventId(Long eventId, Pageable pageable);
    Page<EventSignup> findBySupplierId(Long supplierId, Pageable pageable);
    Page<EventSignup> findByEventIdAndStatus(Long eventId, String status, Pageable pageable);
    long countByEventId(Long eventId);
    long countByEventIdAndStatus(Long eventId, String status);
    boolean existsByEventIdAndSupplierId(Long eventId, Long supplierId);
}
