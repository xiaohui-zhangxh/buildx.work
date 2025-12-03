# BuildX.work 🚀

> 一个开源的 Ruby on Rails 业务网站生成平台，集成企业级基础功能，让您专注于业务逻辑开发。

## 📖 项目简介

**BuildX.work** 是一个功能完整的 Rails 应用模板，用于生成不同业务网站。通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目，避免因复制代码而遗漏关键功能。

### 🎯 项目定位：基础设施模板

**BuildX.work** 的设计目标是作为**基础设施模板**，为所有业务项目提供统一的基础功能。每个新项目都应该基于此模板创建，然后专注于业务逻辑开发。

#### 为什么选择这种方式？

我们考虑过多种集成方式，最终选择了 **Fork + Rails Engine + Module 扩展** 的混合架构方案，原因如下：

**✅ 为什么使用 Rails Engine（作为内部架构）？**
- **代码组织清晰**：将基础设施的视图、JavaScript、样式等资源文件统一管理在 Engine 中
- **职责分离明确**：Engine 管理基础设施代码，主应用专注于业务逻辑
- **便于维护**：基础设施代码集中管理，更新时只需修改 Engine
- **减少合并冲突**：视图文件在 Engine 中，业务项目很少需要修改，降低冲突概率
- **开发体验友好**：Engine 作为项目内部模块，代码可见，调试方便，无需发布为 Gem

**❌ 为什么不使用独立的 Gem Engine？**
- 独立的 Gem Engine 适合需要独立版本管理和发布的场景
- 对于内部项目，Gem 的发布和版本管理机制过于复杂
- 开发调试不够直观，需要频繁发布和更新 Gem 版本

**❌ 为什么不使用文件复制？**
- 更新困难：需要手动复制文件，容易遗漏
- 合并冲突多：基础设施更新时，每个子项目都要处理大量冲突
- 维护成本高：多个项目需要同步更新，容易产生代码分歧

**✅ 为什么选择 Fork + Rails Engine + Module 扩展？**
- **架构清晰**：Engine 管理基础设施资源（视图、JavaScript、样式），主应用管理业务逻辑
- **版本控制清晰**：通过 Git 追踪变更，可以追溯每个项目的修改历史
- **更新可控**：通过 `git merge` 处理冲突，比手动复制更可控
- **扩展灵活**：通过 Module/Concern 扩展功能，减少合并冲突
- **维护成本低**：基础设施代码在 Engine 中保持稳定，子项目通过扩展机制添加业务功能

#### 架构说明

**BuildX.work 采用 Rails Engine 架构**：

- **Engine 位置**：`engines/buildx_core/`
- **Engine 职责**：管理基础设施的视图、JavaScript、样式、邮件模板等资源文件
- **主应用职责**：管理业务逻辑、控制器、模型、业务视图等
- **扩展方式**：通过 Module/Concern 扩展基础设施功能，而不是直接修改 Engine 代码

#### 为什么只把 Views 和 Assets 放入 Engine？

**✅ 放入 Engine 的内容**：
- **Views（视图）**：基础设施的视图文件（认证、管理后台等）
- **Assets（资源）**：JavaScript Controllers、样式、图片等静态资源
- **Vendor（第三方库）**：第三方 JavaScript、CSS 库

**❌ 不放入 Engine 的内容**：
- **Controllers（控制器）**：保留在主应用的 `app/controllers/`
- **Models（模型）**：保留在主应用的 `app/models/`
- **Lib（工具库）**：保留在主应用的 `lib/` 或 `app/`

**原因说明**：

1. **Views 和 Assets 相对稳定**：
   - 视图文件一旦确定，很少需要修改
   - 资源文件（JavaScript、CSS）相对固定
   - 放在 Engine 中可以减少合并冲突，因为业务项目很少需要修改这些文件

2. **Controllers 和 Models 需要频繁扩展**：
   - 业务项目经常需要通过 Module/Concern 扩展控制器和模型
   - 放在主应用中更方便扩展和调试
   - 通过扩展机制（`app/models/concerns/`、`app/controllers/concerns/`）可以灵活扩展，无需修改 Engine

3. **扩展机制更灵活**：
   - 控制器和模型通过 Module/Concern 扩展，不需要放在 Engine 中
   - 主应用中的扩展模块可以覆盖或扩展基础设施功能
   - 视图文件可以通过覆盖机制自定义（在主应用创建同名文件）

4. **开发体验更好**：
   - 控制器和模型在主应用中，代码可见，调试方便
   - 不需要处理 Engine 的加载顺序和命名空间问题
   - 符合 Rails 约定，代码组织更直观

**目录结构**：

```
buildx.work/
├── app/                          # 主应用（业务逻辑）
│   ├── controllers/              # 业务控制器
│   ├── models/                   # 业务模型
│   └── views/                    # 业务视图（如需要覆盖 Engine 视图）
│
└── engines/
    └── buildx_core/              # 基础设施 Engine
        ├── app/
        │   ├── views/            # 基础设施视图（认证、管理后台等）
        │   ├── javascript/       # JavaScript Controllers
        │   └── assets/          # 样式和图片资源
        ├── vendor/               # 第三方库（JavaScript、CSS）
        └── lib/
            └── buildx_core/
                └── engine.rb     # Engine 配置
```

#### 如何使用？

1. **创建新项目**：Fork 或克隆此项目作为起点
2. **扩展功能**：通过 Module/Concern 扩展基础设施功能，而不是直接修改 Engine 代码
3. **覆盖视图**：如需要自定义基础设施视图，在主应用的 `app/views/` 中创建同名文件即可覆盖
4. **更新基础设施**：定期通过 `git merge` 同步基础设施更新

📖 [查看详细使用指南](../../docs/USAGE_GUIDE.md) - 包含完整的创建、扩展、更新流程

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

📋 [查看完整功能清单](../../docs/FEATURES.md)

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

- [开发者指南 - Cloudflare 支持](../../docs/DEVELOPER_GUIDE.md#-cloudflare-支持)
- [开发经验 - Cloudflare 真实 IP 地址获取](../../docs/experiences/cloudflare-real-ip.md)

详细部署说明请参考 [开发文档](../../docs/README.md)。

## 📝 开发计划

本项目采用渐进式开发方式，按阶段逐步实现：

1. **第一阶段**：用户认证系统 ✅ **已完成**
2. **第二阶段**：权限系统 + 管理后台 ✅ **已完成 99%**
3. **第三阶段**：多租户支持 📋 **计划中**
4. **第四阶段**：高级功能 📋 **计划中**

📖 [查看详细开发计划](../../docs/DEVELOPMENT_PLAN.md) | [阶段文档](../../docs/README.md)

## 📚 文档

- [当前工作状态](../../CURRENT_WORK.md) ⭐ - 正在进行的任务和待办事项
- [文档索引](../../docs/README.md) - 所有文档的导航

所有详细文档都在 `docs/` 目录下：

- [使用指南](../../docs/USAGE_GUIDE.md) ⭐ - 如何创建子项目、如何扩展、如何更新
- [AI 使用教程](../../docs/AI_USAGE_GUIDE.md) ⭐ - 快速上手 AI 开发（指令、规则、经验、技术栈）
- [功能清单](../../docs/FEATURES.md) - 完整的功能列表
- [开发计划](../../docs/DEVELOPMENT_PLAN.md) - 开发路线图
- [开发者指南](../../docs/DEVELOPER_GUIDE.md) - 技术决策和架构设计

## 📁 业务项目文档

**重要**：如果您正在基于 BuildX.work 开发业务项目，请将业务相关的文档放在 `docs/project-[项目名称]/` 目录下。

### 文档存放规范

- ✅ **基础设施文档**：保持在 `docs/` 根目录（如 `docs/DEVELOPER_GUIDE.md`、`docs/phase-*/`）
- ✅ **业务项目文档**：存放在 `docs/project-[项目名称]/` 目录下
- ✅ **根目录 README**：保持为基础设施文档，不要修改

### 示例

```
docs/
├── [基础设施文档]              # buildx.work 的通用文档
│   ├── README.md
│   ├── DEVELOPER_GUIDE.md
│   ├── phase-1-authentication/
│   └── ...
│
└── project-[项目名称]/         # 业务项目的特定文档
    ├── README.md              # 项目文档索引（不使用数字前缀）
    ├── 01-BUSINESS_ANALYSIS.md
    ├── 02-PROJECT_PLAN.md
    └── ...
```

这样设计的好处：
- ✅ 降低合并冲突：基础设施文档和业务文档隔离
- ✅ 便于维护：基础设施更新不会影响业务文档
- ✅ 清晰分离：基础设施和业务逻辑职责明确

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

本项目采用 MIT 许可证。详见 [LICENSE](../../LICENSE) 文件。

## 🙏 致谢

- [Ruby on Rails](https://rubyonrails.org/)
- [DaisyUI](https://daisyui.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Kamal](https://kamal-deploy.org/)

## 📧 联系方式

- 提交 [Issue](https://github.com/xiaohui-zhangxh/buildx.work/issues)
- 查看 [开发文档](../../docs/README.md)

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！

