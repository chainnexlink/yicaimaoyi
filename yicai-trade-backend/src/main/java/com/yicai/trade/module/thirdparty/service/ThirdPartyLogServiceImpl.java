package com.yicai.trade.module.thirdparty.service;

import com.yicai.trade.module.thirdparty.entity.ThirdPartyLog;
import com.yicai.trade.module.thirdparty.repository.ThirdPartyConfigRepository;
import com.yicai.trade.module.thirdparty.repository.ThirdPartyLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ThirdPartyLogServiceImpl implements ThirdPartyLogService {

    private final ThirdPartyLogRepository logRepository;
    private final ThirdPartyConfigRepository configRepository;

    @Override
    @Async
    public void log(String configKey, String action, String target,
                    String requestData, String responseData,
                    boolean success, String errorMsg, long costMs) {
        try {
            ThirdPartyLog logEntry = ThirdPartyLog.builder()
                    .configKey(configKey)
                    .action(action)
                    .target(target)
                    .requestData(requestData)
                    .responseData(responseData)
                    .success(success)
                    .errorMsg(errorMsg)
                    .costMs((int) costMs)
                    .build();
            logRepository.save(logEntry);

            if (success) {
                incrementQuota(configKey);
            }
        } catch (Exception e) {
            log.warn("记录第三方API日志失败: configKey={}, error={}", configKey, e.getMessage());
        }
    }

    @Override
    @Transactional
    public void incrementQuota(String configKey) {
        configRepository.findByConfigKey(configKey).ifPresent(config -> {
            config.setUsedQuota(config.getUsedQuota() + 1);
            configRepository.save(config);
        });
    }
}
