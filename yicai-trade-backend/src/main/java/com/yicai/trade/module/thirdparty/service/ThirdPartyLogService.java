package com.yicai.trade.module.thirdparty.service;

/**
 * 第三方API调用日志服务
 */
public interface ThirdPartyLogService {

    void log(String configKey, String action, String target,
             String requestData, String responseData,
             boolean success, String errorMsg, long costMs);

    void incrementQuota(String configKey);
}
