package com.yicai.trade.module.seooutlink.publisher;

import com.yicai.trade.module.seooutlink.entity.SeoBlogBinding;

/**
 * 博客平台发布器接口
 */
public interface BlogPublisher {

    /** 支持的平台标识 */
    String getPlatform();

    /** 测试连接 */
    BlogPublishResult testConnection(SeoBlogBinding binding);

    /** 发布文章 */
    BlogPublishResult publish(SeoBlogBinding binding, String title, String htmlContent);
}
