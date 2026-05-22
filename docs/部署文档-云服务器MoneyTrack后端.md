# MoneyTrack 后端部署文档

## 环境信息

| 项目 | 值 |
|------|-----|
| 服务器公网 IP | 1.12.234.7 |
| 服务端口 | 8080 |
| 后端框架 | Express.js + sql.js |
| Node.js 版本 | >= 18 |

---

## 一、服务器准备

### 1.1 安装 Node.js（如果未安装）

```bash
# 使用 nvm 安装（推荐）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# 或直接安装
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs
node --version  # 确认 >= 18
```

### 1.2 安装 PM2（进程管理器）

```bash
npm install -g pm2
pm2 --version
```

### 1.3 开放服务器端口

在云服务器安全组/防火墙确认：
- **入方向**：允许 `TCP 8080` 端口
- 来源：`0.0.0.0/0`（或限定具体 IP 段）

---

## 二、项目部署

### 2.1 上传项目到服务器

```bash
# 从本机执行（需先配置 ssh 密钥）
scp -r C:/Users/SkyFragments/DevEcoStudioProjects/MoneyTrack1/moneytrack-api user@1.12.234.7:/opt/moneytrack-api

# 或使用 rsync（增量同步，已修改的文件）
rsync -avz --exclude='node_modules' --exclude='.env' moneytrack-api/ user@1.12.234.7:/opt/moneytrack-api/
```

### 2.2 服务器上安装依赖

```bash
ssh user@1.12.234.7
cd /opt/moneytrack-api
npm install --production
```

### 2.3 配置环境变量

```bash
cd /opt/moneytrack-api

# 创建 .env 文件（重要！JWT_SECRET 必须设置）
cat > .env << 'EOF'
PORT=8080
JWT_SECRET=请替换为随机字符串（至少32位，建议使用 uuid 或密码生成器）
JWT_ACCESS_EXPIRES=2h
JWT_REFRESH_EXPIRES=7d
EOF

# 修改权限（防止其他用户读取）
chmod 600 .env
```

**生成随机 JWT_SECRET 示例：**
```bash
# 方法1：使用 openssl
openssl rand -base64 32

# 方法2：使用 Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### 2.4 创建日志目录

```bash
mkdir -p /opt/moneytrack-api/logs
```

### 2.5 启动服务

```bash
cd /opt/moneytrack-api

# 方式一：使用 PM2（推荐，生产环境用）
pm2 start ecosystem.config.js

# 方式二：直接运行（调试用）
node src/index.js
```

### 2.6 验证服务

```bash
# 健康检查
curl http://1.12.234.7:8080/health
# 期望返回：{"status":"ok","timestamp":"2026-05-21T..."}

# 查看 PM2 状态
pm2 list
pm2 logs moneytrack-api --lines 20
```

---

## 三、PM2 常用命令

```bash
# 启动
pm2 start ecosystem.config.js

# 查看状态
pm2 list
pm2 status moneytrack-api

# 查看日志
pm2 logs moneytrack-api

# 重启
pm2 restart moneytrack-api

# 停止
pm2 stop moneytrack-api

# 开机自启（服务器重启后自动运行）
pm2 startup
pm2 save

# 取消开机自启
pm2 unstartup
```

---

## 四、服务管理

### 4.1 更新部署（代码变更后）

```bash
# 1. 上传更新后的代码
scp -r moneytrack-api/* user@1.12.234.7:/opt/moneytrack-api/

# 2. 重启服务
ssh user@1.12.234.7 "cd /opt/moneytrack-api && pm2 restart moneytrack-api"

# 3. 验证
curl http://1.12.234.7:8080/health
```

### 4.2 回滚版本

```bash
# 查看历史
pm2 list
pm2 history moneytrack-api

# 回滚到之前的版本
pm2 restart moneytrack-api --update-env
```

---

## 五、防火墙配置

### 5.1 云服务器安全组（阿里云/腾讯云示例）

| 方向 | 协议 | 端口范围 | 来源 |
|------|------|---------|------|
| 入方向 | TCP | 8080/8080 | 0.0.0.0/0 |
| 入方向 | TCP | 22/22 | 你的 IP |

### 5.2 服务器内部防火墙（Ubuntu/Debian）

```bash
# 查看防火墙状态
sudo ufw status

# 开放端口（如使用 ufw）
sudo ufw allow 8080/tcp
sudo ufw reload
```

---

## 六、故障排查

### 6.1 服务无法启动

```bash
# 查看详细错误
pm2 logs moneytrack-api --err --lines 50

# 常见问题：
# 1. PORT 被占用
lsof -i :8080

# 2. JWT_SECRET 未设置
#    检查 .env 文件是否存在且格式正确
cat .env

# 3. 依赖缺失
npm install
```

### 6.2 前端无法连接

```bash
# 1. 确认服务运行中
pm2 list

# 2. 确认端口监听
netstat -tlnp | grep 8080

# 3. 防火墙是否放行
curl http://localhost:8080/health

# 4. 从本机测试（确认网络通）
curl http://1.12.234.7:8080/health
```

### 6.3 数据库锁定问题

sql.js 使用文件锁，并发写入可能有问题。
生产环境建议未来迁移到 PostgreSQL/MySQL。

---

## 七、目录结构

```
/opt/moneytrack-api/
├── src/
│   ├── index.js          # 入口文件
│   ├── db.js             # 数据库
│   ├── middleware/
│   │   └── auth.js       # JWT 认证
│   ├── routes/           # API 路由
│   │   ├── auth.js
│   │   ├── accounts.js
│   │   ├── transactions.js
│   │   ├── assets.js
│   │   ├── budgets.js
│   │   ├── categories.js
│   │   └── sync.js
│   └── services/         # 业务逻辑
│       ├── userService.js
│       ├── categoryService.js
│       └── syncService.js
├── .env                  # 环境变量（不提交 Git！）
├── .env.example          # 环境变量模板
├── ecosystem.config.js   # PM2 配置
├── package.json
└── logs/                # 日志目录
    ├── out.log
    └── error.log
```

---

## 八、安全检查清单

- [x] `.env` 文件不在 Git 中（已配置 `.gitignore`）
- [x] `JWT_SECRET` 已设置（非默认值）
- [x] 端口 `8080` 仅对必要来源开放
- [x] Rate Limiting 已启用（防暴力破解）
- [x] CORS 已配置
- [x] PM2 进程管理器已配置开机自启
