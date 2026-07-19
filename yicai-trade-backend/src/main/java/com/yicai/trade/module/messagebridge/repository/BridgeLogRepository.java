package com.yicai.trade.module.messagebridge.repository;

import com.yicai.trade.module.messagebridge.entity.MessageBridgeLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface BridgeLogRepository extends JpaRepository<MessageBridgeLog, Long> {

    Page<MessageBridgeLog> findBySupplierId(Long supplierId, Pageable pageable);

    Page<MessageBridgeLog> findBySupplierIdAndChannelType(Long supplierId, String channelType, Pageable pageable);

    long countBySupplierIdAndCreatedAtAfter(Long supplierId, LocalDateTime after);

    long countByCreatedAtAfter(LocalDateTime after);

    long countByStatus(String status);

    @Query("SELECT COUNT(l) FROM MessageBridgeLog l WHERE l.channelType = :channelType")
    long countByChannelType(String channelType);
}
