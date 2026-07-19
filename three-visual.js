/**
 * three-visual.js - 3D数据可视化增强 v3
 * 易采贸易平台首页 - 强化科技视觉效果
 * Hero: 波浪网格 | Sections: 数据流Canvas
 */
(function () {
    'use strict';

    // ==================== 设备能力检测 ====================
    function detectCapability() {
        var w = window.innerWidth;
        var isMobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
        var cores = navigator.hardwareConcurrency || 2;
        if (w < 768 || isMobile) return 'low';
        if (w < 1024 || cores < 4) return 'medium';
        return 'high';
    }

    var capability = detectCapability();

    // ==================== 帧率监控 ====================
    var fpsMonitor = {
        frames: [],
        lowCount: 0,
        degraded: false,
        startTime: performance.now(),
        tick: function () {
            // 前8秒为预热期，不检测
            if (performance.now() - this.startTime < 8000) return;
            this.frames.push(performance.now());
            if (this.frames.length > 61) this.frames.shift();
            if (this.frames.length < 10) return;
            var elapsed = this.frames[this.frames.length - 1] - this.frames[0];
            var fps = (this.frames.length - 1) / (elapsed / 1000);
            if (fps < 5) this.lowCount++;
            else this.lowCount = Math.max(0, this.lowCount - 2);
            if (this.lowCount > 120 && !this.degraded) {
                this.degraded = true;
                console.warn('[three-visual] FPS critically low, degrading Three.js...');
                if (window._heroScene) window._heroScene.dispose();
            }
        }
    };

    // ==================== Hero 波浪网格可视化 ====================
    function HeroWaveMesh(canvas) {
        if (!window.THREE) return;
        this.canvas = canvas;
        this.running = false;
        this.mouse = { x: 0, y: 0 };
        this.time = 0;
        this.gridW = capability === 'high' ? 45 : 30;
        this.gridH = capability === 'high' ? 22 : 15;
        this.initScene();
        this.createGrid();
        this.createGlowRings();
        this.setupObserver();
        this.bindEvents();
        this.running = true;
        this.animate();
    }

    HeroWaveMesh.prototype.initScene = function () {
        var THREE = window.THREE;
        var rect = this.canvas.parentElement.getBoundingClientRect();
        this.scene = new THREE.Scene();
        this.scene.fog = new THREE.FogExp2(0x000810, 0.028);
        this.camera = new THREE.PerspectiveCamera(55, rect.width / rect.height, 0.1, 100);
        this.camera.position.set(0, 8, 18);
        this.camera.lookAt(0, 0, 0);
        this.renderer = new THREE.WebGLRenderer({
            canvas: this.canvas,
            alpha: true,
            antialias: true,
            powerPreference: 'high-performance'
        });
        this.renderer.setSize(rect.width, rect.height);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    };

    HeroWaveMesh.prototype.createGrid = function () {
        var THREE = window.THREE;
        var gw = this.gridW, gh = this.gridH;
        var spacing = 0.8;
        var totalW = gw * spacing;
        var totalH = gh * spacing;

        // Grid points
        var pointCount = gw * gh;
        var positions = new Float32Array(pointCount * 3);
        var colors = new Float32Array(pointCount * 3);

        for (var j = 0; j < gh; j++) {
            for (var i = 0; i < gw; i++) {
                var idx = (j * gw + i) * 3;
                positions[idx] = i * spacing - totalW / 2;
                positions[idx + 1] = 0;
                positions[idx + 2] = j * spacing - totalH / 2;
                colors[idx] = 0.0;
                colors[idx + 1] = 0.9;
                colors[idx + 2] = 0.8;
            }
        }

        var pointGeo = new THREE.BufferGeometry();
        pointGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        pointGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        var pointMat = new THREE.PointsMaterial({
            size: 1.2,
            transparent: true,
            opacity: 0.4,
            vertexColors: true,
            sizeAttenuation: true,
            blending: THREE.AdditiveBlending,
            depthWrite: false
        });

        this.gridPoints = new THREE.Points(pointGeo, pointMat);
        this.scene.add(this.gridPoints);

        // Grid lines (horizontal + vertical)
        var lineCount = (gw - 1) * gh + gw * (gh - 1);
        var linePositions = new Float32Array(lineCount * 6);
        var lineColors = new Float32Array(lineCount * 6);

        var lineGeo = new THREE.BufferGeometry();
        lineGeo.setAttribute('position', new THREE.BufferAttribute(linePositions, 3));
        lineGeo.setAttribute('color', new THREE.BufferAttribute(lineColors, 3));

        var lineMat = new THREE.LineBasicMaterial({
            vertexColors: true,
            transparent: true,
            opacity: 0.18,
            blending: THREE.AdditiveBlending,
            depthWrite: false
        });

        this.gridLines = new THREE.LineSegments(lineGeo, lineMat);
        this.scene.add(this.gridLines);

        this.spacing = spacing;
        this.totalW = totalW;
        this.totalH = totalH;
    };

    HeroWaveMesh.prototype.createGlowRings = function () {
        var THREE = window.THREE;
        this.glowRings = [];
        for (var i = 0; i < 3; i++) {
            var geo = new THREE.RingGeometry(4 + i * 3, 4.08 + i * 3, 64);
            var mat = new THREE.MeshBasicMaterial({
                color: i === 0 ? 0x00E5CC : (i === 1 ? 0x4466FF : 0x8844FF),
                transparent: true,
                opacity: 0.06,
                side: THREE.DoubleSide,
                blending: THREE.AdditiveBlending,
                depthWrite: false
            });
            var ring = new THREE.Mesh(geo, mat);
            ring.rotation.x = Math.PI / 2;
            ring.position.y = -0.5;
            ring.userData = { speed: 0.15 + i * 0.1, baseOpacity: 0.06 };
            this.scene.add(ring);
            this.glowRings.push(ring);
        }
    };

    HeroWaveMesh.prototype.bindEvents = function () {
        var self = this;
        this._onMouseMove = function (e) {
            var rect = self.canvas.getBoundingClientRect();
            self.mouse.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
            self.mouse.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
        };
        this._onResize = function () {
            var rect = self.canvas.parentElement.getBoundingClientRect();
            self.camera.aspect = rect.width / rect.height;
            self.camera.updateProjectionMatrix();
            self.renderer.setSize(rect.width, rect.height);
        };
        window.addEventListener('mousemove', self._onMouseMove);
        window.addEventListener('resize', self._onResize);
    };

    HeroWaveMesh.prototype.setupObserver = function () {
        var self = this;
        if (!('IntersectionObserver' in window)) return;
        this._observer = new IntersectionObserver(function (entries) {
            self.running = entries[0].isIntersecting;
        }, { threshold: 0.05 });
        this._observer.observe(this.canvas.parentElement);
    };

    HeroWaveMesh.prototype.animate = function () {
        var self = this;
        if (fpsMonitor.degraded) return;
        requestAnimationFrame(function () { self.animate(); });
        if (!self.running) return;

        fpsMonitor.tick();
        self.time += 0.01;

        var gw = self.gridW, gh = self.gridH;
        var spacing = self.spacing;
        var totalW = self.totalW, totalH = self.totalH;
        var t = self.time;

        // Mouse world position (approximate projection onto grid plane)
        var mouseWX = self.mouse.x * totalW * 0.5;
        var mouseWZ = -self.mouse.y * totalH * 0.5;

        // Update grid point positions with multi-layer waves
        var pos = self.gridPoints.geometry.attributes.position.array;
        var col = self.gridPoints.geometry.attributes.color.array;

        for (var j = 0; j < gh; j++) {
            for (var i = 0; i < gw; i++) {
                var idx = (j * gw + i) * 3;
                var x = i * spacing - totalW / 2;
                var z = j * spacing - totalH / 2;

                // Multi-layer sine wave displacement
                var y = 0;
                y += Math.sin(x * 0.3 + t * 2.0) * 0.6;
                y += Math.sin(z * 0.4 + t * 1.5) * 0.4;
                y += Math.sin((x + z) * 0.2 + t * 1.0) * 0.3;
                y += Math.cos(x * 0.5 - z * 0.3 + t * 2.5) * 0.2;

                // Mouse influence - localized wave peak
                var mdx = x - mouseWX;
                var mdz = z - mouseWZ;
                var mDist = Math.sqrt(mdx * mdx + mdz * mdz);
                if (mDist < 6) {
                    y += Math.cos(mDist * 0.8) * (1.0 - mDist / 6) * 1.5;
                }

                pos[idx] = x;
                pos[idx + 1] = y;
                pos[idx + 2] = z;

                // Color based on height: low=deep blue, mid=cyan, high=bright cyan
                var h = (y + 2) / 4;
                h = Math.max(0, Math.min(1, h));
                col[idx] = h * 0.3;
                col[idx + 1] = 0.5 + h * 0.5;
                col[idx + 2] = 0.7 + h * 0.3;
            }
        }
        self.gridPoints.geometry.attributes.position.needsUpdate = true;
        self.gridPoints.geometry.attributes.color.needsUpdate = true;

        // Update grid lines to follow point positions
        var linePos = self.gridLines.geometry.attributes.position.array;
        var lineCol = self.gridLines.geometry.attributes.color.array;
        var li = 0;

        // Horizontal lines
        for (var hj = 0; hj < gh; hj++) {
            for (var hi = 0; hi < gw - 1; hi++) {
                var pi1 = (hj * gw + hi) * 3;
                var pi2 = (hj * gw + hi + 1) * 3;
                var base = li * 6;
                linePos[base] = pos[pi1]; linePos[base + 1] = pos[pi1 + 1]; linePos[base + 2] = pos[pi1 + 2];
                linePos[base + 3] = pos[pi2]; linePos[base + 4] = pos[pi2 + 1]; linePos[base + 5] = pos[pi2 + 2];
                var lh1 = (pos[pi1 + 1] + 2) / 4;
                var lh2 = (pos[pi2 + 1] + 2) / 4;
                lineCol[base] = lh1 * 0.2; lineCol[base + 1] = 0.4 + lh1 * 0.5; lineCol[base + 2] = 0.6 + lh1 * 0.3;
                lineCol[base + 3] = lh2 * 0.2; lineCol[base + 4] = 0.4 + lh2 * 0.5; lineCol[base + 5] = 0.6 + lh2 * 0.3;
                li++;
            }
        }
        // Vertical lines
        for (var vj = 0; vj < gh - 1; vj++) {
            for (var vi = 0; vi < gw; vi++) {
                var vi1 = (vj * gw + vi) * 3;
                var vi2 = ((vj + 1) * gw + vi) * 3;
                var vbase = li * 6;
                linePos[vbase] = pos[vi1]; linePos[vbase + 1] = pos[vi1 + 1]; linePos[vbase + 2] = pos[vi1 + 2];
                linePos[vbase + 3] = pos[vi2]; linePos[vbase + 4] = pos[vi2 + 1]; linePos[vbase + 5] = pos[vi2 + 2];
                var vh1 = (pos[vi1 + 1] + 2) / 4;
                var vh2 = (pos[vi2 + 1] + 2) / 4;
                lineCol[vbase] = vh1 * 0.2; lineCol[vbase + 1] = 0.4 + vh1 * 0.5; lineCol[vbase + 2] = 0.6 + vh1 * 0.3;
                lineCol[vbase + 3] = vh2 * 0.2; lineCol[vbase + 4] = 0.4 + vh2 * 0.5; lineCol[vbase + 5] = 0.6 + vh2 * 0.3;
                li++;
            }
        }
        self.gridLines.geometry.attributes.position.needsUpdate = true;
        self.gridLines.geometry.attributes.color.needsUpdate = true;

        // Glow rings pulse
        for (var r = 0; r < self.glowRings.length; r++) {
            var ring = self.glowRings[r];
            ring.rotation.z += ring.userData.speed * 0.01;
            ring.material.opacity = ring.userData.baseOpacity + Math.sin(t * 1.5 + r * 2) * 0.03;
        }

        // Camera breathing
        self.camera.position.x = Math.sin(t * 0.3) * 0.8;
        self.camera.position.y = 8 + Math.sin(t * 0.2) * 0.5;
        self.camera.lookAt(0, 0, 0);

        self.renderer.render(self.scene, self.camera);
    };

    HeroWaveMesh.prototype.pause = function () { this.running = false; };
    HeroWaveMesh.prototype.resume = function () { this.running = true; };
    HeroWaveMesh.prototype.dispose = function () {
        this.running = false;
        window.removeEventListener('mousemove', this._onMouseMove);
        window.removeEventListener('resize', this._onResize);
        if (this._observer) this._observer.disconnect();
        if (this.renderer) this.renderer.dispose();
    };

    // ==================== Canvas 2D 数据流（增强版） ====================
    function DataFlowCanvas(canvasEl) {
        this.canvas = canvasEl;
        this.ctx = canvasEl.getContext('2d');
        this.particleCount = capability === 'low' ? 30 : 80;
        this.particles = [];
        this.pulseTime = 0;
        this.running = false;
        this.resize();
        this.initParticles(this.particleCount);
        this.setupObserver();
        this._onResize = null;
        this.bindResize();
        this.running = true;
        this.animate();
    }

    DataFlowCanvas.prototype.resize = function () {
        var rect = this.canvas.parentElement.getBoundingClientRect();
        var dpr = Math.min(window.devicePixelRatio, 2);
        this.canvas.width = rect.width * dpr;
        this.canvas.height = rect.height * dpr;
        this.canvas.style.width = rect.width + 'px';
        this.canvas.style.height = rect.height + 'px';
        this.ctx.scale(dpr, dpr);
        this.w = rect.width;
        this.h = rect.height;
    };

    DataFlowCanvas.prototype.bindResize = function () {
        var self = this;
        this._onResize = function () {
            self.resize();
            // Re-scatter particles after resize
            self.particles = [];
            self.initParticles(self.particleCount);
        };
        window.addEventListener('resize', this._onResize);
    };

    DataFlowCanvas.prototype.initParticles = function (count) {
        for (var i = 0; i < count; i++) {
            var angle = Math.random() * Math.PI * 2;
            var radius = Math.max(this.w, this.h) * 0.6;
            this.particles.push({
                x: this.w / 2 + Math.cos(angle) * radius * (0.5 + Math.random() * 0.5),
                y: this.h / 2 + Math.sin(angle) * radius * (0.5 + Math.random() * 0.5),
                speed: 0.6 + Math.random() * 1.2,
                size: 1 + Math.random() * 3,
                alpha: 0.15 + Math.random() * 0.5,
                angle: angle + Math.PI,
                trail: []
            });
        }
    };

    DataFlowCanvas.prototype.setupObserver = function () {
        var self = this;
        if (!('IntersectionObserver' in window)) return;
        this._observer = new IntersectionObserver(function (entries) {
            self.running = entries[0].isIntersecting;
        }, { threshold: 0.05 });
        this._observer.observe(this.canvas);
    };

    DataFlowCanvas.prototype.animate = function () {
        var self = this;
        requestAnimationFrame(function () { self.animate(); });
        if (!self.running) return;

        var ctx = self.ctx;
        var w = self.w, h = self.h;
        // 半透明清除产生拖尾
        ctx.fillStyle = 'rgba(0,8,16,0.08)';
        ctx.fillRect(0, 0, w, h);
        self.pulseTime += 0.02;

        var cx = w / 2, cy = h / 2;
        for (var i = 0; i < self.particles.length; i++) {
            var p = self.particles[i];
            // 保存轨迹
            p.trail.push({ x: p.x, y: p.y });
            if (p.trail.length > 8) p.trail.shift();

            var dx = cx - p.x, dy = cy - p.y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 15) {
                var angle = Math.random() * Math.PI * 2;
                var r = Math.max(w, h) * 0.6;
                p.x = cx + Math.cos(angle) * r;
                p.y = cy + Math.sin(angle) * r;
                p.trail = [];
            } else {
                p.x += (dx / dist) * p.speed;
                p.y += (dy / dist) * p.speed;
            }

            // 绘制轨迹
            if (p.trail.length > 1) {
                ctx.beginPath();
                ctx.moveTo(p.trail[0].x, p.trail[0].y);
                for (var ti = 1; ti < p.trail.length; ti++) {
                    ctx.lineTo(p.trail[ti].x, p.trail[ti].y);
                }
                ctx.strokeStyle = 'rgba(0,229,204,' + (p.alpha * 0.3) + ')';
                ctx.lineWidth = p.size * 0.5;
                ctx.stroke();
            }

            // 绘制粒子
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(0,229,204,' + p.alpha + ')';
            ctx.fill();
        }

        // 连接线
        for (var a = 0; a < self.particles.length; a++) {
            for (var b = a + 1; b < self.particles.length; b++) {
                var ddx = self.particles[a].x - self.particles[b].x;
                var ddy = self.particles[a].y - self.particles[b].y;
                var dd = ddx * ddx + ddy * ddy;
                if (dd < 8100) {
                    var al = (1 - Math.sqrt(dd) / 90) * 0.15;
                    ctx.beginPath();
                    ctx.moveTo(self.particles[a].x, self.particles[a].y);
                    ctx.lineTo(self.particles[b].x, self.particles[b].y);
                    ctx.strokeStyle = 'rgba(0,229,204,' + al + ')';
                    ctx.lineWidth = 0.5;
                    ctx.stroke();
                }
            }
        }

        // 多层脉冲环
        for (var ring = 0; ring < 3; ring++) {
            var phase = (self.pulseTime + ring * 1.0) % 3;
            var pulseRadius = phase / 3 * Math.min(w, h) * 0.45;
            var pulseAlpha = 0.2 * (1 - phase / 3);
            ctx.beginPath();
            ctx.arc(cx, cy, pulseRadius, 0, Math.PI * 2);
            ctx.strokeStyle = 'rgba(0,229,204,' + pulseAlpha + ')';
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // 中心发光点
        var centerGlow = ctx.createRadialGradient(cx, cy, 0, cx, cy, 30);
        centerGlow.addColorStop(0, 'rgba(0,229,204,0.3)');
        centerGlow.addColorStop(1, 'rgba(0,229,204,0)');
        ctx.fillStyle = centerGlow;
        ctx.fillRect(cx - 30, cy - 30, 60, 60);
    };

    DataFlowCanvas.prototype.dispose = function () {
        this.running = false;
        if (this._observer) this._observer.disconnect();
        if (this._onResize) window.removeEventListener('resize', this._onResize);
    };

    // ==================== 监控波形（增强版） ====================
    function PulseWaveCanvas(canvasEl) {
        this.canvas = canvasEl;
        this.ctx = canvasEl.getContext('2d');
        this.data = [];
        this.running = true;
        for (var i = 0; i < 120; i++) this.data.push(0);
        this.setupObserver();
        this.animate();
    }

    PulseWaveCanvas.prototype.setupObserver = function () {
        var self = this;
        if (!('IntersectionObserver' in window)) return;
        this._observer = new IntersectionObserver(function (entries) {
            self.running = entries[0].isIntersecting;
        }, { threshold: 0.05 });
        this._observer.observe(this.canvas);
    };

    PulseWaveCanvas.prototype.animate = function () {
        var self = this;
        requestAnimationFrame(function () { self.animate(); });
        if (!self.running) return;

        var t = performance.now() * 0.003;
        var val = Math.sin(t) * 0.3 + Math.sin(t * 2.3) * 0.2 + Math.sin(t * 5.7) * 0.15;
        if (Math.random() < 0.02) val += (Math.random() - 0.5) * 1.5;
        this.data.push(val);
        if (this.data.length > 120) this.data.shift();

        var ctx = this.ctx;
        var w = this.canvas.width, h = this.canvas.height;
        ctx.clearRect(0, 0, w, h);

        // 发光填充
        ctx.beginPath();
        ctx.moveTo(0, h / 2);
        for (var i = 0; i < this.data.length; i++) {
            ctx.lineTo(i, h / 2 - this.data[i] * (h * 0.4));
        }
        ctx.lineTo(w, h / 2);
        ctx.closePath();
        var grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, 'rgba(0,229,204,0.15)');
        grad.addColorStop(1, 'rgba(0,229,204,0)');
        ctx.fillStyle = grad;
        ctx.fill();

        // 主线
        ctx.beginPath();
        ctx.moveTo(0, h / 2);
        for (var j = 0; j < this.data.length; j++) {
            ctx.lineTo(j, h / 2 - this.data[j] * (h * 0.4));
        }
        ctx.strokeStyle = '#00E5CC';
        ctx.lineWidth = 1.5;
        ctx.shadowColor = '#00E5CC';
        ctx.shadowBlur = 8;
        ctx.stroke();
        ctx.shadowBlur = 0;
    };

    PulseWaveCanvas.prototype.dispose = function () {
        this.running = false;
        if (this._observer) this._observer.disconnect();
    };

    // ==================== 鼠标跟随辉光（增强版） ====================
    function CursorGlow() {
        this.el = document.getElementById('cursorGlow');
        if (!this.el) return;
        this.targetX = -500;
        this.targetY = -500;
        this.currentX = -500;
        this.currentY = -500;
        var self = this;
        this._onMove = function (e) {
            self.targetX = e.clientX;
            self.targetY = e.clientY;
        };
        document.addEventListener('mousemove', this._onMove);
        this.animate();
    }

    CursorGlow.prototype.animate = function () {
        var self = this;
        requestAnimationFrame(function () { self.animate(); });
        self.currentX += (self.targetX - self.currentX) * 0.06;
        self.currentY += (self.targetY - self.currentY) * 0.06;
        if (self.el) {
            self.el.style.transform = 'translate(' + (self.currentX - 200) + 'px,' + (self.currentY - 200) + 'px)';
        }
    };

    CursorGlow.prototype.dispose = function () {
        document.removeEventListener('mousemove', this._onMove);
    };

    // ==================== 卡片3D倾斜 ====================
    function CardTiltEffect(selector) {
        this.cards = document.querySelectorAll(selector);
        this.bindAll();
    }

    CardTiltEffect.prototype.bindAll = function () {
        this.cards.forEach(function (card) {
            card.addEventListener('mousemove', function (e) {
                var rect = card.getBoundingClientRect();
                var x = (e.clientX - rect.left) / rect.width - 0.5;
                var y = (e.clientY - rect.top) / rect.height - 0.5;
                card.style.transform = 'perspective(800px) rotateY(' + (x * 12) + 'deg) rotateX(' + (-y * 12) + 'deg) translateY(-6px) scale(1.02)';
            });
            card.addEventListener('mouseleave', function () {
                card.style.transform = '';
            });
        });
    };

    // ==================== 数字雨（增强版） ====================
    function initDataRain() {
        var container = document.getElementById('dataRainContainer');
        if (!container) return;
        var items = ['SPEC', 'FOB', 'AQL', 'KYB', 'RFQ', 'QC', 'ETA', 'PO', 'HS CODE',
            'INCOTERM', 'SAMPLE', 'AUDIT', 'PACK', 'DOCS', 'CAPACITY', 'LEAD TIME', 'NDA', 'COA',
            'BOM', 'QA', 'COC', 'REACH', 'ROHS', 'TRACE'];
        var count = capability === 'low' ? 18 : 35;
        for (var i = 0; i < count; i++) {
            var span = document.createElement('span');
            span.className = 'data-rain-drop';
            span.textContent = items[i % items.length];
            span.style.left = (Math.random() * 100) + '%';
            span.style.animationDuration = (6 + Math.random() * 10) + 's';
            span.style.animationDelay = (Math.random() * 8) + 's';
            span.style.fontSize = (10 + Math.random() * 6) + 'px';
            container.appendChild(span);
        }
    }

    // ==================== 打字机效果 ====================
    function initTypewriter() {
        var el = document.querySelector('.hero-banner-tagline');
        if (!el) return;
        var items = el.querySelectorAll('.tagline-item');
        items.forEach(function (item) {
            var text = item.textContent;
            item.textContent = '';
            item.style.borderRight = '2px solid #00E5CC';
            item.style.display = 'inline-block';
            var idx = 0;
            var timer = setInterval(function () {
                if (idx < text.length) {
                    item.textContent += text[idx];
                    idx++;
                } else {
                    clearInterval(timer);
                    setTimeout(function () {
                        item.style.borderRight = 'none';
                    }, 1500);
                }
            }, 80);
        });
    }

    // ==================== 全局电路线动画 ====================
    function initCircuitLines() {
        var sections = document.querySelectorAll('.core-features-section, .quick-match-section, .auction-advantage-section, .live-monitor-section, .auction-section, .features-section, .quick-access, .news-insights-section');
        sections.forEach(function (sec) {
            sec.style.position = 'relative';
            sec.style.overflow = 'hidden';
            var line = document.createElement('div');
            line.className = 'circuit-line';
            sec.appendChild(line);
            var line2 = document.createElement('div');
            line2.className = 'circuit-line circuit-line-right';
            sec.appendChild(line2);
        });
    }

    // ==================== Glitch文字效果 ====================
    function initGlitchTitles() {
        var titles = document.querySelectorAll('.section-title');
        titles.forEach(function (title) {
            title.setAttribute('data-text', title.textContent);
            title.classList.add('glitch-title');
        });
    }

    // ==================== Section边框扫光 ====================
    function initSectionBorderSweep() {
        var cards = document.querySelectorAll('.core-card, .advantage-card, .feature-card, .quick-card, .news-insights-panel');
        cards.forEach(function (card) {
            var border = document.createElement('div');
            border.className = 'neon-border-sweep';
            card.style.position = 'relative';
            card.appendChild(border);
        });
    }

    // ==================== 数字统计跳动增强 ====================
    function enhanceHeroStats() {
        var nums = document.querySelectorAll('.hero-stat-num');
        nums.forEach(function (num) {
            num.classList.add('tech-number');
        });
    }

    // ==================== 全局扫描线覆盖 ====================
    function initGlobalScanOverlay() {
        var overlay = document.createElement('div');
        overlay.className = 'global-scan-overlay';
        document.body.appendChild(overlay);
    }

    // ==================== 初始化入口 ====================
    function init() {
        console.log('[three-visual] Capability:', capability);

        // 全局效果 - 所有设备
        initGlitchTitles();
        initDataRain();
        initCircuitLines();
        initSectionBorderSweep();
        enhanceHeroStats();
        initGlobalScanOverlay();

        // 打字机效果
        if (capability !== 'low') {
            initTypewriter();
        }

        // 鼠标辉光（中等及以上）
        if (capability !== 'low') {
            new CursorGlow();
        }

        // Hero 波浪网格（中等及以上 + Three.js可用）
        if (capability !== 'low' && window.THREE) {
            var heroCanvas = document.getElementById('heroThreeCanvas');
            if (heroCanvas) {
                window._heroScene = new HeroWaveMesh(heroCanvas);
                var cssParticles = document.getElementById('heroParticles');
                if (cssParticles) cssParticles.style.display = 'none';
            }
        }

        // 数据流Canvas - 所有功能模块（含手机端，粒子数按能力调整）
        {
            var canvasIds = ['quickMatchCanvas', 'coreFeaturesCanvas', 'featuresCanvas', 'quickAccessCanvas', 'newsCanvas', 'auctionAdvCanvas', 'liveMonitorCanvas', 'auctionCanvas'];
            for (var ci = 0; ci < canvasIds.length; ci++) {
                var cvs = document.getElementById(canvasIds[ci]);
                if (cvs) {
                    var inst = new DataFlowCanvas(cvs);
                    if (ci === 0) window._dataFlowCanvas = inst;
                }
            }
        }

        // 监控波形（中等及以上）
        if (capability !== 'low') {
            var pulseCanvas = document.getElementById('pulseCanvas');
            if (pulseCanvas) {
                new PulseWaveCanvas(pulseCanvas);
            }
        }

        // 卡片3D倾斜（中等及以上）
        if (capability !== 'low') {
            new CardTiltEffect('.core-card');
            new CardTiltEffect('.advantage-card');
            new CardTiltEffect('.feature-card');
            new CardTiltEffect('.quick-card');
        }
    }

    // 延迟初始化
    if ('requestIdleCallback' in window) {
        requestIdleCallback(function () { init(); }, { timeout: 1500 });
    } else {
        setTimeout(init, 300);
    }
})();
