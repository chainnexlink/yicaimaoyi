package com.yicai.trade.module.certification.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.certification.dto.*;
import java.util.List;
import java.util.Map;

public interface CertificationService {
    // 用户端：提交认证申请
    CertificationResponse create(Long userId, CertificationRequest request);
    // 用户端：查看我的认证列表
    List<CertificationResponse> getMyList(Long userId);
    // 用户端：查看认证详情
    CertificationResponse getById(Long id);

    // 管理端：分页查询认证列表
    PageResult<CertificationResponse> list(String status, String certType, int page, int size);
    // 管理端：审核认证申请
    void audit(Long id, String action, String remark, String auditor);
    // 管理端：统计数据
    Map<String, Long> getStats();
}
