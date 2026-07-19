#!/bin/bash
# ============================================
# 易采贸易平台 - 服务器初始化脚本
# 在阿里云ECS (Alibaba Linux 3) 上运行
# ============================================

set -e

echo "============================================"
echo "  易采贸易平台 - 服务器环境初始化"
echo "============================================"

# 1. 系统更新
echo ""
echo "[1/5] 更新系统包..."
yum update -y

# 2. 安装Docker
echo ""
echo "[2/5] 安装Docker..."
if command -v docker &> /dev/null; then
    echo "Docker 已安装: $(docker --version)"
else
    yum install -y yum-utils
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    echo "Docker 安装完成: $(docker --version)"
fi

# 3. 安装Docker Compose
echo ""
echo "[3/5] 安装Docker Compose..."
if command -v docker-compose &> /dev/null; then
    echo "Docker Compose 已安装: $(docker-compose --version)"
else
    # 使用Docker Compose V2 plugin
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    # 创建兼容性软链接
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    echo "Docker Compose 安装完成: $(docker-compose --version)"
fi

# 4. 配置Docker镜像加速 (阿里云)
echo ""
echo "[4/5] 配置Docker镜像加速..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'DOCKEREOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://docker.m.daocloud.io"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "50m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
DOCKEREOF
systemctl daemon-reload
systemctl restart docker

# 5. 创建项目目录
echo ""
echo "[5/5] 创建项目目录..."
mkdir -p /opt/yicai-trade
mkdir -p /opt/yicai-trade/logs

echo ""
echo "============================================"
echo "  服务器环境初始化完成!"
echo "============================================"
echo ""
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo ""
echo "下一步: 上传项目代码到 /opt/yicai-trade/"
echo "============================================"
