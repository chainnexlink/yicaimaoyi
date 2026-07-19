# 新闻动态 Elementor 布局指南

## 页面结构概览

```
┌─────────────────────────────────────────────────────┐
│                   页面横幅                           │
│  "新闻动态" 标题                                     │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   分类筛选                           │
│  全部 | 公司新闻 | 行业资讯 | 展会活动                │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   置顶/精选新闻                       │
│  大图展示最新重要新闻                                 │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   新闻列表                           │
│  ┌────────┐  ┌────────┐  ┌────────┐                 │
│  │ 新闻1   │  │ 新闻2   │  │ 新闻3   │                 │
│  └────────┘  └────────┘  └────────┘                 │
│  ┌────────┐  ┌────────┐  ┌────────┐                 │
│  │ 新闻4   │  │ 新闻5   │  │ 新闻6   │                 │
│  └────────┘  └────────┘  └────────┘                 │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   分页导航                           │
└─────────────────────────────────────────────────────┘
```

---

## 准备工作

### 创建新闻分类

**后台 → 文章 → 分类目录**

建议分类：
- 公司新闻（company-news）
- 行业资讯（industry-news）
- 展会活动（exhibitions）
- 产品动态（product-news）

---

## 详细搭建步骤

### Section 1: 页面横幅

**Elementor 设置：**
- 最小高度：250px
- 背景：#1a5276 或新闻相关图片
- 叠加：rgba(26, 82, 118, 0.85)

**内容：**
- 标题：`新闻动态`（H1，白色，42px）
- 副标题：`了解易采贸易最新动态与行业资讯`
- 面包屑：`首页 > 新闻动态`

---

### Section 2: 分类筛选

**布局：单列**
**背景：#f8f9fa**
**内边距：上15px 下15px**

**内容 - 使用按钮组或菜单：**
- 全部
- 公司新闻
- 行业资讯
- 展会活动
- 产品动态

**按钮样式：**
```css
.news-filter-btn {
    background: transparent;
    border: none;
    padding: 8px 20px;
    color: #5d6d7e;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.3s ease;
}

.news-filter-btn:hover,
.news-filter-btn.active {
    color: #1a5276;
    font-weight: 600;
}

.news-filter-btn.active::after {
    content: '';
    display: block;
    width: 100%;
    height: 2px;
    background: #1a5276;
    margin-top: 5px;
}
```

---

### Section 3: 置顶新闻（可选）

**布局：2列（60% | 40%）**
**背景：白色**
**内边距：上40px 下40px**

**左列：**
- 新闻大图（16:9比例）

**右列：**
- 分类标签：`公司新闻`
- 发布日期：`2024-01-15`
- 新闻标题：（H2，24px）
- 新闻摘要：（150字左右）
- 阅读更多按钮

---

### Section 4: 新闻列表

**布局：单列**
**内边距：上40px 下40px**

**使用文章小部件（Posts Widget）：**

**设置：**
- 皮肤：经典
- 列数：3（桌面），2（平板），1（手机）
- 文章数量：9
- 图片位置：顶部
- 图片比例：16:9
- 显示内容：
  - 标题：是
  - 摘要：是（限制80字）
  - 日期：是
  - 分类：是
  - 阅读更多：是
- 隐藏内容：
  - 作者：否
  - 评论数：否

**文章卡片样式：**
```css
.news-card {
    background: #fff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    transition: all 0.3s ease;
}

.news-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 25px rgba(0,0,0,0.1);
}

.news-card .news-image {
    height: 200px;
    overflow: hidden;
}

.news-card .news-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.4s ease;
}

.news-card:hover .news-image img {
    transform: scale(1.05);
}

.news-card .news-content {
    padding: 20px;
}

.news-card .news-category {
    display: inline-block;
    background: #f0f4f7;
    color: #1a5276;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    margin-bottom: 10px;
}

.news-card .news-date {
    color: #7f8c8d;
    font-size: 13px;
    margin-bottom: 10px;
}

.news-card .news-title {
    font-size: 18px;
    font-weight: 600;
    color: #2c3e50;
    line-height: 1.4;
    margin-bottom: 10px;
}

.news-card .news-title:hover {
    color: #1a5276;
}

.news-card .news-excerpt {
    font-size: 14px;
    color: #5d6d7e;
    line-height: 1.6;
}

.news-card .read-more {
    display: inline-block;
    margin-top: 15px;
    color: #1a5276;
    font-size: 14px;
    font-weight: 500;
}

.news-card .read-more:hover {
    text-decoration: underline;
}
```

---

### Section 5: 分页导航

**文章小部件自带分页，或使用以下样式：**

```css
.news-pagination {
    display: flex;
    justify-content: center;
    gap: 8px;
    margin-top: 40px;
}

.news-pagination a,
.news-pagination span {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 40px;
    height: 40px;
    padding: 0 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    color: #5d6d7e;
    text-decoration: none;
    transition: all 0.3s ease;
}

.news-pagination a:hover,
.news-pagination .current {
    background: #1a5276;
    border-color: #1a5276;
    color: #fff;
}

.news-pagination .prev,
.news-pagination .next {
    padding: 0 20px;
}
```

---

## 新闻详情页模板

如使用 Elementor Pro，可创建单篇文章模板：

```
┌─────────────────────────────────────────────────────┐
│  面包屑：首页 > 新闻动态 > 文章标题                   │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   文章标题                           │
│  发布日期 | 分类 | 阅读量                            │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   特色图片                           │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   文章正文                           │
│                                                     │
│  正文内容...                                         │
│                                                     │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  上一篇 ←                              → 下一篇      │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   相关文章推荐                        │
└─────────────────────────────────────────────────────┘
```

---

## 新闻内容建议

### 内容类型参考

**公司新闻：**
- 公司获得新认证/资质
- 参加国际展会报道
- 公司周年庆/重大活动
- 新办公室/仓库启用
- 重要客户来访

**行业资讯：**
- 行业政策解读
- 市场趋势分析
- 国际贸易动态
- 汇率变化影响

**展会活动：**
- 展会预告
- 展会现场报道
- 展会总结回顾

**产品动态：**
- 新产品上线
- 产品升级公告
- 热门产品推荐

---

## 需要准备的内容

- [ ] 每篇新闻的特色图片（建议 1200x630px）
- [ ] 新闻标题和正文内容
- [ ] 合理的分类归档
- [ ] 定期更新计划（建议每周1-2篇）
