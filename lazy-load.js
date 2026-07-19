/**
 * 易采贸易平台 - 懒加载工具库
 * 提供图片懒加载、组件延迟加载、分页数据懒加载等功能
 */

(function(window) {
    'use strict';

    const LazyLoad = {
        // 配置
        config: {
            rootMargin: '50px 0px',
            threshold: 0.1,
            loadingClass: 'lazy-loading',
            loadedClass: 'lazy-loaded',
            errorClass: 'lazy-error'
        },

        // 观察器实例
        observer: null,

        /**
         * 初始化懒加载
         */
        init: function(options = {}) {
            Object.assign(this.config, options);
            
            if ('IntersectionObserver' in window) {
                this.observer = new IntersectionObserver(
                    this.handleIntersection.bind(this),
                    {
                        rootMargin: this.config.rootMargin,
                        threshold: this.config.threshold
                    }
                );
                console.log('懒加载初始化完成 (IntersectionObserver)');
            } else {
                console.log('浏览器不支持IntersectionObserver，使用降级方案');
                this.fallbackLoad();
            }

            // 自动绑定所有懒加载图片
            this.observeImages();
            // 自动绑定懒加载组件
            this.observeComponents();
            
            return this;
        },

        /**
         * 处理元素进入视口
         */
        handleIntersection: function(entries, observer) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const el = entry.target;
                    
                    if (el.dataset.lazySrc) {
                        this.loadImage(el);
                    } else if (el.dataset.lazyComponent) {
                        this.loadComponent(el);
                    } else if (el.dataset.lazyHtml) {
                        this.loadHtml(el);
                    }
                    
                    observer.unobserve(el);
                }
            });
        },

        /**
         * 观察所有懒加载图片
         */
        observeImages: function() {
            const images = document.querySelectorAll('img[data-lazy-src]');
            images.forEach(img => {
                img.classList.add(this.config.loadingClass);
                if (this.observer) {
                    this.observer.observe(img);
                }
            });
            console.log(`已注册 ${images.length} 个懒加载图片`);
        },

        /**
         * 观察所有懒加载组件
         */
        observeComponents: function() {
            const components = document.querySelectorAll('[data-lazy-component]');
            components.forEach(el => {
                if (this.observer) {
                    this.observer.observe(el);
                }
            });
            console.log(`已注册 ${components.length} 个懒加载组件`);
        },

        /**
         * 加载图片
         */
        loadImage: function(img) {
            const src = img.dataset.lazySrc;
            const srcset = img.dataset.lazySrcset;
            
            // 创建临时图片预加载
            const tempImg = new Image();
            
            tempImg.onload = () => {
                img.src = src;
                if (srcset) img.srcset = srcset;
                img.classList.remove(this.config.loadingClass);
                img.classList.add(this.config.loadedClass);
                img.removeAttribute('data-lazy-src');
                img.removeAttribute('data-lazy-srcset');
            };
            
            tempImg.onerror = () => {
                img.classList.remove(this.config.loadingClass);
                img.classList.add(this.config.errorClass);
                console.warn('图片加载失败:', src);
            };
            
            tempImg.src = src;
        },

        /**
         * 加载组件（通过AJAX获取HTML片段）
         */
        loadComponent: function(container) {
            const url = container.dataset.lazyComponent;
            const callback = container.dataset.lazyCallback;
            
            container.innerHTML = '<div class="lazy-loading-spinner"></div>';
            
            fetch(url)
                .then(response => {
                    if (!response.ok) throw new Error('加载失败');
                    return response.text();
                })
                .then(html => {
                    container.innerHTML = html;
                    container.classList.add(this.config.loadedClass);
                    container.removeAttribute('data-lazy-component');
                    
                    // 执行回调
                    if (callback && typeof window[callback] === 'function') {
                        window[callback](container);
                    }
                    
                    // 触发自定义事件
                    container.dispatchEvent(new CustomEvent('lazyLoaded', { detail: { url } }));
                })
                .catch(error => {
                    container.innerHTML = '<div class="lazy-error-msg">加载失败，请刷新重试</div>';
                    container.classList.add(this.config.errorClass);
                    console.error('组件加载失败:', url, error);
                });
        },

        /**
         * 加载内联HTML（用于Tab内容等）
         */
        loadHtml: function(container) {
            const templateId = container.dataset.lazyHtml;
            const template = document.getElementById(templateId);
            
            if (template) {
                container.innerHTML = template.innerHTML;
                container.classList.add(this.config.loadedClass);
                container.removeAttribute('data-lazy-html');
            }
        },

        /**
         * 手动触发加载
         */
        load: function(selector) {
            const elements = typeof selector === 'string' 
                ? document.querySelectorAll(selector) 
                : [selector];
            
            elements.forEach(el => {
                if (el.dataset.lazySrc) {
                    this.loadImage(el);
                } else if (el.dataset.lazyComponent) {
                    this.loadComponent(el);
                } else if (el.dataset.lazyHtml) {
                    this.loadHtml(el);
                }
            });
        },

        /**
         * 添加新元素到观察列表
         */
        observe: function(element) {
            if (this.observer && element) {
                this.observer.observe(element);
            }
        },

        /**
         * 降级方案：直接加载所有内容
         */
        fallbackLoad: function() {
            document.querySelectorAll('img[data-lazy-src]').forEach(img => {
                this.loadImage(img);
            });
            document.querySelectorAll('[data-lazy-component]').forEach(el => {
                this.loadComponent(el);
            });
        },

        /**
         * 销毁观察器
         */
        destroy: function() {
            if (this.observer) {
                this.observer.disconnect();
                this.observer = null;
            }
        }
    };

    /**
     * Tab内容懒加载管理器
     * 适用于大型页面的Tab切换场景
     */
    const TabLazyLoader = {
        loadedTabs: new Set(),

        /**
         * 初始化Tab懒加载
         */
        init: function(tabContainer, contentContainer) {
            this.tabContainer = document.querySelector(tabContainer);
            this.contentContainer = document.querySelector(contentContainer);
            
            if (!this.tabContainer || !this.contentContainer) return;
            
            this.bindEvents();
            console.log('Tab懒加载初始化完成');
        },

        /**
         * 绑定Tab切换事件
         */
        bindEvents: function() {
            this.tabContainer.addEventListener('click', (e) => {
                const tab = e.target.closest('[data-lazy-tab]');
                if (tab) {
                    this.loadTabContent(tab.dataset.lazyTab);
                }
            });
        },

        /**
         * 加载Tab内容
         */
        loadTabContent: function(tabId) {
            if (this.loadedTabs.has(tabId)) {
                return; // 已加载过
            }

            const content = this.contentContainer.querySelector(`[data-tab-content="${tabId}"]`);
            if (!content) return;

            const url = content.dataset.lazyUrl;
            if (!url) {
                this.loadedTabs.add(tabId);
                return;
            }

            content.innerHTML = '<div class="tab-loading"><div class="spinner"></div><p>加载中...</p></div>';

            fetch(url)
                .then(response => response.text())
                .then(html => {
                    content.innerHTML = html;
                    this.loadedTabs.add(tabId);
                    content.dispatchEvent(new CustomEvent('tabContentLoaded', { detail: { tabId } }));
                })
                .catch(error => {
                    content.innerHTML = '<div class="tab-error">内容加载失败</div>';
                    console.error('Tab内容加载失败:', tabId, error);
                });
        },

        /**
         * 预加载指定Tab
         */
        preload: function(tabIds) {
            tabIds.forEach(id => this.loadTabContent(id));
        }
    };

    /**
     * 无限滚动加载器
     * 适用于列表数据分页加载
     */
    const InfiniteScroll = {
        config: {
            threshold: 200,
            loadingText: '加载更多...',
            noMoreText: '没有更多数据了'
        },

        /**
         * 初始化无限滚动
         */
        init: function(options) {
            Object.assign(this.config, options);
            
            this.container = document.querySelector(options.container);
            this.loader = options.loader; // 数据加载函数
            this.page = 1;
            this.hasMore = true;
            this.loading = false;

            if (!this.container || !this.loader) {
                console.error('InfiniteScroll: 缺少必要参数');
                return;
            }

            this.createLoadingIndicator();
            this.bindScrollEvent();
            
            console.log('无限滚动初始化完成');
            return this;
        },

        /**
         * 创建加载指示器
         */
        createLoadingIndicator: function() {
            this.indicator = document.createElement('div');
            this.indicator.className = 'infinite-scroll-indicator';
            this.indicator.innerHTML = `<span class="spinner-small"></span> ${this.config.loadingText}`;
            this.indicator.style.display = 'none';
            this.container.after(this.indicator);
        },

        /**
         * 绑定滚动事件
         */
        bindScrollEvent: function() {
            const scrollHandler = this.throttle(() => {
                if (this.loading || !this.hasMore) return;

                const containerRect = this.container.getBoundingClientRect();
                const containerBottom = containerRect.bottom;
                const windowHeight = window.innerHeight;

                if (containerBottom - windowHeight < this.config.threshold) {
                    this.loadMore();
                }
            }, 200);

            window.addEventListener('scroll', scrollHandler);
            this.scrollHandler = scrollHandler;
        },

        /**
         * 加载更多数据
         */
        loadMore: async function() {
            this.loading = true;
            this.indicator.style.display = 'block';

            try {
                const result = await this.loader(this.page + 1);
                
                if (result && result.items && result.items.length > 0) {
                    this.page++;
                    this.hasMore = result.hasMore !== false;
                } else {
                    this.hasMore = false;
                }

                if (!this.hasMore) {
                    this.indicator.innerHTML = this.config.noMoreText;
                }
            } catch (error) {
                console.error('加载更多数据失败:', error);
            } finally {
                this.loading = false;
                if (this.hasMore) {
                    this.indicator.style.display = 'none';
                }
            }
        },

        /**
         * 重置状态
         */
        reset: function() {
            this.page = 1;
            this.hasMore = true;
            this.loading = false;
            this.indicator.innerHTML = `<span class="spinner-small"></span> ${this.config.loadingText}`;
            this.indicator.style.display = 'none';
        },

        /**
         * 节流函数
         */
        throttle: function(func, limit) {
            let inThrottle;
            return function() {
                const args = arguments;
                const context = this;
                if (!inThrottle) {
                    func.apply(context, args);
                    inThrottle = true;
                    setTimeout(() => inThrottle = false, limit);
                }
            };
        },

        /**
         * 销毁
         */
        destroy: function() {
            if (this.scrollHandler) {
                window.removeEventListener('scroll', this.scrollHandler);
            }
            if (this.indicator) {
                this.indicator.remove();
            }
        }
    };

    // 导出到全局
    window.LazyLoad = LazyLoad;
    window.TabLazyLoader = TabLazyLoader;
    window.InfiniteScroll = InfiniteScroll;

    // DOM Ready后自动初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => LazyLoad.init());
    } else {
        LazyLoad.init();
    }

})(window);
