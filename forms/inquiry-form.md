# 在线询盘表单配置指南

## 方案选择

| 方案 | 插件 | 优点 | 缺点 |
|------|------|------|------|
| A | Elementor Pro 表单 | 与页面无缝集成，样式统一 | 需要付费版本 |
| B | Contact Form 7 | 免费，功能强大 | 需要额外CSS样式 |
| C | WPForms Lite | 可视化编辑，易用 | 高级功能需付费 |

---

## 方案A：Elementor Pro 表单

### 表单字段设计

在 Elementor 编辑器中添加「表单」小部件，配置以下字段：

| 字段类型 | 标签 | ID | 必填 | 占位符 |
|---------|------|-----|------|--------|
| Text | 您的姓名 | name | 是 | 请输入您的姓名 |
| Email | 电子邮箱 | email | 是 | 请输入您的邮箱 |
| Tel | 联系电话 | phone | 是 | 请输入您的电话 |
| Text | 公司名称 | company | 否 | 请输入公司名称 |
| Select | 产品类型 | product_type | 否 | 请选择产品类型 |
| Textarea | 详细需求 | message | 是 | 请描述您的产品需求... |
| Acceptance | 隐私协议 | privacy | 是 | 我同意隐私政策 |

### 产品类型下拉选项

```
电子产品
机械设备
家居用品
服装纺织
其他产品
```

### 表单操作配置

**提交后操作：**
1. Email - 发送邮件通知
2. Email2 - 发送确认邮件给客户

**Email 设置（通知管理员）：**
- 收件人：your-email@company.com
- 主题：[网站询盘] 来自 [field id="name"] 的询盘
- 发件人：[field id="email"]

**邮件内容模板：**
```
您收到一条新的产品询盘：

客户姓名：[field id="name"]
电子邮箱：[field id="email"]  
联系电话：[field id="phone"]
公司名称：[field id="company"]
产品类型：[field id="product_type"]

详细需求：
[field id="message"]

---
此邮件由网站询盘系统自动发送
```

**Email2 设置（确认客户）：**
- 收件人：[field id="email"]
- 主题：感谢您的询盘 - 易采贸易
- 发件人：noreply@yourcompany.com

**确认邮件内容：**
```
尊敬的 [field id="name"]：

感谢您对易采贸易的关注！

我们已收到您的产品询盘，我们的销售团队将在24小时内与您联系。

您提交的信息：
产品类型：[field id="product_type"]
详细需求：[field id="message"]

如有紧急需求，请直接联系：
电话：+86 XXX-XXXX-XXXX
邮箱：sales@yourcompany.com

祝商祺！
易采贸易团队
```

### 表单样式设置

在 Elementor 表单小部件的样式选项卡：

**表单样式：**
- 列间距：20px
- 行间距：20px

**字段样式：**
- 文字颜色：#2c3e50
- 背景色：#ffffff
- 边框类型：实线
- 边框宽度：1px
- 边框颜色：#ddd
- 边框圆角：4px
- 内边距：12px 16px

**聚焦状态：**
- 边框颜色：#1a5276
- 阴影：0 0 0 3px rgba(26,82,118,0.1)

**标签样式：**
- 颜色：#2c3e50
- 字重：500
- 间距：8px

**按钮样式：**
- 背景色：#1a5276
- 文字颜色：#ffffff
- 内边距：15px 40px
- 边框圆角：4px

**按钮悬停：**
- 背景色：#2980b9

---

## 方案B：Contact Form 7

### 安装插件

1. 后台 → 插件 → 安装插件
2. 搜索 "Contact Form 7"
3. 安装并激活

### 创建表单

1. 后台 → 联系 → 新建联系表单
2. 表单名称：产品询盘表单

### 表单代码

```html
<div class="inquiry-form-wrapper">
    <div class="form-row">
        <div class="form-col">
            <label>您的姓名 <span class="required">*</span></label>
            [text* your-name placeholder "请输入您的姓名"]
        </div>
        <div class="form-col">
            <label>电子邮箱 <span class="required">*</span></label>
            [email* your-email placeholder "请输入您的邮箱"]
        </div>
    </div>
    
    <div class="form-row">
        <div class="form-col">
            <label>联系电话 <span class="required">*</span></label>
            [tel* your-phone placeholder "请输入您的电话"]
        </div>
        <div class="form-col">
            <label>公司名称</label>
            [text your-company placeholder "请输入公司名称"]
        </div>
    </div>
    
    <div class="form-row">
        <div class="form-col full-width">
            <label>产品类型</label>
            [select product-type include_blank "请选择产品类型" "电子产品" "机械设备" "家居用品" "服装纺织" "其他产品"]
        </div>
    </div>
    
    <div class="form-row">
        <div class="form-col full-width">
            <label>详细需求 <span class="required">*</span></label>
            [textarea* your-message placeholder "请详细描述您的产品需求，包括规格、数量、预算等信息..."]
        </div>
    </div>
    
    <div class="form-row">
        <div class="form-col full-width">
            [acceptance privacy-policy] 我已阅读并同意 <a href="/privacy-policy">隐私政策</a> [/acceptance]
        </div>
    </div>
    
    <div class="form-row">
        <div class="form-col full-width">
            [submit class:submit-btn "提交询盘"]
        </div>
    </div>
</div>
```

### 邮件设置

**邮件选项卡配置：**

收件人：
```
your-email@company.com
```

主题：
```
[网站询盘] 来自 [your-name] 的产品询盘
```

发件人：
```
[your-name] <[your-email]>
```

邮件正文：
```
您收到一条新的产品询盘：

客户姓名：[your-name]
电子邮箱：[your-email]
联系电话：[your-phone]
公司名称：[your-company]
产品类型：[product-type]

详细需求：
[your-message]

---
此邮件由网站询盘系统自动发送
IP地址：[_remote_ip]
提交时间：[_date] [_time]
```

### Contact Form 7 样式CSS

将以下CSS添加到自定义样式中：

```css
/* Contact Form 7 询盘表单样式 */
.inquiry-form-wrapper {
    background: #fff;
    padding: 40px;
    border-radius: 8px;
    box-shadow: 0 5px 20px rgba(0,0,0,0.08);
}

.inquiry-form-wrapper .form-row {
    display: flex;
    gap: 20px;
    margin-bottom: 20px;
}

.inquiry-form-wrapper .form-col {
    flex: 1;
}

.inquiry-form-wrapper .form-col.full-width {
    flex: 100%;
}

.inquiry-form-wrapper label {
    display: block;
    margin-bottom: 8px;
    font-weight: 500;
    color: #2c3e50;
    font-size: 14px;
}

.inquiry-form-wrapper .required {
    color: #e74c3c;
}

.inquiry-form-wrapper input[type="text"],
.inquiry-form-wrapper input[type="email"],
.inquiry-form-wrapper input[type="tel"],
.inquiry-form-wrapper select,
.inquiry-form-wrapper textarea {
    width: 100%;
    padding: 12px 16px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 15px;
    font-family: inherit;
    transition: all 0.3s ease;
    background: #fff;
}

.inquiry-form-wrapper input:focus,
.inquiry-form-wrapper select:focus,
.inquiry-form-wrapper textarea:focus {
    outline: none;
    border-color: #1a5276;
    box-shadow: 0 0 0 3px rgba(26,82,118,0.1);
}

.inquiry-form-wrapper textarea {
    min-height: 150px;
    resize: vertical;
}

.inquiry-form-wrapper select {
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%235d6d7e' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 15px center;
    padding-right: 40px;
}

.inquiry-form-wrapper .wpcf7-list-item {
    margin: 0;
}

.inquiry-form-wrapper .wpcf7-acceptance {
    font-size: 14px;
    color: #5d6d7e;
}

.inquiry-form-wrapper .wpcf7-acceptance a {
    color: #1a5276;
    text-decoration: underline;
}

.inquiry-form-wrapper .submit-btn,
.inquiry-form-wrapper input[type="submit"] {
    background: #1a5276;
    color: #fff;
    border: none;
    padding: 15px 40px;
    border-radius: 4px;
    font-size: 16px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    width: 100%;
}

.inquiry-form-wrapper .submit-btn:hover,
.inquiry-form-wrapper input[type="submit"]:hover {
    background: #2980b9;
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(26,82,118,0.3);
}

/* 成功/错误消息 */
.wpcf7-response-output {
    margin: 20px 0 0 0 !important;
    padding: 15px 20px !important;
    border-radius: 4px !important;
}

.wpcf7-mail-sent-ok {
    background: #d4edda !important;
    border-color: #c3e6cb !important;
    color: #155724 !important;
}

.wpcf7-validation-errors,
.wpcf7-mail-sent-ng {
    background: #f8d7da !important;
    border-color: #f5c6cb !important;
    color: #721c24 !important;
}

/* 加载状态 */
.wpcf7-spinner {
    display: none;
}

.wpcf7-form.submitting .submit-btn {
    opacity: 0.7;
    cursor: not-allowed;
}

/* 响应式 */
@media (max-width: 768px) {
    .inquiry-form-wrapper {
        padding: 25px;
    }
    
    .inquiry-form-wrapper .form-row {
        flex-direction: column;
        gap: 0;
    }
    
    .inquiry-form-wrapper .form-col {
        margin-bottom: 15px;
    }
}
```

### 在页面中使用

1. 在 Elementor 编辑页面
2. 添加「短代码」小部件
3. 输入表单短代码：`[contact-form-7 id="表单ID" title="产品询盘表单"]`

---

## 表单安全建议

### 1. 添加 reCAPTCHA 验证

**Contact Form 7:**
1. 安装 "Contact Form 7 - reCAPTCHA" 插件
2. 获取 Google reCAPTCHA 密钥
3. 在表单中添加 `[recaptcha]`

**Elementor Pro:**
- 设置 → Integrations → reCAPTCHA
- 填入 Site Key 和 Secret Key

### 2. 添加蜜罐字段（反垃圾）

```html
<!-- 隐藏字段，机器人会填写 -->
<div style="display:none;">
    [text honeypot]
</div>
```

---

## 邮件发送问题排查

如果收不到邮件，请检查：

1. **安装 SMTP 插件**
   - WP Mail SMTP
   - Easy WP SMTP
   
2. **推荐 SMTP 服务**
   - 阿里云邮箱
   - 腾讯企业邮箱
   - SendGrid（国外）
   
3. **SMTP 配置示例（以阿里云为例）**
   ```
   SMTP 主机：smtp.mxhichina.com
   端口：465 (SSL) 或 25
   用户名：your-email@yourdomain.com
   密码：邮箱密码
   ```

---

## 测试清单

- [ ] 填写表单提交测试
- [ ] 检查管理员是否收到邮件
- [ ] 检查客户确认邮件
- [ ] 手机端填写测试
- [ ] 必填字段验证测试
- [ ] 邮箱格式验证测试
