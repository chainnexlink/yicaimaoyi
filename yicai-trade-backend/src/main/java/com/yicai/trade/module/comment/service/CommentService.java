package com.yicai.trade.module.comment.service;

import com.yicai.trade.common.response.PageResult;
import com.yicai.trade.module.comment.dto.CommentResponse;
import java.util.Map;

public interface CommentService {
    PageResult<CommentResponse> list(String status, String sourceType, int page, int size);
    void approve(Long id);
    void hide(Long id);
    void delete(Long id);
    Map<String, Long> getStats();
}
