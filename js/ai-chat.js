/**
 * AI Chat Widget - 易采贸易平台
 * 智能助手「易小采」- 基于 DeepSeek 大模型
 */
(function () {
    'use strict';

    // ==================== Config ====================
    var HTTP_API_URL = (function() {
        var port = window.location.port;
        if (!port || port === '80' || port === '443' || port === '8081') return '/api/ai-chat/message';
        return 'http://' + window.location.hostname + ':8081/api/ai-chat/message';
    })();
    var RESPONSE_TIMEOUT = 30000;     // 30s for AI to respond
    var responseTimer = null;
    var responseStartTime = 0;
    var progressTimer = null;
    var lastSentText = '';
    var httpSessionId = null;

    // File upload state
    var pendingFiles = [];
    var ALLOWED_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/bmp'];
    var ALLOWED_FILE_EXTS = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv', '.zip', '.rar'];
    var MAX_FILE_SIZE = 10 * 1024 * 1024;
    var MAX_FILES = 5;

    // ==================== DOM Creation ====================

    function createWidget() {
        var fab = document.createElement('div');
        fab.className = 'ai-chat-fab';
        fab.id = 'aiChatFab';
        fab.innerHTML = '<div class="ai-fab-pulse"></div>' +
            '<svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12c0 1.54.36 3 1 4.32L2 22l5.68-1C9 21.64 10.46 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm-1 14h-1.5v-1.5H11V16zm2.07-4.75l-.9.92C11.45 12.9 11 13.5 11 15h-1.5v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-1.93 1.57-3.5 3.5-3.5S14 7.07 14 9c0 .88-.36 1.68-.93 2.25z"/></svg>';
        fab.title = '易小采 AI助手';
        fab.onclick = toggleChat;

        var win = document.createElement('div');
        win.className = 'ai-chat-window';
        win.id = 'aiChatWindow';
        win.innerHTML = buildWindowHTML();

        document.body.appendChild(fab);
        document.body.appendChild(win);

        document.getElementById('aiChatCloseBtn').onclick = toggleChat;
        document.getElementById('aiChatSendBtn').onclick = sendMessage;
        document.getElementById('aiChatInput').onkeydown = function (e) {
            if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
        };
        document.getElementById('aiChatUploadBtn').onclick = function () {
            document.getElementById('aiFileInput').click();
        };
        document.getElementById('aiFileInput').onchange = handleFileSelect;

        // Drag-and-drop
        var msgArea = document.getElementById('aiChatMessages');
        msgArea.ondragover = function (e) { e.preventDefault(); e.stopPropagation(); msgArea.classList.add('ai-drag-over'); };
        msgArea.ondragleave = function (e) { e.preventDefault(); e.stopPropagation(); msgArea.classList.remove('ai-drag-over'); };
        msgArea.ondrop = function (e) {
            e.preventDefault(); e.stopPropagation();
            msgArea.classList.remove('ai-drag-over');
            if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) addFiles(e.dataTransfer.files);
        };

        var qbtns = document.querySelectorAll('.ai-quick-btn');
        for (var i = 0; i < qbtns.length; i++) {
            qbtns[i].onclick = function () {
                document.getElementById('aiChatInput').value = this.getAttribute('data-msg');
                sendMessage();
            };
        }

        // Check backend health
        checkHealth();
    }

    function checkHealth() {
        fetch(HTTP_API_URL.replace('/message', '/health'))
        .then(function (res) {
            if (res.ok) updateStatus('在线', 'online');
            else updateStatus('服务异常', 'offline');
        })
        .catch(function () {
            updateStatus('离线', 'offline');
        });
    }

    function getPageQuickActions() {
        var page = getCurrentPage();
        if (page.indexOf('smart-match') >= 0) {
            return '<button class="ai-quick-btn" data-msg="如何使用智能匹配？">如何匹配</button>' +
                '<button class="ai-quick-btn" data-msg="帮我找陶瓷杯的供应商">找供应商</button>' +
                '<button class="ai-quick-btn" data-msg="匹配后怎么签合同？">签合同</button>' +
                '<button class="ai-quick-btn" data-msg="平台收费标准是什么？">收费标准</button>';
        }
        if (page.indexOf('auction') >= 0) {
            return '<button class="ai-quick-btn" data-msg="如何发布反向竞价？">发布竞价</button>' +
                '<button class="ai-quick-btn" data-msg="竞价和直接采购有什么区别？">竞价 vs 采购</button>' +
                '<button class="ai-quick-btn" data-msg="帮我创建一个采购竞价">创建竞价</button>' +
                '<button class="ai-quick-btn" data-msg="如何查看竞价进度？">竞价进度</button>';
        }
        if (page.indexOf('order') >= 0) {
            return '<button class="ai-quick-btn" data-msg="如何查看订单状态？">查看状态</button>' +
                '<button class="ai-quick-btn" data-msg="订单可以取消吗？">取消订单</button>' +
                '<button class="ai-quick-btn" data-msg="如何确认收货？">确认收货</button>' +
                '<button class="ai-quick-btn" data-msg="订单物流信息在哪看？">查物流</button>';
        }
        if (page.indexOf('contract') >= 0) {
            return '<button class="ai-quick-btn" data-msg="三种合同模板有什么区别？">模板区别</button>' +
                '<button class="ai-quick-btn" data-msg="可以上传自己的合同吗？">自定义合同</button>' +
                '<button class="ai-quick-btn" data-msg="平台服务费怎么算？">服务费</button>' +
                '<button class="ai-quick-btn" data-msg="合同签署后如何付款？">付款方式</button>';
        }
        if (page.indexOf('supplier-center') >= 0 || page.indexOf('merchant') >= 0) {
            return '<button class="ai-quick-btn" data-msg="如何管理我的产品？">管理产品</button>' +
                '<button class="ai-quick-btn" data-msg="如何查看供应商订单？">查看订单</button>' +
                '<button class="ai-quick-btn" data-msg="如何提高供应商评分？">提高评分</button>' +
                '<button class="ai-quick-btn" data-msg="如何参与竞价报价？">参与竞价</button>';
        }
        if (page.indexOf('supplier-apply') >= 0) {
            return '<button class="ai-quick-btn" data-msg="供应商入驻需要什么条件？">入驻条件</button>' +
                '<button class="ai-quick-btn" data-msg="入驻审核需要多久？">审核时间</button>' +
                '<button class="ai-quick-btn" data-msg="需要准备哪些资料？">准备资料</button>' +
                '<button class="ai-quick-btn" data-msg="入驻后有什么费用？">入驻费用</button>';
        }
        if (page.indexOf('production') >= 0 || page.indexOf('monitor') >= 0) {
            return '<button class="ai-quick-btn" data-msg="如何查看生产进度？">查看进度</button>' +
                '<button class="ai-quick-btn" data-msg="如何设置生产预警？">设置预警</button>' +
                '<button class="ai-quick-btn" data-msg="质检不合格怎么处理？">质检处理</button>' +
                '<button class="ai-quick-btn" data-msg="生产监控有哪些环节？">监控环节</button>';
        }
        return '<button class="ai-quick-btn" data-msg="平台有哪些功能？">平台功能</button>' +
            '<button class="ai-quick-btn" data-msg="帮我搜索陶瓷杯产品">搜索产品</button>' +
            '<button class="ai-quick-btn" data-msg="如何开始智能匹配采购？">智能匹配</button>' +
            '<button class="ai-quick-btn" data-msg="如何发布反向竞价？">发布竞价</button>';
    }

    function buildWindowHTML() {
        return '' +
            '<div class="ai-chat-header">' +
            '  <svg class="ai-chat-header-icon" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12c0 1.54.36 3 1 4.32L2 22l5.68-1C9 21.64 10.46 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm-1 14h-1.5v-1.5H11V16zm2.07-4.75l-.9.92C11.45 12.9 11 13.5 11 15h-1.5v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-1.93 1.57-3.5 3.5-3.5S14 7.07 14 9c0 .88-.36 1.68-.93 2.25z"/></svg>' +
            '  <span class="ai-chat-header-title">易小采 AI助手</span>' +
            '  <span class="ai-chat-header-status" id="aiChatStatus">检测中...</span>' +
            '  <button class="ai-chat-close-btn" id="aiChatCloseBtn">&times;</button>' +
            '</div>' +
            '<div class="ai-chat-messages" id="aiChatMessages">' +
            '  <div class="ai-welcome">' +
            '    <div class="ai-welcome-icon"><svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12c0 1.54.36 3 1 4.32L2 22l5.68-1C9 21.64 10.46 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm-1 14h-1.5v-1.5H11V16zm2.07-4.75l-.9.92C11.45 12.9 11 13.5 11 15h-1.5v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-1.93 1.57-3.5 3.5-3.5S14 7.07 14 9c0 .88-.36 1.68-.93 2.25z"/></svg></div>' +
            '    <h3>你好！我是易小采</h3>' +
            '    <p>易采贸易平台AI助手，基于DeepSeek大模型。可以帮你搜索产品、匹配供应商、计算成本、管理竞价和订单，还能指引你使用平台各项功能。</p>' +
            '    <div class="ai-quick-actions">' + getPageQuickActions() + '</div>' +
            '  </div>' +
            '</div>' +
            '<div class="ai-chat-upload-preview" id="aiUploadPreview" style="display:none;"></div>' +
            '<div class="ai-chat-input-area">' +
            '  <input type="file" id="aiFileInput" multiple style="display:none;" accept="image/*,.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.csv,.zip,.rar"/>' +
            '  <button class="ai-chat-upload-btn" id="aiChatUploadBtn" title="上传图片/文件">' +
            '    <svg viewBox="0 0 24 24"><path d="M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.04 2.46 5.5 5.5 5.5s5.5-2.46 5.5-5.5V6h-1.5z"/></svg>' +
            '  </button>' +
            '  <input class="ai-chat-input" id="aiChatInput" type="text" placeholder="输入您的问题..." autocomplete="off"/>' +
            '  <button class="ai-chat-send-btn" id="aiChatSendBtn">' +
            '    <svg viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/></svg>' +
            '  </button>' +
            '</div>';
    }

    // ==================== HTTP API ====================

    function doSendHTTP(text) {
        startResponseTimeout();

        fetch(HTTP_API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                sessionId: httpSessionId,
                message: text,
                currentPage: getCurrentPage()
            })
        })
        .then(function (res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function (resp) {
            clearResponseTimeout();
            removeTyping();
            if (resp.sessionId) httpSessionId = resp.sessionId;
            appendBotMsg(resp.message || '');
            enableInput();
            updateStatus('在线', 'online');
        })
        .catch(function (err) {
            clearResponseTimeout();
            removeTyping();
            console.error('[AI Chat] error:', err);
            appendErrorMsg('连接AI服务失败，请确认后端服务已启动。');
            enableInput();
            updateStatus('异常', 'offline');
        });
    }

    // ==================== Response Timeout & Progress ====================

    var PROGRESS_STAGES = [
        { time: 0,  text: '正在连接AI...' },
        { time: 2,  text: '正在分析您的需求...' },
        { time: 5,  text: '正在生成回复...' },
        { time: 12, text: '内容较多，请稍候...' },
        { time: 20, text: '即将完成...' }
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
            removeTyping();
            appendTimeoutMsg();
            enableInput();
        }, RESPONSE_TIMEOUT);
    }

    function clearResponseTimeout() {
        clearTimeout(responseTimer);
        responseTimer = null;
        clearInterval(progressTimer);
        progressTimer = null;
    }

    function updateProgressText(text) {
        var el = document.getElementById('aiTypingText');
        if (el) el.textContent = text;
    }

    function appendTimeoutMsg() {
        var msgs = document.getElementById('aiChatMessages');
        var div = document.createElement('div');
        div.className = 'ai-msg bot';
        var retryId = 'aiRetry_' + Date.now();
        div.innerHTML = '<div class="ai-msg-avatar">AI</div>' +
            '<div class="ai-msg-bubble ai-timeout-bubble">' +
            '<div><svg viewBox="0 0 24 24" width="18" height="18" style="vertical-align:middle;margin-right:4px;"><path fill="#f59e0b" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>AI响应超时，可能服务繁忙，请重试。</div>' +
            '<button class="ai-retry-btn" id="' + retryId + '">重新发送</button>' +
            '</div>';
        msgs.appendChild(div);
        scrollToBottom();
        document.getElementById(retryId).onclick = function () {
            div.remove();
            if (lastSentText) { showTyping(); disableInput(); doSendHTTP(lastSentText); }
        };
    }

    function appendErrorMsg(text) {
        var msgs = document.getElementById('aiChatMessages');
        var div = document.createElement('div');
        div.className = 'ai-msg bot';
        var retryId = 'aiRetry_' + Date.now();
        div.innerHTML = '<div class="ai-msg-avatar">AI</div>' +
            '<div class="ai-msg-bubble ai-error-bubble">' +
            '<div><svg viewBox="0 0 24 24" width="18" height="18" style="vertical-align:middle;margin-right:4px;"><path fill="#ef4444" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>' + escapeHtml(text) + '</div>' +
            '<button class="ai-retry-btn" id="' + retryId + '">重新发送</button>' +
            '</div>';
        msgs.appendChild(div);
        scrollToBottom();
        document.getElementById(retryId).onclick = function () {
            div.remove();
            if (lastSentText) { showTyping(); disableInput(); doSendHTTP(lastSentText); }
        };
    }

    function enableInput() {
        var btn = document.getElementById('aiChatSendBtn');
        if (btn) btn.disabled = false;
    }

    function disableInput() {
        var btn = document.getElementById('aiChatSendBtn');
        if (btn) btn.disabled = true;
    }

    // ==================== Toggle ====================

    function toggleChat() {
        var win = document.getElementById('aiChatWindow');
        var fab = document.getElementById('aiChatFab');
        if (win.classList.contains('open')) {
            win.classList.remove('open');
            fab.style.display = 'flex';
        } else {
            win.classList.add('open');
            fab.style.display = 'none';
            document.getElementById('aiChatInput').focus();
        }
    }

    // ==================== Helpers ====================

    function getCurrentPage() {
        var path = window.location.pathname || '';
        var href = window.location.href || '';
        if (path && path !== '/') return path;
        return href;
    }

    function updateStatus(text, state) {
        var el = document.getElementById('aiChatStatus');
        if (!el) return;
        el.textContent = text;
        el.className = 'ai-chat-header-status';
        if (state) el.classList.add('ai-status-' + state);
    }

    // ==================== Message Rendering ====================

    function appendUserMsg(text) {
        var msgs = document.getElementById('aiChatMessages');
        var welcome = msgs.querySelector('.ai-welcome');
        if (welcome) welcome.remove();
        var div = document.createElement('div');
        div.className = 'ai-msg user';
        div.innerHTML = '<div class="ai-msg-avatar">我</div><div class="ai-msg-bubble">' + escapeHtml(text) + '</div>';
        msgs.appendChild(div);
        scrollToBottom();
    }

    function showTyping() {
        removeTyping();
        var msgs = document.getElementById('aiChatMessages');
        var div = document.createElement('div');
        div.className = 'ai-msg bot';
        div.id = 'aiTypingIndicator';
        div.innerHTML = '<div class="ai-msg-avatar">AI</div>' +
            '<div class="ai-typing-wrap">' +
            '  <div class="ai-typing-progress"><div class="ai-typing-bar"></div></div>' +
            '  <div class="ai-typing-content">' +
            '    <div class="ai-typing"><div class="ai-typing-dot"></div><div class="ai-typing-dot"></div><div class="ai-typing-dot"></div></div>' +
            '    <span class="ai-typing-text" id="aiTypingText">正在连接AI...</span>' +
            '  </div>' +
            '</div>';
        msgs.appendChild(div);
        scrollToBottom();
    }

    function removeTyping() {
        var el = document.getElementById('aiTypingIndicator');
        if (el) el.remove();
    }

    function appendBotMsg(text) {
        var msgs = document.getElementById('aiChatMessages');
        var div = document.createElement('div');
        div.className = 'ai-msg bot';
        div.innerHTML = '<div class="ai-msg-avatar">AI</div><div class="ai-msg-bubble">' + formatMarkdown(text || '') + '</div>';
        msgs.appendChild(div);
        scrollToBottom();
    }

    // ==================== File Upload ====================

    function handleFileSelect(e) {
        if (e.target.files && e.target.files.length > 0) addFiles(e.target.files);
        e.target.value = '';
    }

    function addFiles(fileList) {
        for (var i = 0; i < fileList.length; i++) {
            if (pendingFiles.length >= MAX_FILES) { showToast('最多同时上传' + MAX_FILES + '个文件'); break; }
            var file = fileList[i];
            if (file.size > MAX_FILE_SIZE) { showToast('"' + file.name + '" 超过10MB限制'); continue; }
            var isImage = ALLOWED_IMAGE_TYPES.indexOf(file.type) >= 0;
            var ext = '.' + file.name.split('.').pop().toLowerCase();
            if (!isImage && ALLOWED_FILE_EXTS.indexOf(ext) < 0) { showToast('"' + file.name + '" 不支持该文件格式'); continue; }
            var entry = { file: file, type: isImage ? 'image' : 'file', previewUrl: null };
            if (isImage) {
                (function (entry) {
                    var reader = new FileReader();
                    reader.onload = function (ev) { entry.previewUrl = ev.target.result; renderPreview(); };
                    reader.readAsDataURL(file);
                })(entry);
            }
            pendingFiles.push(entry);
        }
        renderPreview();
    }

    function renderPreview() {
        var container = document.getElementById('aiUploadPreview');
        if (!container) return;
        if (pendingFiles.length === 0) { container.style.display = 'none'; container.innerHTML = ''; return; }
        container.style.display = 'flex';
        var html = '';
        for (var i = 0; i < pendingFiles.length; i++) {
            var f = pendingFiles[i];
            if (f.type === 'image' && f.previewUrl) {
                html += '<div class="ai-preview-item" data-idx="' + i + '"><img src="' + f.previewUrl + '" alt="' + escapeHtml(f.file.name) + '"/><button class="ai-preview-remove" data-idx="' + i + '">&times;</button></div>';
            } else {
                html += '<div class="ai-preview-item ai-preview-file" data-idx="' + i + '"><svg viewBox="0 0 24 24"><path d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm4 18H6V4h7v5h5v11z"/></svg><span class="ai-preview-filename">' + escapeHtml(truncName(f.file.name, 12)) + '</span><button class="ai-preview-remove" data-idx="' + i + '">&times;</button></div>';
            }
        }
        container.innerHTML = html;
        var removeBtns = container.querySelectorAll('.ai-preview-remove');
        for (var j = 0; j < removeBtns.length; j++) {
            removeBtns[j].onclick = function () {
                pendingFiles.splice(parseInt(this.getAttribute('data-idx'), 10), 1);
                renderPreview();
            };
        }
    }

    function truncName(name, max) {
        if (name.length <= max) return name;
        var ext = name.lastIndexOf('.') >= 0 ? name.substring(name.lastIndexOf('.')) : '';
        return name.substring(0, max - ext.length - 2) + '..' + ext;
    }

    function showToast(msg) {
        var existing = document.querySelector('.ai-chat-toast');
        if (existing) existing.remove();
        var toast = document.createElement('div');
        toast.className = 'ai-chat-toast';
        toast.textContent = msg;
        var win = document.getElementById('aiChatWindow');
        if (win) win.appendChild(toast);
        setTimeout(function () { toast.remove(); }, 3000);
    }

    function getFileIcon(filename) {
        var ext = filename.split('.').pop().toLowerCase();
        var icons = {
            pdf: '<svg viewBox="0 0 24 24"><path fill="#e53e3e" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm-1 9h-2v1h2v2h-2v1H9v-6h4v2zm4 4h-2v-6h2v6zM14 9V3.5L19.5 9H14z"/></svg>',
            doc: '<svg viewBox="0 0 24 24"><path fill="#2b6cb0" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm0 7V3.5L19.5 9H14zM8 13h8v1H8v-1zm0 2h8v1H8v-1zm0 2h5v1H8v-1z"/></svg>',
            docx: '<svg viewBox="0 0 24 24"><path fill="#2b6cb0" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm0 7V3.5L19.5 9H14zM8 13h8v1H8v-1zm0 2h8v1H8v-1zm0 2h5v1H8v-1z"/></svg>',
            xls: '<svg viewBox="0 0 24 24"><path fill="#276749" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm0 7V3.5L19.5 9H14zM10 13l2 4 2-4h1.5l-2.75 5L15.5 23H14l-2-4-2 4H8.5l2.75-5L8.5 13H10z"/></svg>',
            xlsx: '<svg viewBox="0 0 24 24"><path fill="#276749" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm0 7V3.5L19.5 9H14zM10 13l2 4 2-4h1.5l-2.75 5L15.5 23H14l-2-4-2 4H8.5l2.75-5L8.5 13H10z"/></svg>'
        };
        return icons[ext] || '<svg viewBox="0 0 24 24"><path fill="#718096" d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm0 7V3.5L19.5 9H14z"/></svg>';
    }

    function formatFileSize(bytes) {
        if (bytes < 1024) return bytes + 'B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + 'KB';
        return (bytes / (1024 * 1024)).toFixed(1) + 'MB';
    }

    function appendUserFileMsg(files) {
        var msgs = document.getElementById('aiChatMessages');
        var welcome = msgs.querySelector('.ai-welcome');
        if (welcome) welcome.remove();
        for (var i = 0; i < files.length; i++) {
            var f = files[i];
            var div = document.createElement('div');
            div.className = 'ai-msg user';
            if (f.type === 'image' && f.previewUrl) {
                div.innerHTML = '<div class="ai-msg-avatar">我</div><div class="ai-msg-bubble ai-file-bubble">' +
                    '<div class="ai-chat-img-wrap"><img src="' + f.previewUrl + '" alt="' + escapeHtml(f.file.name) + '" class="ai-chat-img"/></div>' +
                    '<div class="ai-file-name">' + escapeHtml(f.file.name) + ' <span class="ai-file-size">' + formatFileSize(f.file.size) + '</span></div></div>';
            } else {
                div.innerHTML = '<div class="ai-msg-avatar">我</div><div class="ai-msg-bubble ai-file-bubble">' +
                    '<div class="ai-file-icon">' + getFileIcon(f.file.name) + '</div>' +
                    '<div class="ai-file-info"><div class="ai-file-name">' + escapeHtml(f.file.name) + '</div>' +
                    '<div class="ai-file-size">' + formatFileSize(f.file.size) + '</div></div></div>';
            }
            msgs.appendChild(div);
        }
        scrollToBottom();
    }

    // ==================== Send ====================

    function sendMessage() {
        var input = document.getElementById('aiChatInput');
        var text = input.value.trim();
        var hasFiles = pendingFiles.length > 0;
        if (!text && !hasFiles) return;

        input.value = '';
        if (hasFiles) appendUserFileMsg(pendingFiles);
        if (text) appendUserMsg(text);

        disableInput();
        showTyping();

        var fullText = text;
        if (hasFiles) {
            var fileDescs = [];
            for (var i = 0; i < pendingFiles.length; i++) {
                fileDescs.push('[附件: ' + pendingFiles[i].file.name + ' (' + formatFileSize(pendingFiles[i].file.size) + ')]');
            }
            var fileInfo = fileDescs.join(', ');
            fullText = fullText ? fullText + '\n' + fileInfo : fileInfo;
        }

        pendingFiles = [];
        renderPreview();
        lastSentText = fullText;
        doSendHTTP(fullText);
    }

    // ==================== Utilities ====================

    function escapeHtml(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function formatMarkdown(text) {
        if (!text) return '';
        var html = escapeHtml(text);
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\n- /g, '<br>&bull; ');
        html = html.replace(/\n\* /g, '<br>&bull; ');
        html = html.replace(/\n(\d+)\. /g, '<br>$1. ');
        html = html.replace(/\n/g, '<br>');
        return html;
    }

    function scrollToBottom() {
        var msgs = document.getElementById('aiChatMessages');
        setTimeout(function () { msgs.scrollTop = msgs.scrollHeight; }, 50);
    }

    // Image lightbox
    document.addEventListener('click', function (e) {
        if (e.target && e.target.classList && e.target.classList.contains('ai-chat-img')) {
            var lightbox = document.createElement('div');
            lightbox.className = 'ai-chat-lightbox';
            lightbox.innerHTML = '<img src="' + e.target.src + '"/>';
            lightbox.onclick = function () { lightbox.remove(); };
            document.body.appendChild(lightbox);
        }
        if (e.target && e.target.classList && e.target.classList.contains('ai-chat-lightbox')) {
            e.target.remove();
        }
    });

    // ==================== Init ====================

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', createWidget);
    } else {
        createWidget();
    }

})();
