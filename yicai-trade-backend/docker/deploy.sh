#!/bin/bash
# ============================================
# 易采贸易平台 - 一键部署脚本
# 在项目根目录下执行: bash deploy.sh
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$SCRIPT_DIR"

echo "============================================"
echo "  易采贸易平台 - 生产部署"
echo "============================================"
echo "项目根目录: $PROJECT_ROOT"
echo "Docker目录: $DOCKER_DIR"
echo ""

# 检查.env文件
if [ ! -f "$DOCKER_DIR/.env" ]; then
    echo "[错误] 未找到 .env 配置文件!"
    echo ""
    echo "请先创建配置文件:"
    echo "  cp $DOCKER_DIR/.env.production $DOCKER_DIR/.env"
    echo "  vi $DOCKER_DIR/.env"
    echo ""
    echo "填写数据库地址、密码、AI API密钥等配置后重新运行此脚本。"
    exit 1
fi

# 验证必填配置
echo "[1/6] 验证配置..."
source "$DOCKER_DIR/.env"

MISSING=""
[ -z "$DB_HOST" ] || [ "$DB_HOST" = "你的RDS内网地址" ] && MISSING="$MISSING DB_HOST"
[ -z "$DB_PASSWORD" ] || [ "$DB_PASSWORD" = "你的数据库密码" ] && MISSING="$MISSING DB_PASSWORD"
[ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" = "请替换为一个至少64字符的随机安全密钥" ] && MISSING="$MISSING JWT_SECRET"

if [ -n "$MISSING" ]; then
    echo "[错误] 以下必填配置项未填写:$MISSING"
    echo "请编辑 $DOCKER_DIR/.env 文件填写后重试。"
    exit 1
fi

echo "  配置验证通过。"

# 检查Docker
echo ""
echo "[2/6] 检查Docker环境..."
if ! command -v docker &> /dev/null; then
    echo "[错误] Docker 未安装! 请先运行 server-init.sh"
    exit 1
fi
if ! command -v docker-compose &> /dev/null; then
    echo "[错误] Docker Compose 未安装! 请先运行 server-init.sh"
    exit 1
fi
echo "  Docker: $(docker --version)"
echo "  Compose: $(docker-compose --version)"

# 测试数据库连接
echo ""
echo "[3/6] 测试数据库连接..."
if command -v mysql &> /dev/null; then
    if mysql -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" &> /dev/null; then
        echo "  数据库连接成功。"
    else
        echo "  [警告] 数据库连接失败，请检查配置。部署将继续，但应用可能无法启动。"
    fi
else
    echo "  [跳过] mysql客户端未安装，跳过数据库连接测试。"
fi

# 创建数据库 (如果不存在)
echo ""
echo "[4/6] 检查数据库..."
if command -v mysql &> /dev/null; then
    mysql -h "$DB_HOST" -P "${DB_PORT:-3306}" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
        -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME:-yicai_trade}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null && \
        echo "  数据库 ${DB_NAME:-yicai_trade} 已就绪。" || \
        echo "  [警告] 无法创建数据库，请确保数据库已手动创建。"
else
    echo "  [跳过] 请确保数据库 ${DB_NAME:-yicai_trade} 已在RDS控制台创建。"
fi

# 构建和启动
echo ""
echo "[5/6] 构建并启动服务..."
cd "$DOCKER_DIR"

# 停止旧服务 (如果有)
docker-compose down 2>/dev/null || true

# 构建并启动
docker-compose --env-file .env up -d --build

echo ""
echo "[6/6] 等待服务启动..."
echo "  (后端Java应用首次启动需要60-90秒，请耐心等待)"
echo ""

# 等待后端健康检查通过
MAX_WAIT=180
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' yicai-trade-backend 2>/dev/null || echo "unknown")
    if [ "$STATUS" = "healthy" ]; then
        echo "  后端服务已启动! (等待了 ${WAITED}秒)"
        break
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo "  等待中... ${WAITED}s (状态: $STATUS)"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo ""
    echo "[警告] 后端服务在 ${MAX_WAIT}秒 内未通过健康检查。"
    echo "请查看日志: docker logs yicai-trade-backend"
fi

# 最终状态
echo ""
echo "============================================"
echo "  部署状态"
echo "============================================"
docker-compose ps
echo ""
echo "============================================"
echo "  访问地址: http://$(hostname -I | awk '{print $1}')"
echo "============================================"
echo ""
echo "常用命令:"
echo "  查看日志: docker logs -f yicai-trade-backend"
echo "  重启服务: cd $DOCKER_DIR && docker-compose restart"
echo "  停止服务: cd $DOCKER_DIR && docker-compose down"
echo "  更新部署: cd $DOCKER_DIR && docker-compose up -d --build"
echo "============================================"
