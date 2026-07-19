/**
 * 全球供应链智能匹配平台 - 交互脚本
 */

document.addEventListener('DOMContentLoaded', function() {
    // 初始化所有功能
    initNumberAnimation();
    initHeroBannerStats();
    initHeroParticles();
    initLiveMonitor();
    initSupplierCarousel();
    initScrollReveal();
    initHeroDots();
    initFeatureCards();
    initSearchBox();
    loadHeroNews();
});

/**
 * 数字滚动动画
 */
function initNumberAnimation() {
    const statNumbers = document.querySelectorAll('.stat-number[data-target]');
    
    const animateNumber = (element) => {
        const target = parseInt(element.getAttribute('data-target'));
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;
        
        const updateNumber = () => {
            current += step;
            if (current < target) {
                element.textContent = Math.floor(current).toLocaleString();
                requestAnimationFrame(updateNumber);
            } else {
                element.textContent = target.toLocaleString();
            }
        };
        
        updateNumber();
    };
    
    // 使用Intersection Observer触发动画
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateNumber(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    statNumbers.forEach(num => observer.observe(num));
}

/**
 * 供应商轮播
 */
function initSupplierCarousel() {
    const container = document.querySelector('.supplier-container');
    const prevBtn = document.querySelector('.carousel-btn.prev');
    const nextBtn = document.querySelector('.carousel-btn.next');
    
    if (!container || !prevBtn || !nextBtn) return;
    
    let currentIndex = 0;
    const cards = container.querySelectorAll('.supplier-card');
    const cardWidth = cards[0]?.offsetWidth + 20 || 300; // 卡片宽度 + 间距
    const visibleCards = Math.floor(container.offsetWidth / cardWidth);
    const maxIndex = Math.max(0, cards.length - visibleCards);
    
    const updateCarousel = () => {
        container.style.transform = `translateX(-${currentIndex * cardWidth}px)`;
        container.style.transition = 'transform 0.3s ease';
    };
    
    prevBtn.addEventListener('click', () => {
        if (currentIndex > 0) {
            currentIndex--;
            updateCarousel();
        }
    });
    
    nextBtn.addEventListener('click', () => {
        if (currentIndex < maxIndex) {
            currentIndex++;
            updateCarousel();
        }
    });
    
    // 自动轮播
    let autoplayInterval = setInterval(() => {
        if (currentIndex < maxIndex) {
            currentIndex++;
        } else {
            currentIndex = 0;
        }
        updateCarousel();
    }, 5000);
    
    // 鼠标悬停暂停
    container.addEventListener('mouseenter', () => {
        clearInterval(autoplayInterval);
    });
    
    container.addEventListener('mouseleave', () => {
        autoplayInterval = setInterval(() => {
            if (currentIndex < maxIndex) {
                currentIndex++;
            } else {
                currentIndex = 0;
            }
            updateCarousel();
        }, 5000);
    });
}

/**
 * 滚动显示动画（含 stagger 延时 & scale）
 */
function initScrollReveal() {
    const elements = document.querySelectorAll(
        '.stat-card, .supplier-card, .feature-card, .quick-card, .news-card, .section-title, .core-card, .advantage-card'
    );
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0) scale(1)';
            }
        });
    }, { 
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });
    
    elements.forEach((el, idx) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px) scale(0.97)';
        el.style.transition = 'opacity 0.6s ease ' + (idx % 4) * 0.1 + 's, transform 0.6s ease ' + (idx % 4) * 0.1 + 's';
        observer.observe(el);
    });
}

/**
 * Hero轮播点
 */
function initHeroDots() {
    const dots = document.querySelectorAll('.hero-dots .dot');
    const heroContent = document.querySelector('.hero-content');
    
    if (!heroContent || dots.length === 0) return;
    
    const slides = [
        {
            title: '智能匹配，精准对接',
            subtitle: '通过大数据分析，为您匹配最适合的供应商资源',
            btnText: '开始匹配'
        },
        {
            title: '全球供应商网络',
            subtitle: '从已审核供应商资源中按品类、产能、认证和交付能力筛选候选工厂',
            btnText: '查看供应商'
        },
        {
            title: '全流程透明管理',
            subtitle: '从询价到交付，实时追踪每一个环节',
            btnText: '了解更多'
        }
    ];
    
    let currentSlide = 1;
    
    const updateSlide = (index) => {
        // 更新激活状态
        dots.forEach((dot, i) => {
            dot.classList.toggle('active', i === index);
        });
        
        // 更新内容
        const slide = slides[index];
        const title = heroContent.querySelector('.hero-title');
        const subtitle = heroContent.querySelector('.hero-subtitle');
        const btn = heroContent.querySelector('.btn-primary');
        
        // 淡出效果
        heroContent.style.opacity = '0';
        heroContent.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            title.textContent = slide.title;
            subtitle.textContent = slide.subtitle;
            btn.textContent = slide.btnText;
            
            // 淡入效果
            heroContent.style.opacity = '1';
            heroContent.style.transform = 'translateY(0)';
        }, 300);
        
        currentSlide = index;
    };
    
    // 添加过渡效果
    heroContent.style.transition = 'all 0.3s ease';
    
    // 点击切换
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => updateSlide(index));
    });
    
    // 自动切换
    setInterval(() => {
        const nextSlide = (currentSlide + 1) % slides.length;
        updateSlide(nextSlide);
    }, 6000);
}

/**
 * 功能卡片交互
 */
function initFeatureCards() {
    const cards = document.querySelectorAll('.feature-card');
    
    cards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            // 移除其他卡片的active状态
            cards.forEach(c => c.classList.remove('active'));
            // 添加当前卡片的active状态
            card.classList.add('active');
        });
    });
}

/**
 * 搜索框交互 - 模糊搜索
 */
function initSearchBox() {
    const searchBox = document.querySelector('.search-box');
    const searchInput = searchBox?.querySelector('input');
    const searchBtn = searchBox?.querySelector('.search-btn');

    if (!searchInput || !searchBtn) return;

    // 平台搜索数据索引
    const searchIndex = [
        // === 供应商 ===
        { type: 'supplier', title: '深圳智能科技公司', desc: '智能设备、IT产品', tags: '深圳 智能 科技 电子 IT 设备', url: 'supplier-detail.html?id=1', icon: '深' },
        { type: 'supplier', title: '广州物流集团', desc: '物流服务、仓储服务、配送服务', tags: '广州 物流 仓储 配送 运输', url: 'supplier-detail.html?id=2', icon: '广' },
        { type: 'supplier', title: '杭州电商科技', desc: '电商平台、数字营销、数据分析', tags: '杭州 电商 营销 数据 分析', url: 'supplier-detail.html?id=3', icon: '杭' },
        { type: 'supplier', title: '成都制造有限公司', desc: '汽车零部件、机械配件、五金工具', tags: '成都 制造 汽车 零部件 机械 五金', url: 'supplier-detail.html?id=4', icon: '成' },
        { type: 'supplier', title: '上海精密仪器有限公司', desc: '精密仪器、测量设备、实验器材', tags: '上海 精密 仪器 测量 实验', url: 'suppliers.html', icon: '上' },
        { type: 'supplier', title: '北京环保科技集团', desc: '环保设备、净化系统、新能源', tags: '北京 环保 净化 新能源 绿色', url: 'suppliers.html', icon: '北' },
        { type: 'supplier', title: '东莞电子元器件厂', desc: '电子元器件、PCB板、芯片', tags: '东莞 电子 元器件 PCB 芯片 半导体', url: 'suppliers.html', icon: '东' },
        { type: 'supplier', title: '宁波外贸进出口公司', desc: '外贸代理、报关服务、货运代理', tags: '宁波 外贸 进出口 报关 货运', url: 'suppliers.html', icon: '宁' },
        // === 产品分类 ===
        { type: 'product', title: '电子元器件', desc: '芯片、电阻、电容、传感器等', tags: '电子 元器件 芯片 电阻 电容 传感器 半导体', url: 'suppliers.html', icon: '🔌' },
        { type: 'product', title: '机械设备', desc: '数控机床、注塑机、包装设备等', tags: '机械 设备 数控 机床 注塑 包装 工业', url: 'suppliers.html', icon: '⚙' },
        { type: 'product', title: '原材料', desc: '钢材、塑料、化工原料、纺织材料', tags: '原材料 钢材 塑料 化工 纺织 材料', url: 'suppliers.html', icon: '🧱' },
        { type: 'product', title: '智能设备', desc: 'IoT设备、智能传感器、自动化控制', tags: '智能 设备 IoT 传感器 自动化 控制', url: 'suppliers.html', icon: '🤖' },
        { type: 'product', title: '汽车零部件', desc: '发动机配件、底盘零件、电气系统', tags: '汽车 零部件 发动机 底盘 电气 配件', url: 'suppliers.html', icon: '🚗' },
        { type: 'product', title: '五金工具', desc: '手动工具、电动工具、紧固件', tags: '五金 工具 手动 电动 紧固件 螺丝', url: 'suppliers.html', icon: '🔧' },
        { type: 'product', title: '物流服务', desc: '国际货运、仓储配送、清关服务', tags: '物流 货运 仓储 配送 清关 运输 快递', url: 'suppliers.html', icon: '📦' },
        { type: 'product', title: '数字营销', desc: '电商运营、品牌推广、数据分析', tags: '数字 营销 电商 品牌 推广 数据 广告', url: 'suppliers.html', icon: '📊' },
        // === 平台功能页面 ===
        { type: 'page', title: '智能匹配', desc: 'AI驱动的精准供应商匹配系统', tags: '智能 匹配 AI 推荐 算法 精准', url: 'smart-match.html', icon: '🎯' },
        { type: 'page', title: '供应商库', desc: '全球优质供应商资源一站式浏览', tags: '供应商 库 列表 全球 资源', url: 'suppliers.html', icon: '🏢' },
        { type: 'page', title: '订单管理', desc: '全流程订单跟踪与管理', tags: '订单 管理 跟踪 采购 流程', url: 'orders.html', icon: '📋' },
        { type: 'page', title: '物流追踪', desc: '实时物流状态监控', tags: '物流 追踪 运输 状态 实时 监控', url: 'user-center.html#logistics', icon: '🚚' },
        { type: 'page', title: '需求论坛', desc: '发布采购需求，供应商主动报价', tags: '需求 论坛 发布 采购 报价', url: 'publish-demand.html', icon: '📝' },
        { type: 'page', title: '询盘管理', desc: '管理询价单与报价沟通', tags: '询盘 询价 报价 沟通 管理', url: 'inquiry.html', icon: '💬' },
        { type: 'page', title: '生产监控', desc: '实时监控供应商生产进度', tags: '生产 监控 进度 工厂 质量', url: 'production-monitor.html', icon: '🏭' },
        { type: 'page', title: '数据看板', desc: '采购数据可视化分析', tags: '数据 看板 分析 可视化 报表 统计', url: 'dashboard.html', icon: '📈' },
        { type: 'page', title: '资质认证', desc: '企业资质认证与审核', tags: '资质 认证 审核 ISO 证书', url: 'certification.html', icon: '✅' },
        { type: 'page', title: '消息中心', desc: '系统通知与沟通消息', tags: '消息 通知 沟通 聊天 站内信', url: 'messages.html', icon: '🔔' },
        { type: 'page', title: '客服中心', desc: '帮助文档与在线客服支持', tags: '客服 帮助 FAQ 在线 支持', url: 'help.html', icon: '🎧' },
        { type: 'page', title: '采购商中心', desc: '采购商个人中心与账户管理', tags: '采购商 个人 中心 账户 管理', url: 'user-center.html', icon: '👤' },
        { type: 'page', title: '供应商中心', desc: '供应商工作台与店铺管理', tags: '供应商 中心 工作台 店铺', url: 'supplier-center.html', icon: '🏪' },
        { type: 'page', title: '供应商地图', desc: '全球供应商分布地图', tags: '供应商 地图 分布 全球 位置', url: 'supplier-map.html', icon: '🗺' },
        // === 行业资讯 ===
        { type: 'news', title: '2026年全球供应链发展趋势分析', desc: '数字化转型加速，智能供应链管理成为核心竞争力', tags: '供应链 趋势 分析 数字化 2026', url: 'news-detail.html?id=1', icon: '📰' },
        { type: 'news', title: '平台助力中小企业出海新机遇', desc: '智能匹配技术帮助中小企业对接全球优质供应商', tags: '中小企业 出海 机遇 匹配', url: 'news-detail.html?id=2', icon: '📰' },
        { type: 'news', title: '跨境贸易新政策解读与应对策略', desc: '最新跨境贸易政策对供应链管理的影响', tags: '跨境 贸易 政策 解读 策略', url: 'news-detail.html?id=3', icon: '📰' }
    ];

    // 热门搜索标签
    const hotTags = ['智能匹配', '电子元器件', '物流服务', '机械设备', '供应商', '五金工具', '原材料', '订单管理'];

    // 类型中文名和图标类
    const typeConfig = {
        supplier: { label: '供应商', iconClass: 'supplier' },
        product:  { label: '产品分类', iconClass: 'product' },
        page:     { label: '平台功能', iconClass: 'page' },
        news:     { label: '行业资讯', iconClass: 'news' }
    };

    // 创建下拉面板
    const dropdown = document.createElement('div');
    dropdown.className = 'search-results-dropdown';
    searchBox.appendChild(dropdown);

    // 模糊匹配函数：支持子串匹配和字符序列匹配
    function fuzzyMatch(query, text) {
        if (!query || !text) return { matched: false, score: 0 };
        const q = query.toLowerCase();
        const t = text.toLowerCase();

        // 完全包含 - 最高优先级
        const idx = t.indexOf(q);
        if (idx !== -1) {
            return { matched: true, score: 100 - idx };
        }

        // 多关键词匹配（空格分隔）
        const keywords = q.split(/\s+/).filter(Boolean);
        if (keywords.length > 1) {
            let allMatch = true;
            let totalScore = 0;
            for (const kw of keywords) {
                if (t.indexOf(kw) !== -1) {
                    totalScore += 30;
                } else {
                    allMatch = false;
                    break;
                }
            }
            if (allMatch) return { matched: true, score: totalScore };
        }

        // 字符序列匹配（模糊）
        let qi = 0;
        let consecutiveBonus = 0;
        let lastMatchIdx = -2;
        for (let ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                if (ti === lastMatchIdx + 1) consecutiveBonus += 5;
                lastMatchIdx = ti;
                qi++;
            }
        }
        if (qi === q.length) {
            return { matched: true, score: 10 + consecutiveBonus };
        }

        return { matched: false, score: 0 };
    }

    // 搜索函数
    function doSearch(query) {
        if (!query) return [];
        const results = [];
        for (const item of searchIndex) {
            const searchText = item.title + ' ' + item.desc + ' ' + item.tags;
            const m = fuzzyMatch(query, searchText);
            // 标题匹配额外加分
            const titleMatch = fuzzyMatch(query, item.title);
            if (titleMatch.matched) m.score += 50;
            if (m.matched || titleMatch.matched) {
                results.push({ ...item, score: m.score + (titleMatch.matched ? titleMatch.score : 0) });
            }
        }
        results.sort((a, b) => b.score - a.score);
        return results.slice(0, 12);
    }

    // 高亮匹配文字
    function highlightText(text, query) {
        if (!query) return text;
        const keywords = query.toLowerCase().split(/\s+/).filter(Boolean);
        let result = text;
        for (const kw of keywords) {
            const regex = new RegExp('(' + kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi');
            result = result.replace(regex, '<span class="highlight">$1</span>');
        }
        return result;
    }

    // 渲染搜索结果
    function renderResults(query) {
        const q = query.trim();
        if (!q) {
            // 显示热门搜索
            dropdown.innerHTML = '<div class="search-hot-tags">' +
                '<div class="hot-label">热门搜索</div>' +
                '<div class="hot-list">' +
                hotTags.map(tag => '<span class="hot-tag" data-tag="' + tag + '">' + tag + '</span>').join('') +
                '</div></div>';
            dropdown.classList.add('active');
            // 绑定热门标签点击
            dropdown.querySelectorAll('.hot-tag').forEach(function(el) {
                el.addEventListener('click', function() {
                    searchInput.value = this.getAttribute('data-tag');
                    renderResults(this.getAttribute('data-tag'));
                    searchInput.focus();
                });
            });
            return;
        }

        const results = doSearch(q);
        if (results.length === 0) {
            dropdown.innerHTML = '<div class="search-no-result">' +
                '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"></circle><path d="m21 21-4.35-4.35"></path></svg>' +
                '<div>未找到与 "<strong>' + q.replace(/</g, '&lt;') + '</strong>" 相关的结果</div>' +
                '<div style="font-size:12px;margin-top:6px;">试试其他关键词，如：供应商、电子元器件、物流</div>' +
                '</div>';
            dropdown.classList.add('active');
            return;
        }

        // 按类型分组
        var groups = {};
        var groupOrder = ['supplier', 'product', 'page', 'news'];
        results.forEach(function(item) {
            if (!groups[item.type]) groups[item.type] = [];
            groups[item.type].push(item);
        });

        var html = '';
        groupOrder.forEach(function(type) {
            var items = groups[type];
            if (!items || items.length === 0) return;
            var config = typeConfig[type];
            html += '<div class="search-results-group">';
            html += '<div class="search-group-label">' + config.label + '</div>';
            items.forEach(function(item) {
                html += '<a class="search-result-item" href="' + item.url + '">';
                html += '<div class="search-result-icon ' + config.iconClass + '">' + item.icon + '</div>';
                html += '<div class="search-result-info">';
                html += '<div class="search-result-title">' + highlightText(item.title, q) + '</div>';
                html += '<div class="search-result-desc">' + highlightText(item.desc, q) + '</div>';
                html += '</div>';
                html += '<span class="search-result-arrow">→</span>';
                html += '</a>';
            });
            html += '</div>';
        });

        dropdown.innerHTML = html;
        dropdown.classList.add('active');
    }

    // 关闭下拉面板
    function closeDropdown() {
        dropdown.classList.remove('active');
    }

    // 防抖
    var debounceTimer = null;

    // 输入事件
    searchInput.addEventListener('input', function() {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(function() {
            renderResults(searchInput.value);
        }, 200);
    });

    // 聚焦时显示热门搜索或已有结果
    searchInput.addEventListener('focus', function() {
        searchBox.style.borderColor = '#00E5CC';
        searchBox.style.boxShadow = '0 0 0 3px rgba(0, 229, 204, 0.1)';
        renderResults(searchInput.value);
    });

    searchInput.addEventListener('blur', function() {
        searchBox.style.borderColor = '';
        searchBox.style.boxShadow = '';
        // 延迟关闭，允许点击结果
        setTimeout(closeDropdown, 200);
    });

    // 搜索按钮 / 回车 -> 如果有结果跳转第一个，否则跳转供应商搜索页
    var performSearch = function() {
        var query = searchInput.value.trim();
        if (!query) return;
        var results = doSearch(query);
        if (results.length > 0) {
            window.location.href = results[0].url;
        } else {
            window.location.href = 'suppliers.html?search=' + encodeURIComponent(query);
        }
    };

    searchBtn.addEventListener('click', performSearch);

    searchInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            performSearch();
        }
        if (e.key === 'Escape') {
            closeDropdown();
            searchInput.blur();
        }
    });

    // 点击外部关闭
    document.addEventListener('click', function(e) {
        if (!searchBox.contains(e.target)) {
            closeDropdown();
        }
    });
}

/**
 * 平滑滚动到指定区域
 */
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.scrollIntoView({ behavior: 'smooth' });
    }
}

/**
 * 导航链接高亮
 */
function initNavHighlight() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    
    window.addEventListener('scroll', () => {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            
            if (scrollY >= sectionTop - 200) {
                current = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href')?.includes(current)) {
                link.classList.add('active');
            }
        });
    });
}

/**
 * 地图交互效果
 */
function initMapInteraction() {
    const mapDots = document.querySelectorAll('.map-dot');
    const mapOverlay = document.querySelector('.map-overlay');
    
    mapDots.forEach(dot => {
        dot.addEventListener('mouseenter', function() {
            this.style.fill = '#4FFFEC';
            this.style.filter = 'drop-shadow(0 0 10px #00E5CC)';
        });
        
        dot.addEventListener('mouseleave', function() {
            this.style.fill = '';
            this.style.filter = '';
        });
    });
    
    // 点击地图覆盖层
    if (mapOverlay) {
        mapOverlay.style.cursor = 'pointer';
        mapOverlay.addEventListener('click', () => {
            console.log('查看详细分布');
            // 可以添加弹窗或跳转逻辑
        });
    }
}

// 初始化地图交互
document.addEventListener('DOMContentLoaded', initMapInteraction);

/**
 * 响应式菜单（移动端）
 */
function initMobileMenu() {
    const header = document.querySelector('.header');
    let lastScrollY = window.scrollY;
    
    // 滚动时隐藏/显示导航栏
    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        
        if (currentScrollY > lastScrollY && currentScrollY > 100) {
            header.style.transform = 'translateY(-100%)';
        } else {
            header.style.transform = 'translateY(0)';
        }
        
        lastScrollY = currentScrollY;
    });
    
    header.style.transition = 'transform 0.3s ease';
}

// 延迟初始化移动端菜单
setTimeout(initMobileMenu, 100);

/**
 * 智能采购反向竞价模块
 */
const AUCTION_API = (function() {
    var port = window.location.port;
    if (!port || port === '80' || port === '443' || port === '8081') return '/api/v1/auction';
    return 'http://' + window.location.hostname + ':8081/api/v1/auction';
})();

// 虚拟竞价数据
const MOCK_AUCTIONS = [
    {
        id: 1,
        auctionNo: 'AUC202602260001',
        productName: '办公电脑采购项目',
        buyerCompany: '深圳市政府采购中心',
        productCategory: '电子设备',
        quantity: 100,
        unit: '台',
        startingPrice: 5000.00,
        currentLowestPrice: 4680.00,
        minDecrement: 50,
        status: 'ACTIVE',
        statusText: '竞价中',
        bidCount: 15,
        participantCount: 6,
        signupCount: 8,
        minParticipants: 3,
        remainingSeconds: 3600,
        currentExtensions: 1,
        extensionMinutes: 5,
        extensionTriggerMinutes: 5
    },
    {
        id: 2,
        auctionNo: 'AUC202602260002',
        productName: '打印耗材集中采购',
        buyerCompany: '广州市教育局',
        productCategory: '办公用品',
        quantity: 500,
        unit: '套',
        startingPrice: 200.00,
        currentLowestPrice: 200.00,
        minDecrement: 5,
        status: 'SIGNUP',
        statusText: '报名中',
        bidCount: 0,
        participantCount: 0,
        signupCount: 5,
        minParticipants: 3,
        remainingSeconds: 7200,
        currentExtensions: 0,
        extensionMinutes: 5,
        extensionTriggerMinutes: 5
    },
    {
        id: 3,
        auctionNo: 'AUC202602260003',
        productName: '服务器设备采购',
        buyerCompany: '杭州市信息中心',
        productCategory: '网络设备',
        quantity: 20,
        unit: '台',
        startingPrice: 35000.00,
        currentLowestPrice: 32500.00,
        minDecrement: 500,
        status: 'ACTIVE',
        statusText: '竞价中',
        bidCount: 8,
        participantCount: 4,
        signupCount: 6,
        minParticipants: 3,
        remainingSeconds: 1800,
        currentExtensions: 2,
        extensionMinutes: 5,
        extensionTriggerMinutes: 5
    },
    {
        id: 4,
        auctionNo: 'AUC202602260004',
        productName: '办公家具批量采购',
        buyerCompany: '成都市财政局',
        productCategory: '家具',
        quantity: 200,
        unit: '套',
        startingPrice: 1500.00,
        currentLowestPrice: 1350.00,
        minDecrement: 30,
        status: 'CONFIRMING',
        statusText: '待确认',
        bidCount: 22,
        participantCount: 7,
        signupCount: 10,
        minParticipants: 3,
        remainingSeconds: 0,
        winnerSupplierId: 101,
        winnerCompany: '成都办公家具有限公司',
        winningPrice: 1350.00,
        buyerConfirmed: true,
        supplierConfirmed: false
    },
    {
        id: 5,
        auctionNo: 'AUC202602260005',
        productName: '空调设备采购安装',
        buyerCompany: '武汉市机关事务局',
        productCategory: '电器设备',
        quantity: 50,
        unit: '台',
        startingPrice: 4200.00,
        currentLowestPrice: 4200.00,
        minDecrement: 100,
        status: 'PENDING',
        statusText: '待开始',
        bidCount: 0,
        participantCount: 0,
        signupCount: 12,
        minParticipants: 3,
        remainingSeconds: 14400,
        currentExtensions: 0,
        extensionMinutes: 5,
        extensionTriggerMinutes: 5
    },
    {
        id: 6,
        auctionNo: 'AUC202602260006',
        productName: '网络安全设备采购',
        buyerCompany: '南京市公安局',
        productCategory: '安全设备',
        quantity: 10,
        unit: '套',
        startingPrice: 80000.00,
        currentLowestPrice: 72000.00,
        minDecrement: 1000,
        status: 'ENDED',
        statusText: '已结束',
        bidCount: 18,
        participantCount: 5,
        signupCount: 8,
        minParticipants: 3,
        remainingSeconds: 0,
        winnerSupplierId: 102,
        winnerCompany: '江苏网安科技公司',
        winningPrice: 72000.00
    }
];

async function initAuctionSection() {
    const auctionGrid = document.getElementById('auctionGrid');
    if (!auctionGrid) return;

    try {
        const response = await fetch(`${AUCTION_API}/home?limit=6`);
        const result = await response.json();
        
        if (result.code === 200 && result.data && result.data.length > 0) {
            renderAuctions(result.data);
        } else {
            renderDemoAuctions();
        }
    } catch (error) {
        console.error('加载首页竞价失败:', error);
        renderDemoAuctions();
    }
}

function renderDemoAuctions() {
    if (window.YICAI_AUCTION_DEMO) {
        renderAuctions(window.YICAI_AUCTION_DEMO.getAuctions().slice(0, 3));
        return;
    }
    renderEmptyAuctions();
}

function renderAuctions(auctions) {
    const auctionGrid = document.getElementById('auctionGrid');
    if (!auctionGrid) return;

    const containsDemo = auctions.some(auction => auction.demo === true);
    const notice = containsDemo ? `
        <div class="auction-demo-notice" style="grid-column:1/-1;padding:12px 16px;border:1px solid rgba(0,229,204,.28);border-radius:10px;background:rgba(0,229,204,.07);color:#B8C5D6;font-size:13px;line-height:1.6;">
            <strong style="color:#00E5CC;">交互演示数据</strong> · 用于展示易采自营采购团队如何组织供应商反向竞价，不代表正在发生的真实订单。
        </div>` : '';

    auctionGrid.innerHTML = notice + auctions.map(auction => {
        // 根据状态决定显示内容
        const isSignup = auction.status === 'SIGNUP' || auction.status === 'APPROVED';
        const isActive = auction.status === 'ACTIVE';
        const timerLabel = isActive ? '距结束' : (isSignup ? '距报名截止' : '距开始');
        const auctionUrl = window.YICAI_AUCTION_DEMO
            ? window.YICAI_AUCTION_DEMO.detailUrl(auction)
            : `auction-detail.html?id=${encodeURIComponent(String(auction.id || ''))}`;
        const currency = auction.currency || 'CNY';
        
        return `
        <a href="${auctionUrl}" class="auction-card">
            <div class="auction-card-header">
                <span class="auction-status ${String(auction.status || '').toLowerCase().replace(/[^a-z0-9_-]/g, '')}">${auction.demo ? '演示 · ' : ''}${escapeHtml(auction.statusText || '')}</span>
                <span style="font-size:11px;color:rgba(255,255,255,0.3);">${escapeHtml(auction.auctionNo || '')}</span>
            </div>
            <div class="auction-card-body">
                <h3 class="auction-title">${escapeHtml(auction.productName)}</h3>
                <p class="auction-company">采购主体 · ${escapeHtml(auction.buyerCompany || '易采贸易')}</p>
                
                <div class="auction-info">
                    <div class="auction-info-item">
                        <span class="auction-info-label">最高限价</span>
                        <span class="auction-info-value price">${formatAuctionMoney(auction.startingPrice, currency)}</span>
                    </div>
                    <div class="auction-info-item">
                        <span class="auction-info-label">当前最低价</span>
                        <span class="auction-info-value price lowest">${formatAuctionMoney(auction.currentLowestPrice, currency)}</span>
                    </div>
                    <div class="auction-info-item">
                        <span class="auction-info-label">采购数量</span>
                        <span class="auction-info-value">${escapeHtml(String(auction.quantity == null ? '-' : auction.quantity))} ${escapeHtml(auction.unit || '件')}</span>
                    </div>
                    <div class="auction-info-item">
                        <span class="auction-info-label">最小降幅</span>
                        <span class="auction-info-value">≥${formatAuctionMoney(auction.minDecrement, currency)}</span>
                    </div>
                </div>
                
                <div class="auction-timer">
                    <span class="auction-timer-label">${timerLabel}</span>
                    <span class="auction-timer-value" data-seconds="${Number(auction.remainingSeconds) || 0}" data-auction-id="${Number(auction.id) || 0}">
                        ${formatCountdown(auction.remainingSeconds)}
                    </span>
                    ${auction.currentExtensions > 0 ? `<span class="auction-extended">已延时${Number(auction.currentExtensions) || 0}次</span>` : ''}
                </div>
            </div>
            <div class="auction-card-footer">
                <div class="auction-stats">
                    <div class="auction-stat">
                        <span class="auction-stat-value">${isSignup ? (auction.signupCount || 0) : (auction.bidCount || 0)}</span>
                        <span class="auction-stat-label">${isSignup ? '已报名' : '出价次数'}</span>
                    </div>
                    <div class="auction-stat">
                        <span class="auction-stat-value">${auction.participantCount || auction.signupCount || 0}</span>
                        <span class="auction-stat-label">${isSignup ? '最少' + auction.minParticipants + '家' : '参与供应商'}</span>
                    </div>
                </div>
                <div class="auction-action-hint">
                    ${isSignup ? '<span class="hint-signup">立即报名</span>' : 
                      (isActive ? '<span class="hint-bid">参与竞价</span>' : 
                       '<span class="hint-view">查看详情</span>')}
                </div>
            </div>
        </a>
    `}).join('');
    
    // 启动倒计时
    startAuctionCountdowns();
}

function renderEmptyAuctions() {
    const auctionGrid = document.getElementById('auctionGrid');
    if (!auctionGrid) return;
    
    auctionGrid.innerHTML = `
        <div class="auction-empty">
            <svg class="auction-empty-icon" viewBox="0 0 64 64" fill="none">
                <rect x="8" y="16" width="48" height="40" rx="4" stroke="#4ECDC4" stroke-width="2" fill="none"/>
                <path d="M8 28 L56 28" stroke="#4ECDC4" stroke-width="2"/>
                <circle cx="32" cy="44" r="8" stroke="#4ECDC4" stroke-width="2" fill="none"/>
                <path d="M32 40 L32 48 M28 44 L36 44" stroke="#4ECDC4" stroke-width="2"/>
            </svg>
            <p>暂无进行中的竞价</p>
            <p style="font-size:12px;margin-top:8px;">成为首个发起反向竞价的采购商</p>
        </div>
    `;
}

function formatPrice(price) {
    if (!price) return '0.00';
    return parseFloat(price).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatAuctionMoney(value, currency) {
    if (window.YICAI_AUCTION_DEMO) {
        return window.YICAI_AUCTION_DEMO.money(value, currency);
    }
    const symbols = { USD: '$', EUR: '€', GBP: '£', CNY: '¥', JPY: '¥' };
    return (symbols[currency] || `${currency} `) + formatPrice(value);
}

function formatCountdown(seconds) {
    if (!seconds || seconds <= 0) return '已结束';
    
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (days > 0) {
        return `${days}天 ${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function startAuctionCountdowns() {
    setInterval(() => {
        document.querySelectorAll('.auction-timer-value[data-seconds]').forEach(el => {
            let seconds = parseInt(el.getAttribute('data-seconds'));
            if (seconds > 0) {
                seconds--;
                el.setAttribute('data-seconds', seconds);
                el.textContent = formatCountdown(seconds);
                // 小于5分钟时添加紧急状态
                if (seconds < 300) {
                    el.classList.add('urgent');
                } else {
                    el.classList.remove('urgent');
                }
            }
        });
    }, 1000);
}

// 页面加载时初始化竞价模块
document.addEventListener('DOMContentLoaded', initAuctionSection);

/**
 * 首页右侧资讯面板 — 从后端 /api/news 加载最新平台宣传文案
 */
function loadHeroNews() {
    var container = document.getElementById('heroNewsList');
    if (!container) return;

    var backend = (function() {
        var port = window.location.port;
        if (!port || port === '80' || port === '443' || port === '8081') return '';
        return 'http://' + window.location.hostname + ':8081';
    })();
    fetch(backend + '/api/news/latest?size=4&lang=en')
        .then(function(r) { return r.json(); })
        .then(function(res) {
            if (res.code === 200 && res.data && res.data.length) {
                var html = '';
                for (var i = 0; i < res.data.length; i++) {
                    var n = res.data[i];
                    var tag = n.industryName || 'Platform';
                    var date = (n.publishTime || n.createdAt || '').substring(0, 10);
                    var summary = (n.content || '').replace(/<[^>]+>/g, '').substring(0, 140);
                    html += '<a href="news.html?id=' + n.id + '" class="hero-news-item">'
                        + '<div class="hero-news-tag">' + escapeHtml(tag) + '</div>'
                        + '<h4>' + escapeHtml(n.title || '') + '</h4>'
                        + '<p>' + escapeHtml(summary) + '</p>'
                        + '<span class="hero-news-time">' + date + '</span>'
                        + '</a>';
                }
                container.innerHTML = html;
            }
            // 加载失败或无数据时保留占位内容
        }).catch(function() { /* keep placeholder */ });
}

function escapeHtml(str) {
    var d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
}

/**
 * Hero Banner 数字统计动画
 */
function initHeroBannerStats() {
    var statNums = document.querySelectorAll('.hero-stat-num[data-target]');
    if (!statNums.length) return;

    var animateHeroNum = function(el) {
        var target = parseInt(el.getAttribute('data-target'));
        var duration = 2500;
        var step = target / (duration / 16);
        var current = 0;
        var update = function() {
            current += step;
            if (current < target) {
                el.textContent = Math.floor(current).toLocaleString();
                requestAnimationFrame(update);
            } else {
                el.textContent = target.toLocaleString();
            }
        };
        update();
    };

    var observer = new IntersectionObserver(function(entries) {
        entries.forEach(function(entry) {
            if (entry.isIntersecting) {
                animateHeroNum(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    statNums.forEach(function(el) { observer.observe(el); });
}

/**
 * Hero Banner 粒子效果 (CSS fallback - 当Three.js可用时跳过)
 */
function initHeroParticles() {
    // 如果Three.js已加载，three-visual.js会用WebGL接管，跳过CSS粒子
    if (window.THREE) return;

    var container = document.getElementById('heroParticles');
    if (!container) return;

    for (var i = 0; i < 30; i++) {
        var p = document.createElement('span');
        p.className = 'hero-particle';
        p.style.left = Math.random() * 100 + '%';
        p.style.top = (60 + Math.random() * 40) + '%';
        p.style.animationDuration = (6 + Math.random() * 10) + 's';
        p.style.animationDelay = (Math.random() * 8) + 's';
        p.style.width = (1 + Math.random() * 2) + 'px';
        p.style.height = p.style.width;
        container.appendChild(p);
    }
}

/**
 * 订单实时监控 - 动态滚动面板
 */
function initLiveMonitor() {
    var scroll = document.getElementById('liveMonitorScroll');
    if (!scroll) return;

    var orderData = [
        { type: 'production', icon: '&#9881;', id: 'DEMO-PO-001', text: 'Purchase order accepted; production slot reserved', progress: 10, color: 'green' },
        { type: 'quality',    icon: '&#9989;', id: 'DEMO-PO-001', text: 'Golden sample approved against signed specification', progress: 20, color: 'yellow' },
        { type: 'production', icon: '&#9881;', id: 'DEMO-PO-001', text: 'Raw materials received and incoming inspection passed', progress: 30, color: 'green' },
        { type: 'production', icon: '&#9881;', id: 'DEMO-PO-001', text: 'Mass production 35% complete', progress: 45, color: 'green' },
        { type: 'quality',    icon: '&#9989;', id: 'DEMO-PO-001', text: 'Inline inspection: dimensions and workmanship within limits', progress: 55, color: 'yellow' },
        { type: 'production', icon: '&#9881;', id: 'DEMO-PO-001', text: 'Mass production completed; export packing started', progress: 70, color: 'green' },
        { type: 'quality',    icon: '&#9989;', id: 'DEMO-PO-001', text: 'Pre-shipment inspection passed at AQL 1.5 / 2.5', progress: 82, color: 'yellow' },
        { type: 'shipping',   icon: '&#128666;', id: 'DEMO-PO-001', text: 'Booking confirmed; customs documents under review', progress: 88, color: 'blue' },
        { type: 'shipping',   icon: '&#128666;', id: 'DEMO-PO-001', text: 'Container gated in and export declaration released', progress: 93, color: 'blue' },
        { type: 'completed',  icon: '&#10004;', id: 'DEMO-PO-001', text: 'Shipment departed; document set shared with buyer', progress: 100, color: 'green' }
    ];

    var timeLabels = ['T+0', 'T+3d', 'T+6d', 'T+12d', 'T+15d', 'T+23d', 'T+25d', 'T+27d', 'T+29d', 'T+30d'];

    function renderItem(item, timeLabel) {
        return '<div class="live-order-item">' +
            '<div class="live-order-icon ' + item.type + '">' + item.icon + '</div>' +
            '<div class="live-order-info">' +
                '<span class="live-order-id">' + item.id + '</span>' +
                '<span class="live-order-text">' + item.text + '</span>' +
            '</div>' +
            '<div class="live-order-progress">' +
                '<div class="live-order-progress-fill ' + item.color + '" style="width:' + item.progress + '%"></div>' +
            '</div>' +
            '<span class="live-order-time">' + timeLabel + '</span>' +
        '</div>';
    }

    // 初始渲染
    var html = '';
    for (var i = 0; i < orderData.length; i++) {
        html += renderItem(orderData[i], timeLabels[i] || '1 hr ago');
    }
    scroll.innerHTML = html;

    // 自动滚动效果
    var scrollSpeed = 0.5;
    var scrollPos = 0;
    var paused = false;

    scroll.addEventListener('mouseenter', function() { paused = true; });
    scroll.addEventListener('mouseleave', function() { paused = false; });

    function autoScroll() {
        if (!paused) {
            scrollPos += scrollSpeed;
            if (scrollPos >= scroll.scrollHeight - scroll.clientHeight) {
                scrollPos = 0;
            }
            scroll.scrollTop = scrollPos;
        }
        requestAnimationFrame(autoScroll);
    }
    requestAnimationFrame(autoScroll);

}

/**
 * 智能匹配快捷表单处理
 */
function handleQuickMatch(e) {
    e.preventDefault();
    var product = document.getElementById('qmProduct').value.trim();
    var quantity = document.getElementById('qmQuantity').value.trim();
    var destination = document.getElementById('qmDestination').value.trim();

    if (!product) {
        alert('Please enter a product name / 请输入产品名称');
        return false;
    }

    var params = 'product=' + encodeURIComponent(product);
    if (quantity) params += '&quantity=' + encodeURIComponent(quantity);
    if (destination) params += '&destination=' + encodeURIComponent(destination);

    window.location.href = 'smart-match.html?' + params;
    return false;
}
