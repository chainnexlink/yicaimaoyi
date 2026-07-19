package com.yicai.trade.module.thirdparty.repository;

import com.yicai.trade.module.thirdparty.entity.ThirdPartyConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface ThirdPartyConfigRepository extends JpaRepository<ThirdPartyConfig, Long> {
    Optional<ThirdPartyConfig> findByConfigKey(String configKey);
    List<ThirdPartyConfig> findAllByOrderByIdAsc();
}
