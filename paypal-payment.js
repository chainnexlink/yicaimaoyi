/**
 * PayPal 支付集成模块
 * 统一处理所有页面的 PayPal 支付流程
 */
(function() {
    'use strict';

    // API 基础地址
    var API_BASE = (function() {
        var port = window.location.port;
        if (!port || port === '80' || port === '443' || port === '8081') return '/api';
        return 'http://' + window.location.hostname + ':8081/api';
    })();

    var configPromise = null;
    var sdkPromise = null;
    var sdkCurrency = null;

    function authHeaders() {
        var headers = { 'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true' };
        var token = localStorage.getItem('accessToken') || localStorage.getItem('authToken');
        if (token) headers.Authorization = 'Bearer ' + token;
        return headers;
    }

    function loadConfig() {
        if (!configPromise) {
            configPromise = fetch(API_BASE + '/payments/paypal/config', { headers: authHeaders() })
                .then(function(response) {
                    if (!response.ok) throw new Error('PayPal configuration request failed');
                    return response.json();
                })
                .then(function(result) {
                    if (result.code !== 200 || !result.data || !result.data.enabled || !result.data.clientId) {
                        throw new Error('PayPal merchant account is not configured');
                    }
                    return result.data;
                });
        }
        return configPromise;
    }

    /**
     * 动态加载 PayPal JS SDK
     */
    function loadPayPalSDK(currency, callback) {
        if (typeof currency === 'function') {
            callback = currency;
            currency = 'USD';
        }
        currency = String(currency || 'USD').toUpperCase();
        if (window.paypal && sdkCurrency === currency) {
            var ready = Promise.resolve();
            if (callback) ready.then(function() { callback(); });
            return ready;
        }
        if (!sdkPromise || sdkCurrency !== currency) {
            sdkCurrency = currency;
            sdkPromise = loadConfig().then(function(config) {
                return new Promise(function(resolve, reject) {
                    var oldScript = document.getElementById('paypal-js-sdk');
                    if (oldScript) oldScript.remove();
                    var script = document.createElement('script');
                    script.id = 'paypal-js-sdk';
                    script.src = 'https://www.paypal.com/sdk/js?client-id=' + encodeURIComponent(config.clientId)
                        + '&currency=' + encodeURIComponent(currency) + '&components=buttons';
                    script.onload = resolve;
                    script.onerror = function() { reject(new Error('PayPal SDK load failed')); };
                    document.head.appendChild(script);
                });
            }).catch(function(error) {
                sdkPromise = null;
                throw error;
            });
        }
        if (callback) sdkPromise.then(function() { callback(); }, callback);
        return sdkPromise;
    }

    /**
     * 在指定容器中渲染 PayPal 支付按钮
     * @param {Object} options 配置
     * @param {string} options.containerId - 按钮容器 DOM ID
     * @param {string} options.amount - 支付金额（USD）
     * @param {string} options.paymentNo - 支付流水号
     * @param {number} options.paymentId - 支付记录 ID（可选）
     * @param {string} options.description - 支付描述
     * @param {function} options.onSuccess - 支付成功回调 (captureData)
     * @param {function} options.onError - 支付失败回调 (error)
     * @param {function} options.onCancel - 用户取消回调
     */
    function renderPayPalButton(options) {
        if (!options.paymentId) {
            var missingPayment = new Error('A platform payment record is required before PayPal checkout');
            if (options.onError) options.onError(missingPayment);
            return Promise.reject(missingPayment);
        }
        return loadPayPalSDK(options.currency || 'USD', function(err) {
            if (err) {
                console.error('[PayPal] SDK 加载失败，无法渲染按钮');
                if (options.onError) options.onError(err);
                return;
            }

            var container = document.getElementById(options.containerId);
            if (!container) {
                console.error('[PayPal] 容器不存在:', options.containerId);
                return;
            }

            // 清空容器
            container.innerHTML = '';

            window.paypal.Buttons({
                style: {
                    layout: 'vertical',
                    color: 'gold',
                    shape: 'rect',
                    label: 'paypal',
                    height: 45
                },

                // 创建 PayPal 订单
                createOrder: function(data, actions) {
                    console.log('[PayPal] 创建平台支付单对应的PayPal订单:', options.paymentId);

                    return fetch(API_BASE + '/payments/paypal/create-order', {
                        method: 'POST',
                        headers: authHeaders(),
                        body: JSON.stringify({
                            paymentId: Number(options.paymentId)
                        })
                    })
                    .then(function(res) { return res.json(); })
                    .then(function(result) {
                        if (result.code === 200 && result.data && result.data.orderId) {
                            console.log('[PayPal] 订单创建成功:', result.data.orderId);
                            return result.data.orderId;
                        }
                        throw new Error(result.message || 'Failed to create order');
                    });
                },

                // 买家批准后捕获支付
                onApprove: function(data, actions) {
                    console.log('[PayPal] 买家已批准, orderID:', data.orderID);

                    return fetch(API_BASE + '/payments/paypal/capture-order', {
                        method: 'POST',
                        headers: authHeaders(),
                        body: JSON.stringify({
                            orderId: data.orderID,
                            paymentId: Number(options.paymentId)
                        })
                    })
                    .then(function(res) { return res.json(); })
                    .then(function(result) {
                        if (result.code === 200 && result.data) {
                            console.log('[PayPal] 支付完成:', result.data);
                            if (options.onSuccess) {
                                options.onSuccess(result.data);
                            }
                        } else {
                            throw new Error(result.message || 'Capture failed');
                        }
                    });
                },

                // 用户取消
                onCancel: function(data) {
                    console.log('[PayPal] 用户取消支付');
                    if (options.onCancel) options.onCancel(data);
                },

                // 错误处理
                onError: function(err) {
                    console.error('[PayPal] 支付错误:', err);
                    if (options.onError) options.onError(err);
                }
            }).render('#' + options.containerId);
        });
    }

    /**
     * 创建 PayPal 支付弹窗
     * @param {Object} options 配置（同 renderPayPalButton）
     */
    function showPayPalModal(options) {
        // 移除已有弹窗
        var existing = document.getElementById('paypal-payment-modal');
        if (existing) existing.remove();

        var modal = document.createElement('div');
        modal.id = 'paypal-payment-modal';
        modal.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.6);z-index:100000;display:flex;align-items:center;justify-content:center;';

        var content = document.createElement('div');
        content.style.cssText = 'background:#1a1a2e;border-radius:16px;padding:32px;max-width:480px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,0.5);border:1px solid rgba(0,229,204,0.2);';

        var safeDescription = String(options.description || 'Payment')
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        var header = '<div style="text-align:center;margin-bottom:24px;">' +
            '<h3 style="color:#fff;margin:0 0 8px;font-size:20px;">PayPal Checkout</h3>' +
            '<p style="color:#aaa;margin:0;font-size:14px;">' + safeDescription + '</p>' +
            '<p style="color:#00E5CC;font-size:28px;font-weight:700;margin:16px 0 0;">' + parseFloat(options.amount).toFixed(2) + ' ' + String(options.currency || 'USD') + '</p>' +
            '</div>';

        var btnContainer = '<div id="paypal-modal-btn-container" style="min-height:50px;"></div>';

        var closeBtn = '<button onclick="document.getElementById(\'paypal-payment-modal\').remove()" ' +
            'style="width:100%;margin-top:16px;padding:12px;background:transparent;border:1px solid rgba(255,255,255,0.2);' +
            'border-radius:8px;color:#aaa;cursor:pointer;font-size:14px;">Cancel</button>';

        content.innerHTML = header + btnContainer + closeBtn;
        modal.appendChild(content);

        // 点击遮罩关闭
        modal.addEventListener('click', function(e) {
            if (e.target === modal) modal.remove();
        });

        document.body.appendChild(modal);

        // 覆盖回调以自动关闭弹窗
        var origSuccess = options.onSuccess;
        var origCancel = options.onCancel;

        renderPayPalButton({
            containerId: 'paypal-modal-btn-container',
            amount: options.amount,
            currency: options.currency,
            paymentId: options.paymentId,
            description: options.description,
            onSuccess: function(data) {
                modal.remove();
                if (origSuccess) origSuccess(data);
            },
            onCancel: function(data) {
                modal.remove();
                if (origCancel) origCancel(data);
            },
            onError: options.onError
        });
    }

    // 导出全局 API
    window.PayPalPayment = {
        loadSDK: loadPayPalSDK,
        renderButton: renderPayPalButton,
        showModal: showPayPalModal
    };

})();
