# AI智能体集成指南

## 概述
本指南介绍如何将现有的易采贸易网站AI聊天悬浮窗口升级为功能完整的智能体系统，支持项目功能调用。

## 已完成的工作

### 1. 前端增强 (`js/ai-agent-enhanced.js`)
- 创建了增强版的悬浮窗口UI
- 支持工具调用可视化
- 改进的用户交互体验
- 文件上传支持
- 实时状态显示

### 2. 样式文件 (`css/ai-agent-enhanced.css`)
- 现代化的UI设计
- 响应式布局
- 暗色模式支持
- 动画效果

### 3. 后端增强 (`Java代码`)
- `AIAgentController.java`: 智能体API控制器
- `AgentRequest.java`: 智能体请求DTO
- `AgentResponse.java`: 智能体响应DTO

## 集成步骤

### 步骤1: 引入前端文件
在需要智能体的页面中添加以下代码：

```html
<!-- 在head标签中引入样式 -->
<link rel="stylesheet" href="css/ai-agent-enhanced.css">

<!-- 在body结束前引入脚本 -->
<script src="js/ai-agent-enhanced.js"></script>
```

### 步骤2: 配置后端API
确保后端服务运行在正确的端口（默认8081），并支持以下API端点：

```
GET  /api/ai-agent/health          # 健康检查
POST /api/ai-agent/message         # 智能体对话
GET  /api/ai-agent/tools           # 获取工具列表
POST /api/ai-agent/execute-tool    # 执行工具
```

### 步骤3: 替换现有AI聊天
如果已经存在`ai-chat.js`，智能体系统会自动替换它。如果没有，智能体会自动初始化。

## 功能特性

### 1. 工具调用系统
智能体支持以下工具调用：
- **search_products**: 搜索产品
- **match_factories**: 匹配工厂
- **create_reverse_auction**: 创建反向竞拍
- **calculate_cost**: 计算成本
- **check_order_status**: 检查订单状态
- **navigate_page**: 页面导航
- **explain_feature**: 功能解释

### 2. 上下文感知
- 根据当前页面提供相关帮助
- 记忆会话历史
- 智能推荐下一步操作

### 3. 文件处理
- 支持图片上传（PNG, JPEG, GIF, WebP, BMP）
- 支持文档上传（PDF, Word, Excel, PPT, TXT, CSV）
- 最大文件大小：10MB
- 最多同时上传5个文件

### 4. 用户界面
- 现代化的悬浮按钮
- 可折叠工具面板
- 实时打字指示器
- 响应式设计
- 暗色模式支持

## 使用示例

### 示例1: 搜索产品
用户说："帮我找陶瓷杯"
智能体会：
1. 调用`search_products`工具
2. 显示匹配的产品列表
3. 提供查看详情的链接

### 示例2: 创建竞拍
用户说："我想采购1000个不锈钢水壶"
智能体会：
1. 调用`create_reverse_auction`工具
2. 显示竞拍表单
3. 引导用户确认并提交

### 示例3: 页面导航
用户说："带我去智能匹配页面"
智能体会：
1. 调用`navigate_page`工具
2. 跳转到`/smart-match.html`
3. 提供页面功能介绍

## 配置选项

### 前端配置 (`ai-agent-enhanced.js`)
```javascript
// 主要配置项
var HTTP_API_URL = '/api/ai-chat/message';  // API地址
var AGENT_API_URL = '/api/ai-agent/message'; // 智能体API
var RESPONSE_TIMEOUT = 45000;               // 响应超时(毫秒)
var MAX_FILE_SIZE = 10 * 1024 * 1024;       // 最大文件大小
var MAX_FILES = 5;                          // 最大文件数量
```

### 后端配置
在`application.yml`中配置：
```yaml
ai:
  agent:
    enabled: true
    max-session-time: 1800000    # 会话超时(30分钟)
    max-history-length: 20       # 最大历史记录
    tools-enabled: true          # 启用工具调用
    file-upload-enabled: true    # 启用文件上传
```

## 扩展开发

### 添加新工具
1. 在后端`AIAgentService`中添加工具方法
2. 在工具定义中注册新工具
3. 在前端工具面板中显示新工具

### 自定义样式
1. 修改`css/ai-agent-enhanced.css`
2. 添加自定义主题
3. 调整布局和动画

### 集成其他服务
1. 添加新的API端点
2. 实现服务调用逻辑
3. 更新前端交互

## 故障排除

### 常见问题

1. **智能体不显示**
   - 检查CSS和JS文件路径
   - 查看浏览器控制台错误
   - 确保DOM加载完成

2. **API调用失败**
   - 检查后端服务状态
   - 验证API端点URL
   - 查看网络请求详情

3. **工具调用无响应**
   - 检查工具定义
   - 验证参数格式
   - 查看后端日志

4. **文件上传失败**
   - 检查文件大小限制
   - 验证文件类型
   - 检查网络连接

### 调试方法
```javascript
// 在浏览器控制台中调试
window.toggleAgentWindow()  // 打开/关闭智能体窗口
console.log(window.aiAgentState)  // 查看智能体状态
```

## 性能优化

### 前端优化
- 使用懒加载
- 压缩JS/CSS文件
- 缓存API响应

### 后端优化
- 使用连接池
- 缓存工具结果
- 异步处理请求

## 安全考虑

1. **API安全**
   - 验证请求来源
   - 限制请求频率
   - 敏感数据加密

2. **文件安全**
   - 验证文件类型
   - 扫描恶意文件
   - 限制上传权限

3. **会话安全**
   - 会话超时机制
   - 数据清理策略
   - 访问日志记录

## 未来扩展

### 计划功能
1. **语音输入支持**
2. **多语言界面**
3. **实时协作**
4. **数据分析仪表板**
5. **移动端优化**

### 技术升级
1. **WebSocket实时通信**
2. **GraphQL API**
3. **微服务架构**
4. **容器化部署**

## 支持与反馈

如有问题或建议，请联系：
- 技术支持: tech@yicai-trade.com
- 功能建议: feedback@yicai-trade.com
- 紧急问题: emergency@yicai-trade.com

## 版本历史

### v1.0.0 (当前)
- 基础智能体功能
- 工具调用系统
- 文件上传支持
- 响应式UI设计

### v0.9.0 (初始版本)
- 基于现有AI聊天系统
- 基础对话功能
- 简单工具调用