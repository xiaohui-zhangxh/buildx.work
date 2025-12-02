# BuildX.work 🚀

> 一个开源的 Ruby on Rails 业务网站生成平台，集成企业级基础功能，让您专注于业务逻辑开发。

## 📖 项目简介

**BuildX.work** 是一个功能完整的 Rails 应用模板，用于生成不同业务网站。通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目，避免因复制代码而遗漏关键功能。

### 🎯 项目定位：基础设施模板

**BuildX.work** 的设计目标是作为**基础设施模板**，为所有业务项目提供统一的基础功能。每个新项目都应该基于此模板创建，然后专注于业务逻辑开发。

#### 为什么选择这种方式？

我们考虑过多种集成方式，最终选择了 **Fork + Module 扩展** 的方案，原因如下：

**❌ 为什么不使用 Rails Engine？**
- Engine 适合需要独立版本管理和发布为 Gem 的场景
- 对于内部项目，Engine 的配置和加载机制过于复杂
- 代码调试不够直观，脱离了 Rails 的最佳实践
- 开发体验不够友好，需要处理各种 Engine 特有的配置

**❌ 为什么不使用文件复制？**
- 更新困难：需要手动复制文件，容易遗漏
- 合并冲突多：基础设施更新时，每个子项目都要处理大量冲突
- 维护成本高：多个项目需要同步更新，容易产生代码分歧

**✅ 为什么选择 Fork + Module 扩展？**
- **简单直接**：符合 Rails 约定，代码可见，调试方便
- **版本控制清晰**：通过 Git 追踪变更，可以追溯每个项目的修改历史
- **更新可控**：通过 `git merge` 处理冲突，比手动复制更可控
- **扩展灵活**：通过 Module/Concern 扩展功能，减少合并冲突
- **维护成本低**：基础设施代码保持稳定，子项目通过扩展机制添加业务功能

#### 如何使用？

1. **创建新项目**：Fork 或克隆此项目作为起点
2. **扩展功能**：通过 Module/Concern 扩展基础设施功能，而不是直接修改
3. **更新基础设施**：定期通过 `git merge` 同步基础设施更新

📖 [查看详细使用指南](docs/USAGE_GUIDE.md) - 包含完整的创建、扩展、更新流程

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
- **CDN/代理**: Cloudflare（支持真实 IP 地址获取）
- **缓存**: Solid Cache（Rails 8 内置，生产环境）
- **任务队列**: Solid Queue（Rails 8 内置）

## ✨ 主要功能模块

- 🔐 **认证与授权**：✅ 邮箱登录、密码找回、会话管理 | ⏳ 手机号登录、OAuth、2FA
- 👥 **用户与角色**：✅ 用户管理、RBAC、权限控制、批量操作 | ⏳ 数据导入导出
- 🏢 **多租户**：⏳ 租户隔离、组织架构、团队协作
- 📡 **Webhook**：⏳ 事件订阅、签名验证、重试机制
- 🔔 **通知系统**：✅ 邮件通知 | ⏳ 站内通知、短信通知、推送通知
- 🤖 **AI MCP 服务**：⏳ MCP 协议、AI 助手集成
- 🌐 **API 支持**：⏳ RESTful API、Token/JWT 认证、API 文档

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
git clone https://github.com/xiaohui-zhangxh/buildx.work.git
cd buildx.work

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

### Cloudflare 支持

项目已集成 `cloudflare-rails` Gem，支持在 Cloudflare 代理环境下自动获取真实客户端 IP 地址。详细说明请参考：

- [开发者指南 - Cloudflare 支持](docs/DEVELOPER_GUIDE.md#-cloudflare-支持)
- [开发经验 - Cloudflare 真实 IP 地址获取](docs/experiences/cloudflare-real-ip.md)

详细部署说明请参考 [开发文档](docs/README.md)。

## 📝 开发计划

本项目采用渐进式开发方式，按阶段逐步实现：

1. **第一阶段**：用户认证系统 ✅ **已完成**
2. **第二阶段**：权限系统 + 管理后台 ✅ **已完成 99%**
3. **第三阶段**：多租户支持 📋 **计划中**
4. **第四阶段**：高级功能 📋 **计划中**

📖 [查看详细开发计划](docs/DEVELOPMENT_PLAN.md) | [阶段文档](docs/README.md)

## 📚 文档

- [当前工作状态](CURRENT_WORK.md) ⭐ - 正在进行的任务和待办事项
- [文档索引](docs/README.md) - 所有文档的导航

所有详细文档都在 `docs/` 目录下：

- [使用指南](docs/USAGE_GUIDE.md) ⭐ - 如何创建子项目、如何扩展、如何更新
- [AI 使用教程](docs/AI_USAGE_GUIDE.md) ⭐ - 快速上手 AI 开发（指令、规则、经验、技术栈）
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

- 提交 [Issue](https://github.com/xiaohui-zhangxh/buildx.work/issues)
- 查看 [开发文档](docs/README.md)

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！
