# 联系我们 Elementor 布局指南

## 页面结构概览

```
┌─────────────────────────────────────────────────────┐
│                   页面横幅                           │
│  "联系我们" 标题                                     │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  联系信息卡片       │         在线询盘表单            │
│  - 地址            │   姓名、邮箱、电话、公司         │
│  - 电话            │   产品需求、留言                 │
│  - 邮箱            │   [提交询盘]                    │
│  - 工作时间        │                                │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   地图嵌入                           │
│  公司位置地图                                        │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│                   常见问题FAQ                        │
│  折叠面板形式                                        │
└─────────────────────────────────────────────────────┘
```

---

## 详细搭建步骤

### Section 1: 页面横幅

**Elementor 设置：**
- 最小高度：250px
- 背景：#1a5276 或办公室图片
- 叠加：rgba(26, 82, 118, 0.85)

**内容：**
- 标题：`联系我们`（H1，白色，42px）
- 副标题：`我们期待与您的合作，请随时联系我们`
- 面包屑：`首页 > 联系我们`

---

### Section 2: 联系信息 + 询盘表单

**布局：2列（35% | 65%）**
**内边距：上60px 下60px**
**间距：40px**

#### 左列：联系信息卡片

**添加 HTML 或使用图标盒子组合：**

```html
<div class="contact-info-card">
    <div class="info-item">
        <div class="info-icon">
            <i class="fas fa-map-marker-alt"></i>
        </div>
        <div class="info-text">
            <h4>公司地址</h4>
            <p>[您的公司地址]<br>中国 · [城市]</p>
        </div>
    </div>
    
    <div class="info-item">
        <div class="info-icon">
            <i class="fas fa-phone-alt"></i>
        </div>
        <div class="info-text">
            <h4>联系电话</h4>
            <p>+86 XXX-XXXX-XXXX<br>+86 XXX-XXXX-XXXX</p>
        </div>
    </div>
    
    <div class="info-item">
        <div class="info-icon">
            <i class="fas fa-envelope"></i>
        </div>
        <div class="info-text">
            <h4>电子邮箱</h4>
            <p>info@yicaitrade.com<br>sales@yicaitrade.com</p>
        </div>
    </div>
    
    <div class="info-item">
        <div class="info-icon">
            <i class="fas fa-clock"></i>
        </div>
        <div class="info-text">
            <h4>工作时间</h4>
            <p>周一至周五：9:00 - 18:00<br>周六：9:00 - 12:00</p>
        </div>
    </div>
    
    <div class="social-links">
        <a href="#"><i class="fab fa-wechat"></i></a>
        <a href="#"><i class="fab fa-whatsapp"></i></a>
        <a href="#"><i class="fab fa-linkedin"></i></a>
        <a href="#"><i class="fab fa-skype"></i></a>
    </div>
</div>
```

**联系卡片样式（已在主CSS中定义）：**
- 背景：渐变蓝色
- 圆角：8px
- 内边距：40px

#### 右列：询盘表单

**使用 Elementor Pro 表单或 Contact Form 7**

详见 `forms/inquiry-form.md`

---

### Section 3: 地图嵌入

**布局：单列，全宽**
**高度：400px**

**方式A：使用 Google Maps 小部件**
- 地址：输入公司地址
- 缩放级别：15
- 高度：400px

**方式B：使用百度地图（国内用户）**
1. 访问 map.baidu.com
2. 搜索公司地址
3. 点击"分享" → "嵌入网站"
4. 复制 iframe 代码
5. 在 Elementor 中使用 HTML 小部件粘贴

**示例代码：**
```html
<iframe 
    src="百度地图嵌入URL" 
    width="100%" 
    height="400" 
    frameborder="0" 
    style="border:0" 
    allowfullscreen>
</iframe>
```

---

### Section 4: 常见问题FAQ

**布局：单列**
**背景：#f8f9fa**
**内边距：上60px 下60px**
**最大宽度：900px，居中**

**标题：** `常见问题`

**使用手风琴（Accordion）小部件：**

**Q1: 如何获取产品报价？**
```
您可以通过以下方式获取报价：
1. 填写本页面的在线询盘表单
2. 发送邮件至 sales@yicaitrade.com
3. 拨打电话 +86 XXX-XXXX-XXXX
4. 添加微信/WhatsApp 在线咨询

我们将在24小时内回复您的询价请求。
```

**Q2: 你们的最小起订量是多少？**
```
最小起订量根据产品类型有所不同。大多数产品支持小批量采购，具体MOQ请在询盘时说明产品需求，我们会为您提供详细信息。
```

**Q3: 支持哪些付款方式？**
```
我们支持以下付款方式：
- T/T（电汇）：30%定金，发货前付清余款
- L/C（信用证）：适用于大额订单
- PayPal：适用于小额样品订单
- 西联汇款

具体付款条款可根据订单金额和合作情况协商。
```

**Q4: 产品质量如何保证？**
```
我们提供多重质量保障：
1. 严格的供应商筛选和审核
2. 专业QC团队全程质检
3. 第三方检测报告（SGS、BV等）
4. 出货前提供验货服务
5. 完善的售后服务体系
```

**Q5: 物流配送覆盖哪些地区？**
```
我们与多家国际物流公司合作，可配送至全球100多个国家和地区：
- 海运：适合大批量货物，成本较低
- 空运：适合紧急订单，速度快
- 快递：适合小批量样品

我们会根据您的需求推荐最优物流方案。
```

**手风琴样式CSS：**
```css
.elementor-accordion {
    border: none !important;
}

.elementor-accordion-item {
    background: #fff;
    margin-bottom: 15px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    overflow: hidden;
}

.elementor-tab-title {
    background: #fff !important;
    padding: 20px 25px !important;
    border: none !important;
}

.elementor-tab-title a {
    color: #2c3e50 !important;
    font-weight: 600 !important;
}

.elementor-tab-title .elementor-accordion-icon {
    color: #1a5276;
}

.elementor-tab-content {
    padding: 20px 25px !important;
    background: #fafbfc;
    border-top: 1px solid #eee;
}
```

---

## 联系信息社交图标样式

```css
.social-links {
    margin-top: 30px;
    padding-top: 20px;
    border-top: 1px solid rgba(255,255,255,0.2);
}

.social-links a {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 45px;
    height: 45px;
    background: rgba(255,255,255,0.1);
    border-radius: 50%;
    color: #fff;
    font-size: 18px;
    margin-right: 10px;
    transition: all 0.3s ease;
}

.social-links a:hover {
    background: #fff;
    color: #1a5276;
    transform: translateY(-3px);
}
```

---

## 需要准备的信息

- [ ] 公司详细地址
- [ ] 联系电话（座机、手机）
- [ ] 邮箱地址（商务邮箱）
- [ ] 工作时间
- [ ] 社交媒体账号（微信、WhatsApp、LinkedIn等）
- [ ] 常见问题解答内容
- [ ] 地图位置确认
