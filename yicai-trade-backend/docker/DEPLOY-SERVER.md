# 易采后端单机部署

目标服务器：Alibaba Cloud Linux 3，2 vCPU / 4 GiB，公网 IP `47.243.212.90`。

## 1. DNS

在阿里云云解析添加 A 记录：

- 主机记录：`api`
- 记录值：`47.243.212.90`
- TTL：默认

部署前确认 `api.chainnexlink.com` 已解析到该 IP。Caddy 会自动申请和续期 HTTPS 证书。

## 2. 上传与解压

通过 Workbench 文件管理器把部署包上传到 `/opt/yicai-trade/`，然后执行：

```bash
cd /opt/yicai-trade
unzip -o yicai-backend-deploy-20260715.zip
chmod +x docker/bootstrap-server.sh docker/server-init.sh
```

## 3. Docker

检查 Docker：

```bash
docker --version
docker compose version
```

如果没有安装，先执行：

```bash
bash docker/server-init.sh
```

## 4. 启动

```bash
bash docker/bootstrap-server.sh
```

脚本首次运行会在 `docker/.env` 中生成随机 MySQL、Redis 和 JWT 密钥，权限为 `600`。不要把该文件下载、提交或公开。

## 5. 验证

```bash
cd /opt/yicai-trade/docker
docker compose ps
docker compose logs --tail=120 yicai-backend
curl -fsS https://api.chainnexlink.com/healthz
```

正常响应应包含 `"status":"UP"`。

## 6. 防火墙

公网仅保留 `22/tcp`、`80/tcp`、`443/tcp`。MySQL、Redis 和 Spring Boot 8081 仅位于 Docker 内网，不应映射到宿主机或安全组。
