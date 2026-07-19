package com.yicai.trade.module.membership.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.membership.dto.MembershipResponse;
import java.util.Map;

public interface MembershipService {
    MembershipResponse getByUserId(Long userId);
    PageResult<MembershipResponse> list(String level, int page, int size);
    void updateLevel(Long id, String level);
    void addPoints(Long id, int points);
    Map<String, Long> getStats();
}
