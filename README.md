# Tanmer Egg 🥚

> 一个开源的 Ruby on Rails 应用脚手架，集成企业级基础功能，让您专注于业务逻辑开发。

## 📖 项目简介

Tanmer Egg 是一个功能完整的 Rails 应用模板，旨在解决多项目开发中重复编写基础代码的问题。通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目，避免因复制代码而遗漏关键功能。

### 🎯 项目目标

- **标准化开发**：提供统一的基础功能实现，确保代码质量和一致性
- **快速启动**：跳过重复的基础开发工作，直接开始业务逻辑开发
- **最佳实践**：集成 Rails 社区推荐的最佳实践和安全机制
- **开箱即用**：包含用户系统、权限管理、多租户等企业级功能

## 🛠️ 技术栈

### 核心框架
- **Ruby**: 3.3.5
- **Rails**: 8.1.1
- **数据库**: SQLite3（开发/测试），支持生产环境迁移到 PostgreSQL/MySQL

### 前端技术
- **Tailwind CSS**: 4.x
- **DaisyUI**: 5.x（UI 组件库）
- **Importmap**: 无需 JavaScript 编译，直接使用 ESM 模块
- **Stimulus**: 轻量级 JavaScript 框架
- **Turbo**: SPA 体验加速器

### 基础设施
- **缓存**: Redis（生产环境）
- **任务队列**: Solid Queue（Rails 8 内置）
- **WebSocket**: Solid Cable（Rails 8 内置）
- **部署**: Kamal + Docker
- **SSL**: 自动证书更新（Let's Encrypt）

## ✨ 功能清单

### 🔐 认证与授权系统

#### 用户认证
- [ ] 邮箱注册/登录
- [ ] 手机号注册/登录（短信验证）
- [ ] 密码找回（邮箱/短信）
- [ ] 密码强度验证
- [ ] 登录失败次数限制
- [ ] 账户锁定机制
- [ ] 记住我功能
- [ ] 双因素认证（2FA）

#### 第三方授权
- [ ] OAuth 2.0 集成
- [ ] 微信登录
- [ ] GitHub 登录
- [ ] Google 登录
- [ ] 其他第三方平台支持

#### 会话管理
- [ ] 多设备登录管理
- [ ] 会话超时控制
- [ ] 强制下线功能
- [ ] 登录历史记录

### 👥 用户与角色系统

#### 用户管理
- [ ] 用户基础信息管理
- [ ] 用户头像上传
- [ ] 用户资料编辑
- [ ] 用户状态管理（激活/禁用）
- [ ] 用户搜索与筛选
- [ ] 用户数据导入（Excel/CSV）
- [ ] 用户数据导出（Excel/CSV）
- [ ] 批量用户操作

#### 角色系统
- [ ] 基于角色的访问控制（RBAC）
- [ ] 预定义角色（管理员、普通用户等）
- [ ] 自定义角色创建
- [ ] 角色权限分配

#### 权限控制
- [ ] 细粒度权限管理
- [ ] 资源级权限控制
- [ ] 权限继承机制
- [ ] 动态权限检查

### 🏢 多租户与组织架构

#### 多租户支持
- [ ] 租户隔离（数据隔离）
- [ ] 租户创建与管理
- [ ] 租户切换功能
- [ ] 租户级别配置

#### 组织架构
- [ ] 企业组织树形结构
- [ ] 部门管理
- [ ] 员工管理
- [ ] 组织架构可视化
- [ ] 部门权限继承

#### 团队协作
- [ ] 团队成员管理
- [ ] 团队角色分配
- [ ] 团队权限控制

### 📡 Webhook 与事件系统

#### Webhook 管理
- [ ] Webhook 创建与配置
- [ ] 事件订阅管理
- [ ] Webhook 签名验证
- [ ] 重试机制
- [ ] Webhook 日志记录

#### 事件系统
- [ ] 事件发布/订阅
- [ ] 异步事件处理
- [ ] 事件历史记录
- [ ] 事件过滤与搜索

### 🔔 通知系统

- [ ] 站内通知
- [ ] 邮件通知
- [ ] 短信通知
- [ ] 推送通知（Web Push）
- [ ] 通知模板管理
- [ ] 通知偏好设置
- [ ] 群发通知功能
- [ ] 批量通知发送
- [ ] 联系方式导入（Excel/CSV）
- [ ] 联系方式导出（Excel/CSV）
- [ ] 联系人分组管理
- [ ] 通知发送记录与统计

### 📊 系统管理

- [ ] 系统配置管理
- [ ] 操作日志记录
- [ ] 审计日志
- [ ] 系统监控
- [ ] 健康检查端点

### 🔒 安全功能

- [ ] CSRF 保护
- [ ] XSS 防护
- [ ] SQL 注入防护
- [ ] 速率限制（Rate Limiting）
- [ ] IP 白名单/黑名单
- [ ] 安全头配置
- [ ] 数据加密存储

### 📁 文件管理

- [ ] 文件上传（Active Storage）
- [ ] 图片处理与缩略图
- [ ] 文件访问控制
- [ ] 文件预览
- [ ] 批量文件操作

### 🌐 API 支持

- [ ] RESTful API
- [ ] API 认证（Token/JWT）
- [ ] API 版本控制
- [ ] API 文档（Swagger/OpenAPI）
- [ ] API 速率限制
- [ ] CORS 配置

### 🤖 AI MCP 服务

#### MCP 服务器
- [ ] MCP 协议实现
- [ ] MCP 服务器注册与管理
- [ ] MCP 工具（Tools）管理
- [ ] MCP 资源（Resources）管理
- [ ] MCP 提示词（Prompts）管理

#### MCP 集成
- [ ] 多 MCP 服务器支持
- [ ] MCP 服务器连接管理
- [ ] MCP 请求路由与分发
- [ ] MCP 响应缓存
- [ ] MCP 错误处理与重试

#### AI 功能增强
- [ ] 基于 MCP 的 AI 助手集成
- [ ] 上下文管理
- [ ] 对话历史记录
- [ ] AI 功能权限控制
- [ ] AI 使用统计与分析

## 🚀 快速开始

### 前置要求

- Ruby 3.3.5
- Bundler
- Node.js（用于 Tailwind CSS）
- SQLite3
- Redis（生产环境）

### 安装步骤

```bash
# 克隆项目
git clone https://github.com/xiaohui-zhangxh/tanmer-egg.git
cd tanmer-egg

# 安装依赖
bundle install
npm install

# 设置数据库
bin/rails db:setup

# 启动开发服务器
bin/dev
```

访问 http://localhost:3000 查看应用。

### 开发环境

```bash
# 启动开发服务器（包含 Tailwind CSS 监听）
bin/dev

# 运行测试
bin/rails test

# 代码检查
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## 🐳 部署

### 使用 Kamal 部署

```bash
# 配置部署信息（编辑 config/deploy.yml）
# 设置服务器地址、域名等

# 部署应用
bin/kamal deploy

# 查看日志
bin/kamal logs

# 进入控制台
bin/kamal console
```

### 环境变量配置

在 `.kamal/secrets` 文件中配置必要的密钥：

```bash
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=your_database_url
REDIS_URL=your_redis_url
# ... 其他配置
```

### SSL 证书

Kamal 会自动通过 Let's Encrypt 获取和更新 SSL 证书。确保在 `config/deploy.yml` 中配置了正确的域名。

## 📝 开发计划

本项目采用渐进式开发方式，按照功能模块逐步实现。当前开发重点：

1. **第一阶段**：用户认证系统
   - 邮箱注册/登录
   - 密码找回
   - 基础用户管理

2. **第二阶段**：权限系统
   - 角色管理
   - 权限控制
   - 资源权限

3. **第三阶段**：多租户支持
   - 租户隔离
   - 组织架构
   - 团队管理

4. **第四阶段**：高级功能
   - Webhook 系统
   - 通知系统
   - API 支持
   - AI MCP 服务集成

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 遵循 Rails 社区最佳实践
- 使用 RuboCop 进行代码检查
- 编写测试覆盖新功能
- 更新相关文档

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Ruby on Rails](https://rubyonrails.org/)
- [DaisyUI](https://daisyui.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Kamal](https://kamal-deploy.org/)

## 📧 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/your-org/tanmer-egg/issues)
- 发送邮件至：your-email@example.com

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！
