package com.yicai.trade.module.seooutlink.repository;

import com.yicai.trade.module.seooutlink.entity.SeoBlogPublishLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface SeoBlogPublishLogRepository extends JpaRepository<SeoBlogPublishLog, Long> {

    Page<SeoBlogPublishLog> findBySupplierId(Long supplierId, Pageable pageable);

    Page<SeoBlogPublishLog> findBySupplierIdAndStatus(Long supplierId, String status, Pageable pageable);

    List<SeoBlogPublishLog> findByBindingIdAndCreatedAtAfter(Long bindingId, LocalDateTime after);

    long countByBindingIdAndStatusAndCreatedAtAfter(Long bindingId, String status, LocalDateTime after);

    Page<SeoBlogPublishLog> findAllBy(Pageable pageable);

    Page<SeoBlogPublishLog> findByStatus(String status, Pageable pageable);
}
