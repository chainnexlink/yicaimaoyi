/**
 * AI智能体增强版 - 易采贸易平台
 * 基于现有AI聊天悬浮窗口升级，支持项目功能调用
 */

(function () {
    'use strict';

    // ==================== 配置 ====================
    var API_BASE = (function() {
        var port = window.location.port;
        if (!port || port === '80' || port === '443' || port === '8081') return '/api/ai-agent';
        return 'http://' + window.location.hostname + ':8081/api/ai-agent';
    })();
    
    var AGENT_API_URL = API_BASE + '/message';
    var AGENT_TOOLS_URL = API_BASE + '/tools';
    var AGENT_HEALTH_URL = API_BASE + '/health';
    var RESPONSE_TIMEOUT = 45000;     // 45秒超时
    var responseTimer = null;
    var responseStartTime = 0;
    var progressTimer = null;
    var lastSentText = '';
    var httpSessionId = null;
    
    // 文件上传状态
    var pendingFiles = [];
    var ALLOWED_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/bmp'];
    var ALLOWED_FILE_EXTS = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv', '.zip', '.rar'];
    var MAX_FILE_SIZE = 10 * 1024 * 1024;
    var MAX_FILES = 5;

    // ==================== DOM创建 ====================

    function createEnhancedWidget() {
        // 移除现有的悬浮按钮（如果存在）
        var existingFab = document.getElementById('aiChatFab');
        if (existingFab) existingFab.remove();
        
        var existingWindow = document.getElementById('aiChatWindow');
        if (existingWindow) existingWindow.remove();

        // 创建增强版悬浮按钮
        var fab = document.createElement('div');
        fab.className = 'ai-agent-fab';
        fab.id = 'aiAgentFab';
        fab.innerHTML = '<div class="ai-fab-pulse"></div>' +
            '<svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12c0 1.54.36 3 1 4.32L2 22l5.68-1C9 21.64 10.46 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm-1 14h-1.5v-1.5H11V16zm2.07-4.75l-.9.92C11.45 12.9 11 13.5 11 15h-1.5v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-1.93 1.57-3.5 3.5-3.5S14 7.07 14 9c0 .88-.36 1.68-.93 2.25z"/></svg>' +
            '<div class="ai-agent-badge">AI</div>';
        fab.title = '易小采智能助手 - 支持项目功能调用';
        fab.onclick = toggleAgent;

        // 创建增强版聊天窗口
        var win = document.createElement('div');
        win.className = 'ai-agent-window';
        win.id = 'aiAgentWindow';
        win.innerHTML = buildEnhancedWindowHTML();

        document.body.appendChild(fab);
        document.body.appendChild(win);

        // 绑定事件
        document.getElementById('aiAgentCloseBtn').onclick = toggleAgent;
        document.getElementById('aiAgentSendBtn').onclick = sendAgentMessage;
        document.getElementById('aiAgentInput').onkeydown = function (e) {
            if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendAgentMessage(); }
        };
        document.getElementById('aiAgentUploadBtn').onclick = function () {
            document.getElementById('aiAgentFileInput').click();
        };
        document.getElementById('aiAgentFileInput').onchange = handleFileSelect;

        // 快捷操作按钮
        var quickActions = document.querySelectorAll('.ai-agent-quick-action');
        for (var i = 0; i < quickActions.length; i++) {
            quickActions[i].onclick = function() {
                var action = this.getAttribute('data-action');
                executeQuickAction(action);
            };
        }

        // 工具按钮
        var toolBtns = document.querySelectorAll('.ai-agent-tool-btn');
        for (var i = 0; i < toolBtns.length; i++) {
            toolBtns[i].onclick = function() {
                var tool = this.getAttribute('data-tool');
                var params = this.getAttribute('data-params');
                executeTool(tool, params ? JSON.parse(params) : {});
            };
        }

        // 拖放支持
        var msgArea = document.getElementById('aiAgentMessages');
        msgArea.ondragover = function (e) { e.preventDefault(); e.stopPropagation(); msgArea.classList.add('ai-drag-over'); };
        msgArea.ondragleave = function (e) { e.preventDefault(); e.stopPropagation(); msgArea.classList.remove('ai-drag-over'); };
        msgArea.ondrop = function (e) {
            e.preventDefault(); e.stopPropagation();
            msgArea.classList.remove('ai-drag-over');
            if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) addFiles(e.dataTransfer.files);
        };

        // 检查后端健康状态
        checkAgentHealth();
        
        // 加载可用工具
        loadAvailableTools();
    }

    function buildEnhancedWindowHTML() {
        var currentPage = getCurrentPage();
        var pageName = currentPage.substring(currentPage.lastIndexOf('/') + 1);
        if (pageName.includes('?')) pageName = pageName.substring(0, pageName.indexOf('?'));
        if (pageName.includes('#')) pageName = pageName.substring(0, pageName.indexOf('#'));

        return `
            <div class="ai-agent-header">
                <div class="ai-agent-header-left">
                    <div class="ai-agent-avatar">AI</div>
                    <div class="ai-agent-title">
                        <div class="ai-agent-name">易小采智能助手</div>
                        <div class="ai-agent-status" id="aiAgentStatus">连接中...</div>
                    </div>
                </div>
                <button class="ai-agent-close-btn" id="aiAgentCloseBtn">×</button>
            </div>

            <div class="ai-agent-body">
                <!-- 消息区域 -->
                <div class="ai-agent-messages" id="aiAgentMessages">
                    <div class="ai-agent-welcome">
                        <div class="ai-agent-welcome-title">👋 你好！我是易小采</div>
                        <div class="ai-agent-welcome-subtitle">易采贸易平台智能助手</div>
                        <div class="ai-agent-welcome-text">
                            我可以帮你：
                            <ul>
                                <li>搜索产品和供应商</li>
                                <li>创建反向竞拍</li>
                                <li>查看订单状态</li>
                                <li>计算采购成本</li>
                                <li>导航到平台功能页面</li>
                                <li>解释平台功能使用方法</li>
                            </ul>
                            <div class="ai-agent-current-page">
                                当前页面：<strong>${pageName}</strong>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 工具面板 -->
                <div class="ai-agent-tools-panel" id="aiAgentToolsPanel">
                    <div class="ai-agent-tools-header">
                        <span>📋 快捷工具</span>
                        <button class="ai-agent-tools-toggle" id="aiAgentToolsToggle">收起</button>
                    </div>
                    <div class="ai-agent-tools-grid" id="aiAgentToolsGrid">
                        <!-- 工具按钮将通过JavaScript动态加载 -->
                    </div>
                </div>

                <!-- 输入区域 -->
                <div class="ai-agent-input-area">
                    <div class="ai-agent-input-wrapper">
                        <textarea class="ai-agent-input" id="aiAgentInput" placeholder="输入您的问题或需求... (支持上传图片和文件)" rows="1"></textarea>
                        <div class="ai-agent-input-actions">
                            <button class="ai-agent-action-btn" id="aiAgentUploadBtn" title="上传文件">
                                📎
                            </button>
                            <input type="file" id="aiAgentFileInput" multiple style="display:none;" accept="image/*,.pdf,.doc,.docx,.xls,.xlsx,.txt,.csv">
                        </div>
                    </div>
                    <button class="ai-agent-send-btn" id="aiAgentSendBtn" title="发送">
                        <svg viewBox="0 0 24 24" width="20" height="20">
                            <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
                        </svg>
                    </button>
                </div>
            </div>

            <!-- 打字指示器 -->
            <div class="ai-agent-typing" id="aiAgentTyping" style="display:none;">
                <div class="ai-agent-typing-dots">
                    <div class="ai-agent-typing-dot"></div>
                    <div class="ai-agent-typing-dot"></div>
                    <div class="ai-agent-typing-dot"></div>
                </div>
                <div class="ai-agent-typing-text" id="aiAgentTypingText">正在思考...</div>
            </div>
        `;
    }

    // ==================== 核心功能 ====================

    function sendAgentMessage() {
        var input = document.getElementById('aiAgentInput');
        var message = input.value.trim();
        
        if (!message && pendingFiles.length === 0) return;
        
        // 显示用户消息
        if (message) appendUserMessage(message);
        
        // 清空输入框
        input.value = '';
        input.style.height = 'auto';
        
        // 显示打字指示器
        showAgentTyping();
        
        // 发送请求
        lastSentText = message;
        startResponseTimeout();
        
        var hasFiles = pendingFiles.length > 0;
        var currentSessionId = httpSessionId || generateSessionId();
        httpSessionId = currentSessionId;
        
        var fetchPromise;
        
        if (hasFiles) {
            // 有文件时用 multipart 发到 /message-with-files
            var requestData = {
                message: message,
                currentPage: window.location.pathname + window.location.search,
                sessionId: currentSessionId,
                files: pendingFiles.map(function(f) { return { name: f.name, type: f.type, size: f.size }; })
            };
            var formData = new FormData();
            formData.append('request', JSON.stringify(requestData));
            pendingFiles.forEach(function(file) {
                formData.append('files', file);
            });
            fetchPromise = fetch(API_BASE + '/message-with-files', {
                method: 'POST',
                body: formData
            });
        } else {
            // 普通消息用 JSON
            fetchPromise = fetch(AGENT_API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: message,
                    currentPage: window.location.pathname + window.location.search,
                    sessionId: currentSessionId
                })
            });
        }
        
        fetchPromise
        .then(function(response) {
            if (!response.ok) throw new Error('HTTP ' + response.status);
            return response.json();
        })
        .then(function(data) {
            clearResponseTimeout();
            removeAgentTyping();
            handleAgentResponse(data);
            if (data.sessionId) httpSessionId = data.sessionId;
            pendingFiles = [];
        })
        .catch(function(error) {
            clearResponseTimeout();
            removeAgentTyping();
            appendError('请求失败: ' + error.message);
            console.error('Agent request error:', error);
        });
    }

    function handleAgentResponse(data) {
        if (!data) { appendAgentMessage('收到空回复'); return; }
        var type = data.type || 'text';
        if (type === 'tool_result' || type === 'product_list' || type === 'factory_list' ||
            type === 'auction_created' || type === 'cost_calculation' || type === 'order_status') {
            displayToolResult(data);
        } else if (type === 'navigation') {
            handleNavigation(data);
        } else if (type === 'error') {
            appendError(data.message || '处理出错');
        } else {
            appendAgentMessage(data.message || '收到回复');
        }
    }

    function handleNavigation(data) {
        var nav = data.navigation;
        var targetUrl = nav ? nav.targetUrl : null;
        var description = data.message || (nav ? nav.description : '');
        if (description) appendAgentMessage(description);
        if (targetUrl) {
            var openNew = nav && nav.openInNewTab;
            if (openNew) {
                window.open(targetUrl, '_blank');
            } else {
                setTimeout(function() { window.location.href = targetUrl; }, 1500);
            }
        }
    }

    function executeTool(toolName, params) {
        showAgentTyping();
        
        var requestData = {
            message: `执行工具: ${toolName}`,
            currentPage: window.location.pathname + window.location.search,
            sessionId: httpSessionId || generateSessionId(),
            toolCall: {
                name: toolName,
                arguments: params
            }
        };
        
        fetch(AGENT_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestData)
        })
        .then(function(response) {
            if (!response.ok) throw new Error('HTTP ' + response.status);
            return response.json();
        })
        .then(function(data) {
            removeAgentTyping();
            displayToolResult(data);
        })
        .catch(function(error) {
            removeAgentTyping();
            appendError('工具执行失败: ' + error.message);
        });
    }

    function executeQuickAction(action) {
        var messages = {
            'search_product': '帮我搜索产品',
            'create_auction': '如何创建反向竞拍？',
            'check_order': '查看我的订单状态',
            'calculate_cost': '计算采购成本',
            'find_supplier': '寻找供应商',
            'explain_feature': '解释这个功能怎么用'
        };
        
        var input = document.getElementById('aiAgentInput');
        input.value = messages[action] || action;
        sendAgentMessage();
    }

    // ==================== 工具管理 ====================

    function loadAvailableTools() {
        fetch(AGENT_TOOLS_URL)
        .then(function(response) {
            if (!response.ok) throw new Error('HTTP ' + response.status);
            return response.json();
        })
        .then(function(tools) {
            renderTools(tools);
        })
        .catch(function(error) {
            console.warn('无法加载工具列表:', error);
            renderDefaultTools();
        });
    }

    function renderTools(tools) {
        var toolsGrid = document.getElementById('aiAgentToolsGrid');
        if (!toolsGrid) return;
        
        var html = '';
        
        tools.forEach(function(tool) {
            html += `
                <button class="ai-agent-tool-btn" data-tool="${tool.name}" data-params='${JSON.stringify(tool.defaultParams || {})}'>
                    <div class="ai-agent-tool-icon">${tool.icon || '🔧'}</div>
                    <div class="ai-agent-tool-name">${tool.displayName || tool.name}</div>
                    <div class="ai-agent-tool-desc">${tool.description || ''}</div>
                </button>
            `;
        });
        
        toolsGrid.innerHTML = html;
        
        // 重新绑定事件
        var toolBtns = document.querySelectorAll('.ai-agent-tool-btn');
        for (var i = 0; i < toolBtns.length; i++) {
            toolBtns[i].onclick = function() {
                var tool = this.getAttribute('data-tool');
                var params = this.getAttribute('data-params');
                executeTool(tool, params ? JSON.parse(params) : {});
            };
        }
    }

    function renderDefaultTools() {
        var defaultTools = [
            { name: 'search_products', displayName: '搜索产品', icon: '🔍', description: '按关键词搜索产品' },
            { name: 'match_factories', displayName: '匹配工厂', icon: '🏭', description: '智能匹配供应商' },
            { name: 'create_reverse_auction', displayName: '创建竞拍', icon: '💰', description: '发布反向竞拍需求' },
            { name: 'calculate_cost', displayName: '成本计算', icon: '🧮', description: '计算采购总成本' },
            { name: 'check_order_status', displayName: '订单状态', icon: '📦', description: '查看订单进度' },
            { name: 'navigate_page', displayName: '页面导航', icon: '🧭', description: '跳转到功能页面' }
        ];
        
        renderTools(defaultTools);
    }

    // ==================== 结果显示 ====================

    function displayToolResult(data) {
        var messages = document.getElementById('aiAgentMessages');
        
        // 创建工具结果容器
        var resultDiv = document.createElement('div');
        resultDiv.className = 'ai-agent-tool-result';
        
        var resultHTML = `
            <div class="ai-agent-tool-result-header">
                <div class="ai-agent-tool-result-icon">🔧</div>
                <div class="ai-agent-tool-result-title">工具执行结果</div>
            </div>
            <div class="ai-agent-tool-result-content">
        `;
        
        if (data.type === 'product_list') {
            resultHTML += renderProductList(data.data);
        } else if (data.type === 'factory_list') {
            resultHTML += renderFactoryList(data.data);
        } else if (data.type === 'auction_created') {
            resultHTML += renderAuctionCreated(data.data);
        } else if (data.type === 'cost_calculation') {
            resultHTML += renderCostCalculation(data.data);
        } else if (data.type === 'order_status') {
            resultHTML += renderOrderStatus(data.data);
        } else {
            resultHTML += `<div class="ai-agent-tool-result-text">${data.message || '操作完成'}</div>`;
        }
        
        resultHTML += '</div>';
        
        // 如果有额外数据
        if (data.extra) {
            resultHTML += `
                <div class="ai-agent-tool-result-extra">
                    <div class="ai-agent-tool-result-extra-title">详细信息</div>
                    <pre class="ai-agent-tool-result-extra-content">${JSON.stringify(data.extra, null, 2)}</pre>
                </div>
            `;
        }
        
        resultDiv.innerHTML = resultHTML;
        messages.appendChild(resultDiv);
        scrollToBottom();
        
        // 添加AI的总结回复
        if (data.message) {
            setTimeout(function() {
                appendAgentMessage(data.message);
            }, 500);
        }
    }

    function renderProductList(products) {
        if (!products || products.length === 0) {
            return '<div class="ai-agent-no-results">未找到相关产品</div>';
        }
        
        var html = '<div class="ai-agent-product-list">';
        
        products.forEach(function(product) {
            html += `
                <div class="ai-agent-product-item">
                    <div class="ai-agent-product-name">${product.name || '未命名产品'}</div>
                    <div class="ai-agent-product-details">
                        <span class="ai-agent-product-category">${product.category || '未分类'}</span>
                        <span class="ai-agent-product-moq">MOQ: ${product.minOrder || 0}</span>
                        <span class="ai-agent-product-price">${product.priceRange || '价格面议'}</span>
                    </div>
                    <div class="ai-agent-product-supplier">
                        <span class="ai-agent-product-rating">⭐ ${product.rating || 0}</span>
                        <span class="ai-agent-product-supplier-name">${product.supplier || '未知供应商'}</span>
                    </div>
                    <button class="ai-agent-product-action" onclick="window.location.href='/smart-match.html?product=${encodeURIComponent(product.name)}'">
                        查看详情
                    </button>
                </div>
            `;
        });
        
        html += '</div>';
        return html;
    }

    function renderFactoryList(factories) {
        if (!factories || factories.length === 0) {
            return '<div class="ai-agent-no-results">未找到匹配的供应商</div>';
        }
        var html = '<div class="ai-agent-product-list">';
        factories.forEach(function(factory) {
            var verified = factory.verified ? '<span style="color:#10b981;font-weight:600;">&#10003; 已认证</span>' : '<span style="color:#9ca3af;">未认证</span>';
            html += '<div class="ai-agent-product-item">' +
                '<div class="ai-agent-product-name">' + escapeHtml(factory.name || '未知供应商') + '</div>' +
                '<div class="ai-agent-product-details">' +
                    '<span class="ai-agent-product-category">' + escapeHtml(factory.location || '未知地区') + '</span>' +
                    '<span class="ai-agent-product-moq">' + escapeHtml(factory.mainProducts || '综合') + '</span>' +
                    '<span class="ai-agent-product-price">' + verified + '</span>' +
                '</div>' +
                '<div class="ai-agent-product-supplier">' +
                    '<span class="ai-agent-product-rating">&#11088; ' + (factory.rating || 0) + '</span>' +
                    '<span>' + escapeHtml(factory.capacity || '') + '</span>' +
                '</div>' +
                '<button class="ai-agent-product-action" onclick="window.location.href=\'/smart-match.html?supplier=' + encodeURIComponent(factory.name || '') + '\'">查看详情</button>' +
            '</div>';
        });
        html += '</div>';
        return html;
    }

    function renderAuctionCreated(data) {
        if (!data) return '<div class="ai-agent-no-results">竞价创建信息不可用</div>';
        var info = Array.isArray(data) ? data[0] || {} : data;
        return '<div style="padding:8px 0;">' +
            '<div style="font-weight:600;font-size:15px;margin-bottom:12px;color:#10b981;">&#10003; 反向竞价已创建</div>' +
            '<div style="display:grid;grid-template-columns:auto 1fr;gap:8px 16px;font-size:13px;">' +
                '<span style="color:#6b7280;">竞价编号:</span><span style="font-weight:500;">' + escapeHtml(info.auctionId || info.id || 'N/A') + '</span>' +
                '<span style="color:#6b7280;">产品名称:</span><span>' + escapeHtml(info.productName || info.title || 'N/A') + '</span>' +
                '<span style="color:#6b7280;">目标数量:</span><span>' + escapeHtml(String(info.quantity || 'N/A')) + '</span>' +
                '<span style="color:#6b7280;">起始价格:</span><span style="color:#ef4444;font-weight:600;">' + escapeHtml(info.startingPrice || info.price || 'N/A') + '</span>' +
                '<span style="color:#6b7280;">截止时间:</span><span>' + escapeHtml(info.deadline || info.endTime || 'N/A') + '</span>' +
                '<span style="color:#6b7280;">状态:</span><span style="color:#667eea;font-weight:500;">' + escapeHtml(info.status || '进行中') + '</span>' +
            '</div>' +
            '<button class="ai-agent-product-action" style="margin-top:12px;" onclick="window.location.href=\'/auction-detail.html?id=' + encodeURIComponent(info.auctionId || info.id || '') + '\'">查看竞价详情</button>' +
        '</div>';
    }

    function renderCostCalculation(data) {
        if (!data) return '<div class="ai-agent-no-results">成本计算数据不可用</div>';
        var info = Array.isArray(data) ? data[0] || {} : data;
        var items = [
            { label: '产品单价', value: info.unitPrice || 'N/A', color: '' },
            { label: '采购数量', value: info.quantity || 'N/A', color: '' },
            { label: '产品小计', value: info.subtotal || 'N/A', color: '' },
            { label: '运费', value: info.shippingCost || info.shipping || 'N/A', color: '' },
            { label: '平台服务费 (2%)', value: info.serviceFee || 'N/A', color: '' },
            { label: '关税/税费', value: info.tax || info.tariff || 'N/A', color: '' }
        ];
        var html = '<div style="padding:8px 0;">' +
            '<div style="font-weight:600;font-size:15px;margin-bottom:12px;">&#129518; 采购成本估算</div>' +
            '<table style="width:100%;font-size:13px;border-collapse:collapse;">';
        items.forEach(function(item) {
            html += '<tr style="border-bottom:1px solid #f3f4f6;">' +
                '<td style="padding:8px 4px;color:#6b7280;">' + item.label + '</td>' +
                '<td style="padding:8px 4px;text-align:right;font-weight:500;">' + escapeHtml(String(item.value)) + '</td></tr>';
        });
        html += '<tr style="border-top:2px solid #e5e7eb;">' +
            '<td style="padding:10px 4px;font-weight:700;font-size:14px;">总计</td>' +
            '<td style="padding:10px 4px;text-align:right;font-weight:700;font-size:16px;color:#ef4444;">' + escapeHtml(String(info.totalCost || info.total || 'N/A')) + '</td></tr>';
        html += '</table></div>';
        return html;
    }

    function renderOrderStatus(data) {
        if (!data) return '<div class="ai-agent-no-results">订单信息不可用</div>';
        var orders = Array.isArray(data) ? data : [data];
        var statusColors = {
            'pending': '#f59e0b', 'confirmed': '#3b82f6', 'production': '#8b5cf6',
            'quality_check': '#6366f1', 'shipped': '#0ea5e9', 'completed': '#10b981',
            'cancelled': '#ef4444'
        };
        var statusLabels = {
            'pending': '待确认', 'confirmed': '已确认', 'production': '生产中',
            'quality_check': '质检中', 'shipped': '已发货', 'completed': '已完成',
            'cancelled': '已取消'
        };
        var html = '<div style="padding:8px 0;">';
        orders.forEach(function(order) {
            var st = order.status || 'pending';
            var color = statusColors[st] || '#6b7280';
            var label = statusLabels[st] || escapeHtml(st);
            html += '<div style="padding:12px;border:1px solid #e5e7eb;border-radius:8px;margin-bottom:8px;">' +
                '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">' +
                    '<span style="font-weight:600;">' + escapeHtml(order.orderId || order.id || 'N/A') + '</span>' +
                    '<span style="background:' + color + ';color:white;padding:2px 10px;border-radius:12px;font-size:12px;">' + label + '</span>' +
                '</div>' +
                '<div style="font-size:13px;color:#6b7280;">' +
                    '<div>' + escapeHtml(order.productName || order.product || '') + '</div>' +
                    '<div style="display:flex;justify-content:space-between;margin-top:4px;">' +
                        '<span>数量: ' + escapeHtml(String(order.quantity || '')) + '</span>' +
                        '<span>金额: ' + escapeHtml(String(order.amount || order.totalAmount || '')) + '</span>' +
                    '</div>' +
                '</div>' +
                '<button class="ai-agent-product-action" style="margin-top:8px;font-size:12px;padding:6px 12px;" onclick="window.location.href=\'/order-detail.html?id=' + encodeURIComponent(order.orderId || order.id || '') + '\'">查看详情</button>' +
            '</div>';
        });
        html += '</div>';
        return html;
    }

    // ==================== 辅助函数 ====================

    function checkAgentHealth() {
        fetch(AGENT_HEALTH_URL)
        .then(function (res) {
            if (res.ok) updateAgentStatus('在线', 'online');
            else updateAgentStatus('服务异常', 'offline');
        })
        .catch(function () {
            updateAgentStatus('离线', 'offline');
        });
    }

    function updateAgentStatus(text, status) {
        var statusEl = document.getElementById('aiAgentStatus');
        if (statusEl) {
            statusEl.textContent = text;
            statusEl.className = 'ai-agent-status ai-agent-status-' + status;
        }
    }

    function generateSessionId() {
        return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    function getCurrentPage() {
        return window.location.pathname + window.location.search;
    }

    function appendUserMessage(text) {
        var messages = document.getElementById('aiAgentMessages');
        var div = document.createElement('div');
        div.className = 'ai-agent-msg user';
        div.innerHTML = `
            <div class="ai-agent-msg-avatar">👤</div>
            <div class="ai-agent-msg-bubble">${escapeHtml(text)}</div>
        `;
        messages.appendChild(div);
        scrollToBottom();
    }

    function appendAgentMessage(text) {
        var messages = document.getElementById('aiAgentMessages');
        var div = document.createElement('div');
        div.className = 'ai-agent-msg agent';
        div.innerHTML = `
            <div class="ai-agent-msg-avatar">AI</div>
            <div class="ai-agent-msg-bubble">${escapeHtml(text)}</div>
        `;
        messages.appendChild(div);
        scrollToBottom();
    }

    function appendError(text) {
        var messages = document.getElementById('aiAgentMessages');
        var div = document.createElement('div');
        div.className = 'ai-agent-msg error';
        div.innerHTML = `
            <div class="ai-agent-msg-avatar">⚠️</div>
            <div class="ai-agent-msg-bubble">${escapeHtml(text)}</div>
        `;
        messages.appendChild(div);
        scrollToBottom();
    }

    function showAgentTyping() {
        var typing = document.getElementById('aiAgentTyping');
        if (typing) typing.style.display = 'flex';
    }

    function removeAgentTyping() {
        var typing = document.getElementById('aiAgentTyping');
        if (typing) typing.style.display = 'none';
    }

    function toggleAgent() {
        var win = document.getElementById('aiAgentWindow');
        var fab = document.getElementById('aiAgentFab');
        
        if (win.classList.contains('ai-agent-window-open')) {
            win.classList.remove('ai-agent-window-open');
            fab.classList.remove('ai-agent-fab-active');
        } else {
            win.classList.add('ai-agent-window-open');
            fab.classList.add('ai-agent-fab-active');
            // 自动聚焦输入框
            setTimeout(function() {
                var input = document.getElementById('aiAgentInput');
                if (input) input.focus();
            }, 100);
        }
    }

    function scrollToBottom() {
        var messages = document.getElementById('aiAgentMessages');
        if (messages) {
            messages.scrollTop = messages.scrollHeight;
        }
    }

    function escapeHtml(text) {
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // ==================== 文件处理 ====================

    function handleFileSelect(event) {
        var files = event.target.files;
        if (files.length > 0) {
            addFiles(files);
        }
        // 重置文件输入
        event.target.value = '';
    }

    function addFiles(files) {
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            
            // 检查文件大小
            if (file.size > MAX_FILE_SIZE) {
                alert('文件 "' + file.name + '" 超过最大限制 ' + (MAX_FILE_SIZE / 1024 / 1024) + 'MB');
                continue;
            }
            
            // 检查文件类型
            var isValid = false;
            if (file.type.startsWith('image/')) {
                isValid = ALLOWED_IMAGE_TYPES.includes(file.type);
            } else {
                var ext = '.' + file.name.split('.').pop().toLowerCase();
                isValid = ALLOWED_FILE_EXTS.includes(ext);
            }
            
            if (!isValid) {
                alert('不支持的文件类型: ' + file.name);
                continue;
            }
            
            // 检查文件数量
            if (pendingFiles.length >= MAX_FILES) {
                alert('最多只能上传 ' + MAX_FILES + ' 个文件');
                break;
            }
            
            pendingFiles.push(file);
            appendFileMessage(file);
        }
    }

    function appendFileMessage(file) {
        var messages = document.getElementById('aiAgentMessages');
        var div = document.createElement('div');
        div.className = 'ai-agent-msg user';
        
        var fileSize = (file.size / 1024).toFixed(1);
        var fileType = file.type.startsWith('image/') ? '图片' : '文件';
        
        div.innerHTML = `
            <div class="ai-agent-msg-avatar">📎</div>
            <div class="ai-agent-msg-bubble ai-agent-file-bubble">
                <div class="ai-agent-file-name">${escapeHtml(file.name)}</div>
                <div class="ai-agent-file-info">${fileType} • ${fileSize} KB</div>
            </div>
        `;
        
        messages.appendChild(div);
        scrollToBottom();
    }

    // ==================== 响应超时和进度 ====================

    var PROGRESS_STAGES = [
        { time: 0,  text: '正在连接AI...' },
        { time: 2,  text: '正在分析您的需求...' },
        { time: 5,  text: '正在调用相关工具...' },
        { time: 10, text: '正在处理数据...' },
        { time: 15, text: '正在生成回复...' },
        { time: 25, text: '内容较多，请稍候...' },
        { time: 35, text: '即将完成...' }
    ];

    function startResponseTimeout() {
        clearResponseTimeout();
        responseStartTime = Date.now();

        progressTimer = setInterval(function () {
            var elapsed = Math.floor((Date.now() - responseStartTime) / 1000);
            var stageText = PROGRESS_STAGES[0].text;
            for (var i = PROGRESS_STAGES.length - 1; i >= 0; i--) {
                if (elapsed >= PROGRESS_STAGES[i].time) {
                    stageText = PROGRESS_STAGES[i].text;
                    break;
                }
            }
            updateProgressText(stageText + ' (' + elapsed + 's)');
        }, 1000);

        responseTimer = setTimeout(function () {
            clearResponseTimeout();
            removeAgentTyping();
            appendTimeoutMsg();
        }, RESPONSE_TIMEOUT);
    }

    function clearResponseTimeout() {
        clearTimeout(responseTimer);
        responseTimer = null;
        clearInterval(progressTimer);
        progressTimer = null;
    }

    function updateProgressText(text) {
        var el = document.getElementById('aiAgentTypingText');
        if (el) el.textContent = text;
    }

    function appendTimeoutMsg() {
        var messages = document.getElementById('aiAgentMessages');
        var div = document.createElement('div');
        div.className = 'ai-agent-msg agent';
        div.innerHTML = `
            <div class="ai-agent-msg-avatar">AI</div>
            <div class="ai-agent-msg-bubble ai-agent-timeout-bubble">
                <div>⏱️ AI响应超时，可能服务繁忙或处理复杂请求。</div>
                <button class="ai-agent-retry-btn" onclick="retryLastMessage()">重新发送</button>
            </div>
        `;
        messages.appendChild(div);
        scrollToBottom();
    }

    // ==================== 全局函数 ====================

    window.retryLastMessage = function() {
        if (lastSentText) {
            var input = document.getElementById('aiAgentInput');
            input.value = lastSentText;
            sendAgentMessage();
        }
    };

    window.toggleAgentWindow = toggleAgent;

    // ==================== 初始化 ====================

    function initEnhanced() {
        // 用 CSS 隐藏原版元素防止闪烁（在增强版创建前立即执行）
        var style = document.createElement('style');
        style.textContent = '#aiChatFab, #aiChatWindow { display: none !important; }';
        document.head.appendChild(style);
        createEnhancedWidget();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initEnhanced);
    } else {
        initEnhanced();
    }

})();