package com.yicai.trade.module.logistics.repository;

import com.yicai.trade.module.logistics.entity.LogisticsTrack;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;

import java.util.List;

public interface LogisticsTrackRepository extends JpaRepository<LogisticsTrack, Long> {
    List<LogisticsTrack> findByLogisticsIdOrderByNodeTimeDesc(Long logisticsId);
    List<LogisticsTrack> findByTrackingNoOrderByNodeTimeDesc(String trackingNo);
    @Modifying
    void deleteByLogisticsId(Long logisticsId);
}
