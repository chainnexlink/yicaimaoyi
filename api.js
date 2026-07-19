/**
 * 易采贸易平台 - 共享API工具类
 * 所有页面可引入此脚本获得统一的API调用能力
 * 
 * 使用方式: <script src="api.js"></script>
 * 调用方式: YicaiAPI.get('/orders/buyer/1'), YicaiAPI.post('/auth/login', body)
 */
const YicaiAPI = (function() {
    // API基础地址 - 智能检测运行环境
    // Docker/Nginx(port 80/443)或Spring Boot(port 8081): 使用相对路径
    // 开发环境(前端在其他端口): 直接连接后端8081
    const API_BASE = (() => {
        const port = window.location.port;
        if (!port || port === '80' || port === '443' || port === '8081') return '/api';
        return 'http://' + window.location.hostname + ':8081/api';
    })();

    // 获取JWT Token
    function getToken() {
        return localStorage.getItem('accessToken') || '';
    }

    // 构建请求头
    function buildHeaders(extra) {
        const headers = {
            'Content-Type': 'application/json',
            ...extra
        };
        const token = getToken();
        if (token) {
            headers['Authorization'] = 'Bearer ' + token;
        }
        return headers;
    }

    // 通用请求方法
    async function request(method, path, body, options) {
        const url = API_BASE + path;
        const config = {
            method: method,
            headers: buildHeaders(options && options.headers),
            ...options
        };
        if (body && method !== 'GET') {
            config.body = JSON.stringify(body);
        }
        
        try {
            const res = await fetch(url, config);
            
            // 401 自动跳转登录
            if (res.status === 401) {
                localStorage.removeItem('accessToken');
                localStorage.removeItem('refreshToken');
                if (!window.location.pathname.includes('login.html')) {
                    window.location.href = 'login.html';
                }
                return { code: 401, msg: '未登录或登录已过期' };
            }
            
            const data = await res.json();
            return data;
        } catch (e) {
            console.warn(`API请求失败 [${method} ${path}]:`, e.message);
            return null; // 返回null表示API不可用，调用方可回退到Mock
        }
    }

    // 获取当前登录用户
    function getCurrentUser() {
        try {
            return JSON.parse(localStorage.getItem('currentUser') || 'null');
        } catch (e) {
            return null;
        }
    }

    // 检查是否已登录
    function isLoggedIn() {
        return !!getCurrentUser();
    }

    // 登出
    function logout() {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('currentUser');
        window.location.href = 'login.html';
    }

    // Toast通知（如页面有showToast则复用，否则用alert）
    function toast(msg, type) {
        if (typeof window.showToast === 'function') {
            window.showToast(msg, type);
        } else {
            if (type === 'error') {
                console.error(msg);
            } else {
                console.log(msg);
            }
        }
    }

    return {
        BASE: API_BASE,
        get: (path, options) => request('GET', path, null, options),
        post: (path, body, options) => request('POST', path, body, options),
        put: (path, body, options) => request('PUT', path, body, options),
        patch: (path, body, options) => request('PATCH', path, body, options),
        del: (path, options) => request('DELETE', path, null, options),
        getToken,
        getCurrentUser,
        isLoggedIn,
        logout,
        toast
    };
})();
