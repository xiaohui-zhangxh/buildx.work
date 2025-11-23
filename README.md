# Tanmer Egg 🥚

> 一个开源的 Ruby on Rails 应用脚手架，集成企业级基础功能，让您专注于业务逻辑开发。

## 📖 项目简介

Tanmer Egg 是一个功能完整的 Rails 应用模板，旨在解决多项目开发中重复编写基础代码的问题。通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目，避免因复制代码而遗漏关键功能。

### 🎯 核心特性

- **标准化开发**：统一的基础功能实现，确保代码质量和一致性
- **快速启动**：跳过重复的基础开发工作，直接开始业务逻辑开发
- **最佳实践**：集成 Rails 社区推荐的最佳实践和安全机制
- **开箱即用**：包含用户系统、权限管理、多租户等企业级功能

## 🛠️ 技术栈

- **Ruby**: 3.3.5
- **Rails**: 8.1.1
- **数据库**: SQLite3（开发/测试），支持生产环境迁移到 PostgreSQL/MySQL
- **前端**: Tailwind CSS 4 + DaisyUI 5
- **JavaScript**: Importmap + Stimulus + Turbo
- **部署**: Kamal + Docker + Let's Encrypt SSL
- **缓存**: Redis（生产环境）
- **任务队列**: Solid Queue（Rails 8 内置）

## ✨ 主要功能模块

- 🔐 **认证与授权**：邮箱/手机号登录、OAuth、2FA、会话管理
- 👥 **用户与角色**：用户管理、RBAC、权限控制、数据导入导出
- 🏢 **多租户**：租户隔离、组织架构、团队协作
- 📡 **Webhook**：事件订阅、签名验证、重试机制
- 🔔 **通知系统**：多渠道通知、群发、模板管理
- 🤖 **AI MCP 服务**：MCP 协议、AI 助手集成
- 🌐 **API 支持**：RESTful API、Token/JWT 认证、API 文档

📋 [查看完整功能清单](docs/FEATURES.md)

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

### 常用命令

```bash
# 启动开发服务器
bin/dev

# 运行测试
bin/rails test

# 代码检查
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## 🐳 部署

使用 Kamal 部署（支持 Docker 和自动 SSL 证书）：

```bash
# 配置部署信息（编辑 config/deploy.yml）
# 部署应用
bin/kamal deploy

# 查看日志
bin/kamal logs

# 进入控制台
bin/kamal console
```

详细部署说明请参考 [开发文档](docs/README.md)。

## 📝 开发计划

本项目采用渐进式开发方式，按阶段逐步实现：

1. **第一阶段**：用户认证系统 🚧
2. **第二阶段**：权限系统 📋
3. **第三阶段**：多租户支持 📋
4. **第四阶段**：高级功能 📋

📖 [查看详细开发计划](docs/DEVELOPMENT_PLAN.md) | [阶段文档](docs/README.md)

## 📚 文档

- [当前工作状态](CURRENT_WORK.md) ⭐ - 正在进行的任务和待办事项
- [文档索引](docs/README.md) - 所有文档的导航

所有详细文档都在 `docs/` 目录下：

- [功能清单](docs/FEATURES.md) - 完整的功能列表
- [开发计划](docs/DEVELOPMENT_PLAN.md) - 开发路线图
- [开发者指南](docs/DEVELOPER_GUIDE.md) - 技术决策和架构设计

## 🤝 贡献

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

- 提交 [Issue](https://github.com/xiaohui-zhangxh/tanmer-egg/issues)
- 查看 [开发文档](docs/README.md)

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！
