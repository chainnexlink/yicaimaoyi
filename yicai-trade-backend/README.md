# 易采贸易平台 Spring Boot 后端

## 技术栈

- Java 17
- Spring Boot 3.2.2
- Spring Security 6 + JWT
- Spring Data JPA
- Spring Data Redis
- MySQL (阿里云PolarDB)
- Flyway 数据库迁移
- Docker 容器化部署

## 项目结构

```
yicai-trade-backend/
├── src/main/java/com/yicai/trade/
│   ├── YiCaiTradeApplication.java     # 启动类
│   ├── common/                        # 通用模块
│   │   ├── config/                    # 配置类
│   │   ├── security/                  # JWT安全组件
│   │   ├── exception/                 # 异常处理
│   │   ├── response/                  # 统一响应
│   │   └── constant/                  # 常量枚举
│   └── module/                        # 业务模块
│       ├── auth/                      # 认证模块
│       ├── supplier/                  # 供应商模块
│       ├── buyer/                     # 采购商模块
│       ├── order/                     # 订单模块
│       └── ...
├── src/main/resources/
│   ├── application.yml                # 主配置
│   └── db/migration/                  # 数据库迁移脚本
└── docker/                            # Docker配置
```

## 快速开始

### 1. 环境要求

- JDK 17+
- Maven 3.9+
- MySQL 8.0+ (或阿里云PolarDB)
- Redis 7.x

### 2. 配置数据库

复制 `.env.example` 为 `.env` 并填写数据库连接信息：

```bash
cp .env.example .env
```

### 3. 本地开发

```bash
# 编译项目
mvn clean compile

# 运行项目
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### 4. Docker部署

```bash
cd docker

# 启动所有服务
docker-compose up -d --build

# 查看日志
docker-compose logs -f yicai-backend

# 停止服务
docker-compose down
```

## API文档

启动后访问: http://localhost:8081/swagger-ui.html

## 管理员账号

生产环境不提供默认管理员密码，请通过受控运维流程创建并立即启用多因素认证。

## API接口

### 认证模块

| 方法 | 路径 | 说明 |
|-----|------|-----|
| POST | /api/auth/login | 用户登录 |
| POST | /api/auth/register | 用户注册 |
| POST | /api/auth/refresh | 刷新Token |
| POST | /api/auth/logout | 用户登出 |

### 请求示例

**登录**
```json
POST /api/auth/login
{
  "account": "your-account",
  "password": "your-password"
}
```

**注册**
```json
POST /api/auth/register
{
  "username": "buyer001",
  "password": "123456",
  "email": "buyer@example.com",
  "phone": "13800138000",
  "userType": "BUYER"
}
```
