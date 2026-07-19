-- ============================================================
-- V16: AI SEO 外链智能体 - 供应商博客绑定与发布日志
-- ============================================================

CREATE TABLE IF NOT EXISTS t_seo_blog_binding (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id     BIGINT       NOT NULL COMMENT '供应商ID',
    platform        VARCHAR(30)  NOT NULL COMMENT '博客平台: WORDPRESS / BLOGGER / TUMBLR',
    blog_url        VARCHAR(500) NOT NULL COMMENT '博客地址',
    username        VARCHAR(200)          COMMENT '用户名',
    app_password    VARCHAR(500)          COMMENT '密码/应用密码(加密存储)',
    auto_publish    TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否启用自动发布: 0=否, 1=是',
    daily_limit     INT          NOT NULL DEFAULT 1 COMMENT '每日发布篇数上限(1-3)',
    status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE / DISABLED / ERROR',
    last_test_at    DATETIME              COMMENT '最后测试连接时间',
    last_test_ok    TINYINT(1)            COMMENT '最后测试是否成功',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_supplier_platform (supplier_id, platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商SEO博客绑定';

CREATE TABLE IF NOT EXISTS t_seo_blog_publish_log (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    binding_id      BIGINT       NOT NULL COMMENT '关联绑定ID',
    supplier_id     BIGINT       NOT NULL COMMENT '供应商ID',
    platform        VARCHAR(30)  NOT NULL COMMENT '发布平台',
    product_id      BIGINT                COMMENT '关联产品ID',
    product_name    VARCHAR(200)          COMMENT '产品名称',
    keyword         VARCHAR(200)          COMMENT '目标关键词',
    product_url     VARCHAR(500)          COMMENT '产品外链URL',
    article_title   VARCHAR(300)          COMMENT '文章标题',
    article_content TEXT                  COMMENT '文章正文',
    publish_url     VARCHAR(500)          COMMENT '发布后的文章URL',
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING / PUBLISHED / FAILED',
    error_message   VARCHAR(1000)         COMMENT '失败原因',
    published_at    DATETIME              COMMENT '发布时间',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_supplier (supplier_id),
    INDEX idx_binding (binding_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SEO博客发布日志';
