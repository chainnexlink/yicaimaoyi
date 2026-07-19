/**
 * auth-check.js - 统一认证状态检查
 * 在页面加载时检查 localStorage 中的登录状态，
 * 动态切换 登录按钮 / 用户菜单 的显示。
 */
(function () {
    function initAuth() {
        var token = localStorage.getItem('accessToken');
        var currentUser = null;
        try {
            currentUser = JSON.parse(localStorage.getItem('currentUser'));
        } catch (e) { /* ignore */ }

        var loginBtn = document.getElementById('loginBtn');
        var userMenu = document.getElementById('userMenu');

        // 没有 token 或没有 currentUser => 未登录
        var isLoggedIn = !!(token && currentUser && currentUser.username);

        if (loginBtn) {
            loginBtn.style.display = isLoggedIn ? 'none' : '';
        }
        if (userMenu) {
            userMenu.style.display = isLoggedIn ? '' : 'none';
        }

        // 如果已登录，更新用户名显示
        if (isLoggedIn && userMenu) {
            var nameEls = userMenu.querySelectorAll('.user-name');
            var displayName = currentUser.displayName || currentUser.username || '';
            for (var i = 0; i < nameEls.length; i++) {
                nameEls[i].textContent = displayName;
            }
            // 更新头像字母
            var avatarEls = userMenu.querySelectorAll('.user-avatar-sm');
            if (avatarEls.length > 0 && displayName) {
                for (var j = 0; j < avatarEls.length; j++) {
                    avatarEls[j].textContent = displayName.charAt(0).toUpperCase();
                }
            }
        }

        // 绑定退出登录
        var logoutBtn = document.getElementById('logoutBtn');
        if (!logoutBtn) {
            // 尝试通过 class 查找
            var logoutItems = document.querySelectorAll('.logout-item');
            if (logoutItems.length > 0) {
                logoutBtn = logoutItems[logoutItems.length - 1];
            }
        }
        if (logoutBtn) {
            logoutBtn.addEventListener('click', function (e) {
                e.preventDefault();
                localStorage.removeItem('accessToken');
                localStorage.removeItem('refreshToken');
                localStorage.removeItem('currentUser');
                window.location.href = 'login.html';
            });
        }
    }

    // 如果 DOM 已经加载完成则直接执行，否则等待
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAuth);
    } else {
        initAuth();
    }
})();
