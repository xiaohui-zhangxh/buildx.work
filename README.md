# BuildX.work 🚀

> 一个开源的 Ruby on Rails 业务网站生成平台，集成企业级基础功能，让您专注于业务逻辑开发。

## 🎯 项目目的

**BuildX.work** 是一个功能完整的 Rails 应用模板，帮助开发者快速启动新项目。通过提供一套经过验证的企业级功能模块，让您无需重复开发基础功能，直接专注于业务逻辑开发。

### 为什么选择 BuildX.work？

- ✅ **开箱即用**：集成用户认证、权限管理、多租户等企业级功能
- ✅ **最佳实践**：遵循 Rails 社区推荐的最佳实践和安全机制
- ✅ **快速启动**：跳过重复的基础开发工作，节省数周开发时间
- ✅ **标准化开发**：统一的基础功能实现，确保代码质量和一致性
- ✅ **持续更新**：基础设施持续优化，所有子项目自动受益

## 🎯 适用场景

BuildX.work 特别适合以下场景：

### 1. SaaS 应用开发
- 需要多租户支持
- 需要用户认证和权限管理
- 需要管理后台功能

### 2. 企业内部系统
- 需要角色和权限控制
- 需要操作日志和审计功能
- 需要系统配置管理

### 3. 内容管理系统
- 需要用户管理
- 需要内容组织和交互功能
- 需要搜索和筛选功能

### 4. 协作平台
- 需要团队协作功能
- 需要通知和消息系统
- 需要文件管理和分享

## ✨ 核心功能清单

### 🔐 认证与授权系统
- ✅ 邮箱注册/登录、密码找回、会话管理
- ✅ 基于角色的访问控制（RBAC）
- ✅ 细粒度权限管理、资源级权限控制
- ⏳ 手机号登录、OAuth、双因素认证（2FA）

### 👥 用户与角色系统
- ✅ 用户管理、角色管理、权限分配
- ✅ 用户搜索与筛选、批量操作
- ✅ 管理后台（Dashboard、用户管理、角色管理、系统配置、操作日志）
- ⏳ 用户数据导入导出

### 🏢 多租户支持
- ⏳ 租户隔离、Account 模型（外部 ID、Slug、JoinCode）
- ⏳ 组织架构、团队协作

### 💬 内容交互系统（计划中）
- ⏳ 评论系统（多态关联）、提及系统、反应系统
- ⏳ 支持对任意资源进行评论、提及和反应

### 🏷️ 内容组织系统（计划中）
- ⏳ 标签系统（多态关联）、置顶系统、关注系统、分配系统
- ⏳ 支持对任意资源进行标签、置顶、关注和分配

### 🔍 搜索与筛选系统（计划中）
- ⏳ 全文搜索（自动索引）、高级筛选（条件保存）
- ⏳ 多数据库适配器支持（SQLite/MySQL/PostgreSQL）

### 🔐 访问控制系统（计划中）
- ⏳ 资源访问控制（多态关联、访问级别、访问历史）

### 📊 事件系统（计划中）
- ⏳ Event 审核日志（多态关联、Eventable Concern、Webhook 分发）

### 🔔 通知系统
- ✅ 邮件通知
- ⏳ 站内通知（多态关联、已读/未读、推送通知）、通知聚合

### 📡 Webhook 系统（计划中）
- ⏳ 事件订阅、签名验证、重试机制

### 🌐 API 支持（计划中）
- ⏳ RESTful API、Token/JWT 认证、API 文档

### 🤖 AI MCP 服务（计划中）
- ⏳ MCP 协议、AI 助手集成

📋 [查看完整功能清单](docs/FEATURES.md)

## 🛠️ 技术栈

- **Ruby**: 3.3.5
- **Rails**: 8.1.1
- **数据库**: SQLite3（开发/测试），支持生产环境迁移到 PostgreSQL/MySQL
- **前端**: Tailwind CSS 4 + DaisyUI 5
- **JavaScript**: Importmap + Stimulus + Turbo（Hotwire）
- **部署**: Kamal + Docker + Let's Encrypt SSL
- **缓存**: Solid Cache（Rails 8 内置）
- **任务队列**: Solid Queue（Rails 8 内置）

## 🚀 快速开始

### 前置要求

- Ruby 3.3.5
- Bundler
- Node.js（用于 Tailwind CSS）
- SQLite3

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

## 📊 开发进度

- ✅ **第一阶段**：用户认证系统（已完成）
- ✅ **第二阶段**：权限系统 + 管理后台（已完成 99%）
- 📋 **第三阶段**：多租户支持（计划中）
- 📋 **第四阶段**：通用业务功能系统（计划中）
- 📋 **第五阶段**：通知与 Webhook 系统（计划中）
- 📋 **第六阶段**：高级功能（计划中）

📖 [查看详细开发计划](docs/DEVELOPMENT_PLAN.md)

## 📚 文档导航

### 🎯 快速上手
- 📖 [基础设施详细文档](engines/buildx_core/README.md) ⭐ **完整文档**
- 🚀 [使用指南](docs/USAGE_GUIDE.md) - 如何创建子项目、如何扩展、如何更新
- 🤖 [AI 使用教程](docs/AI_USAGE_GUIDE.md) - 快速上手 AI 开发

### 📋 功能与规划
- 📋 [完整功能清单](docs/FEATURES.md) - 所有功能模块的详细列表
- 📖 [开发计划](docs/DEVELOPMENT_PLAN.md) - 开发路线图和阶段规划
- 📋 [当前工作状态](CURRENT_WORK.md) ⭐ 每日必看

### 🔧 开发文档
- 📚 [文档索引](docs/README.md) - 所有文档的导航
- 📖 [开发者指南](docs/DEVELOPER_GUIDE.md) - 技术决策和架构设计
- 📝 [开发经验](docs/experiences/) - 开发过程中遇到的问题和解决方案

### 🎓 学习资源
- 📚 [Fizzy 最佳实践学习](docs/experiences/fizzy-overview.md) - 从 Basecamp Fizzy 项目学习的设计模式

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

## 📧 联系方式

- 提交 [Issue](https://github.com/xiaohui-zhangxh/buildx.work/issues)
- 查看 [开发文档](docs/README.md)

## 📄 许可证

本项目采用 **AGPL v3** 许可证。

- ✅ **开源使用**：允许自由使用、修改、分发
- ✅ **学习研究**：允许学习、研究、内部使用
- ⚠️ **Copyleft**：基于此代码的衍生作品必须使用 AGPL 许可证
- ⚠️ **网络服务**：通过网络服务提供基于此代码的服务，必须开源整个服务代码

详见 [LICENSE](LICENSE) 文件。

### 商业许可

如果您需要在商业环境中使用此项目而不开源您的代码，请联系我们获取商业许可证。

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！

> 💡 **设计原则**：通用业务功能（评论、标签、关注等）采用多态关联设计，提高代码复用性和可扩展性。参考 [Fizzy 最佳实践学习](docs/experiences/fizzy-overview.md)
