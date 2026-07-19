package com.yicai.trade.module.aftersale.repository;

import com.yicai.trade.module.aftersale.entity.AftersaleLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AftersaleLogRepository extends JpaRepository<AftersaleLog, Long> {
    List<AftersaleLog> findByAftersaleIdOrderByCreatedAtAsc(Long aftersaleId);
}
