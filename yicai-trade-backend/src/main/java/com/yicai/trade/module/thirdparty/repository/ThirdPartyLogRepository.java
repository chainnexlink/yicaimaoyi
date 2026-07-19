package com.yicai.trade.module.thirdparty.repository;

import com.yicai.trade.module.thirdparty.entity.ThirdPartyLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ThirdPartyLogRepository extends JpaRepository<ThirdPartyLog, Long> {
    Page<ThirdPartyLog> findByConfigKey(String configKey, Pageable pageable);
    long countByConfigKeyAndSuccess(String configKey, Boolean success);
}
