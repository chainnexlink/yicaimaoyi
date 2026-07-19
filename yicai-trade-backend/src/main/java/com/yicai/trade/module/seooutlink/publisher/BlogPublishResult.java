package com.yicai.trade.module.seooutlink.publisher;

/**
 * 博客平台发布结果
 */
public record BlogPublishResult(boolean success, String publishUrl, String errorMessage) {

    public static BlogPublishResult ok(String publishUrl) {
        return new BlogPublishResult(true, publishUrl, null);
    }

    public static BlogPublishResult fail(String errorMessage) {
        return new BlogPublishResult(false, null, errorMessage);
    }
}
