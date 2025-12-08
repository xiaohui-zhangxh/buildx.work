# BuildX.work

本文档为在此仓库工作的 AI 编码代理提供指导。

## 🤖 AI 对话开始时的行为

### 检查今天是否已学习 Fizzy

**重要**：在第一次对话时，AI 应该检查今天是否已学习 Fizzy 新提交。如果没有学习，应该提示用户学习。

**执行规则**：

1. **检查时机**：仅在第一次对话时检查（避免重复提示）

2. **检查方法**：
   - 读取 `docs/fizzy-learning-log.md` 文件
   - 查找"## 最后学习时间"部分
   - 获取最后学习时间的日期（第一行，格式：YYYY-MM-DD）
   - 获取今天的日期（使用 `date +%Y-%m-%d` 命令）
   - 比较两个日期，判断是否相同

3. **判断逻辑**：
   - 如果日志文件不存在 → 视为未学习
   - 如果"最后学习时间"为空或不存在 → 视为未学习
   - 如果最后学习时间的日期 ≠ 今天的日期 → 视为未学习
   - 如果最后学习时间的日期 = 今天的日期 → 已学习，不提示

4. **提示格式**（如果今天未学习）：

```markdown
💡 **每日学习提醒**

今天还没有学习 Fizzy 新提交，建议先学习一下：

📖 **学习 Fizzy 新提交**
- **Cursor 斜线命令**：`/learn-fizzy-commits`
- **直接描述**：`学习 Fizzy 新提交`、`查看 Fizzy 最新代码变更`
- **说明**：每日学习 Basecamp Fizzy 项目的新提交代码变更，学习他们的新思路和最佳实践
- **指令文件**：`.cursor/commands/84-learn-fizzy-commits.md` ⭐

学习 Fizzy 可以帮助我们：
- ✅ 学习最新的代码风格和最佳实践
- ✅ 了解新的设计模式和架构决策
- ✅ 发现可以应用到 BuildX 的实践
- ✅ 保持对 Rails 社区最新趋势的了解

需要我现在帮你学习吗？使用 `/learn-fizzy-commits` 或直接说"学习 Fizzy 新提交"。
```

5. **如果今天已学习**：
   - 不显示提示
   - 正常继续对话

6. **如果日志文件不存在**：
   - 视为未学习，显示提示

**注意**：
- 这个检查只在第一次对话时执行，避免重复提示
- 如果用户明确表示不想学习，不要强制
- 提示应该友好、非强制，让用户自主决定

## 什么是 BuildX.work？

BuildX.work 是一个开源的 Ruby on Rails 业务网站生成平台，集成了企业级基础功能，让开发者专注于业务逻辑开发。它是一个完整的 Rails 应用模板，通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目。

**核心功能**：
- 🔐 **认证与授权**：邮箱登录、密码找回、会话管理、个人中心
- 👥 **用户与角色管理**：用户管理、RBAC、权限控制、批量操作、管理后台
- 🏢 **多租户支持**：Account 模型（外部 ID、Slug、JoinCode）、数据隔离、组织架构
- 💬 **内容交互系统**：评论系统（多态关联）、提及系统、反应系统
- 🏷️ **内容组织系统**：标签系统（多态关联）、置顶系统、关注系统、分配系统
- 🔍 **搜索与筛选**：全文搜索（自动索引）、高级筛选（条件保存）
- 📊 **事件系统**：Event 审核日志（多态关联、Eventable Concern、Webhook 分发）
- 🔔 **通知系统**：站内通知（多态关联、已读/未读、推送通知）、通知聚合

## 开发命令

### 初始化和服务器

```bash
bin/setup              # 初始设置（安装 gems、创建数据库、加载 schema）
bin/dev                 # 启动开发服务器（运行在端口 3000）
```

开发 URL: http://localhost:3000

### 测试

```bash
bin/rails test                    # 运行单元测试（默认并行，快速）
bin/rails test test/path/file_test.rb  # 运行单个测试文件
bin/rails test:system             # 运行系统测试（Capybara + Selenium）
bin/ci                            # 运行完整 CI 套件（样式、安全、测试）

# 单线程测试（统计准确覆盖率，学习 Fizzy 的方式）：
PARALLEL_WORKERS=1 bin/rails test

# 指定 worker 数量（并行测试，更快，但覆盖率不准确）：
PARALLEL_WORKERS=2 bin/rails test  # 使用 2 个 worker

# 检查特定文件覆盖率（使用单线程）：
PARALLEL_WORKERS=1 COVERAGE_FILES=app/models/user.rb bin/rails test test/models/user_test.rb
```

**重要提示**：
- **默认行为**：默认启用并行测试（快速），适合日常开发和快速验证
- **覆盖率要求**：整体覆盖率至少 85%（在 `test/test_helper.rb` 中配置）
- **查看覆盖率**：需要准确覆盖率时，使用 `PARALLEL_WORKERS=1 bin/rails test`（单线程）
- **查看覆盖率报告**：`open coverage/index.html`（运行测试后）
- **AI 覆盖率分析**：读取 `coverage/.resultset.json` 获取详细覆盖率数据
- **并行测试限制**：并行测试时覆盖率统计不准确，查看覆盖率时必须使用单线程（`PARALLEL_WORKERS=1`）

**AI 覆盖率分析规则**：当需要分析覆盖率数据、找出需要测试的文件时，AI 应该：
- ✅ **读取 JSON 数据文件**：`coverage/.resultset.json`（包含详细的覆盖率数据）
- ✅ **读取元数据文件**：`coverage/.last_run.json`（包含整体覆盖率信息）
- ❌ **不要打开 HTML 文件**：`open coverage/index.html`（AI 无法读取浏览器内容，此命令仅适用于用户手动查看）

CI 流水线（`bin/ci`）运行：
1. Rubocop（代码风格）
2. Bundler audit（gem 安全）
3. Brakeman（安全扫描）
4. 应用测试
5. 系统测试

### 数据库

```bash
bin/rails db:fixtures:load   # 加载 fixture 数据
bin/rails db:migrate          # 运行迁移
bin/rails db:reset            # 删除、创建并加载 schema
bin/rails db:setup            # 创建数据库、加载 schema 并填充种子数据
```

### 其他工具

```bash
bin/rails dev:email          # 切换 letter_opener 用于邮件预览
bin/jobs                     # 管理 Solid Queue 任务
bin/kamal deploy             # 部署（需要凭证）
bin/rubocop                  # 运行 RuboCop 代码风格检查器
bin/brakeman                 # 运行 Brakeman 安全扫描器
bin/bundler-audit            # 运行 Bundler audit 进行 gem 安全审计
```

## 架构概述

### 多租户（基于 URL）

BuildX.work 使用**基于 URL 路径的多租户**（类似 Fizzy）：
- 每个 Account（租户）有唯一的 `external_account_id`（7+ 位数字）
- URL 前缀：`/{account_id}/...`
- 中间件（`AccountSlug::Extractor`）从 URL 提取 account ID 并设置 `Current.account`
- slug 从 `PATH_INFO` 移动到 `SCRIPT_NAME`，使 Rails 认为它"挂载"在该路径上
- 所有模型包含 `account_id` 用于数据隔离
- 后台任务自动序列化和恢复 account 上下文

**关键洞察**：这种架构允许多租户，无需子域名或独立数据库，使本地开发和测试更简单。

### 认证和授权

**基于邮箱的认证**：
- 用户通过邮箱和密码注册和登录
- 通过邮箱魔法链接找回密码
- 通过签名 cookie（Warden）管理会话
- 密码过期检查（默认 90 天，可通过 SystemConfig 配置）

**授权**：
- **Action Policy** - 权限策略框架
- **RBAC（基于角色的访问控制）** - 用户通过角色获得权限
- **资源级权限** - 细粒度权限检查
- **Policy 类** - UserPolicy、RolePolicy、AdminPolicy 等

**关键模型**：
- `Identity` → 全局用户（基于邮箱）
- `User` → Account 成员资格（属于 Account 和 Identity）
- `Role` → 角色定义（owner/admin/member/system）
- `UserRole` → 用户-角色关联（多对多）

### 核心领域模型

**Account** → 租户/组织
- 拥有用户、external_account_id、slug、join_code
- 通过 account_id 进行数据隔离

**User** → Account 成员资格
- 属于 Account 和 Identity
- 通过 UserRole 拥有角色（owner/admin/member/system）
- 密码过期跟踪

**Role** → 角色定义
- 通过 Action Policy 拥有权限
- 用户可以拥有多个角色

**Session** → 用户会话
- 跟踪登录历史和设备信息
- 支持多个并发会话
- 会话管理（终止单个/所有其他会话）

**SystemConfig** → 系统配置
- 键值对配置存储
- 分类配置管理
- 安装状态跟踪

**AuditLog** → 操作审核日志
- 记录所有重要操作
- 多态关联到更改的对象
- 操作类型、用户、IP 地址和详细信息跟踪

### Engine 架构

BuildX.work 使用**Rails Engine** 架构：
- **Engine**：`engines/buildx_core/` - 管理基础设施视图、JavaScript、样式
- **主应用**：`app/` - 管理控制器、模型、业务逻辑
- **优势**：代码组织清晰、易于维护、减少合并冲突

**视图覆盖**：业务项目可以通过在 `app/views/` 中创建同名文件来覆盖 engine 视图。

### 后台任务（Solid Queue）

基于数据库的任务队列（无需 Redis）：
- Rails 8 内置 Solid Queue
- 任务自动捕获/恢复 `Current.account`（实现后）
- Mission Control::Jobs 用于监控

### UUID 主键

所有表使用 UUID（UUIDv7 格式，base36 编码为 25 字符字符串）：
- 自定义 fixture UUID 生成保持测试的确定性排序
- Fixtures 总是比运行时记录"更旧"
- `.first`/`.last` 在测试中正确工作

## 工具

### 开发工具

- **Letter Opener**：开发环境邮件预览（通过 `bin/rails dev:email` 切换）
- **Mission Control**：任务监控（Solid Queue）
- **SimpleCov**：测试覆盖率跟踪（要求至少 85%）

### 代码质量工具

- **RuboCop**：代码风格检查器（`bin/rubocop`）
- **Brakeman**：安全扫描器（`bin/brakeman`）
- **Bundler Audit**：Gem 安全审计（`bin/bundler-audit`）

## 代码风格

**核心原则**：所有代码开发都必须参考 Basecamp Fizzy 项目的最佳实践。

**关键参考**：
- [Fizzy 最佳实践总览](docs/experiences/fizzy-overview.md) ⭐ **必读**
- [Fizzy 代码风格指南](docs/experiences/fizzy-code-style-guide.md) - 代码风格标准
- [Fizzy 模型设计模式](docs/experiences/fizzy-model-design.md) - 模型设计
- [Fizzy 控制器设计模式](docs/experiences/fizzy-controller-design.md) - 控制器设计
- [Fizzy Hotwire 使用实践](docs/experiences/fizzy-hotwire-practices.md) - Hotwire/Turbo/Stimulus
- [Fizzy STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md) - Fizzy 官方风格指南

**关键实践**：
- ✅ **条件返回**：优先使用展开的条件语句
- ✅ **方法排序**：按调用顺序组织方法
- ✅ **可见性修饰符**：不使用换行符，内容缩进
- ✅ **CRUD 控制器**：使用资源而不是自定义动作
- ✅ **异步操作命名**：使用 `_later` 和 `_now` 后缀
- ✅ **使用 Concerns**：通过 Concerns 模块化功能
- ✅ **作用域链**：使用链式作用域封装查询
- ✅ **业务逻辑封装**：在模型中封装业务逻辑
- ✅ **薄控制器**：保持控制器简洁
- ✅ **参数处理**：使用 `params.expect`

## 开发工作流

### 开始开发前

1. **检查 Fizzy 最佳实践**：始终检查 Fizzy 是否有类似实现
2. **文档先行**：重要决策和设计应该先记录在文档中
3. **测试驱动**：每个功能都应该有对应的测试

### 开发过程中

1. **遵循 Fizzy 模式**：优先采用 Fizzy 的实现方式
2. **编写测试**：确保测试覆盖率满足 85% 要求
3. **代码质量**：运行 RuboCop、Brakeman 和 Bundler audit
4. **更新文档**：根据需要更新相关文档

### 开发完成后

1. **运行测试**：`PARALLEL_WORKERS=1 bin/rails test`（单线程查看覆盖率）
2. **检查覆盖率**：`open coverage/index.html`
3. **代码质量**：`bin/ci`（完整 CI 套件）
4. **更新文档**：更新 `CURRENT_WORK.md` 和相关进度文件

## 📚 文档结构和管理

### 文档组织方式

本项目采用分阶段文档管理方式，所有文档按功能模块和开发阶段组织。

**根目录文档**：
- **技术栈说明**：更新 `engines/buildx_core/README.md` 或 `docs/DEVELOPER_GUIDE.md`
- **开发笔记**：更新对应阶段的 `notes.md`
- **记录添加原因和使用场景**：便于后续维护

**注意**：根目录 `README.md` 只做简单介绍和链接，指向 `engines/buildx_core/README.md` 获取详细文档。详细的基础设施文档在 `engines/buildx_core/README.md`。

### 解决技术问题

1. 查看 `docs/experiences/` 目录是否有类似问题的解决方案
2. 查看 `docs/phase-{阶段名}/notes.md` 是否有类似问题
3. 查看 `docs/DEVELOPER_GUIDE.md` 了解技术决策
4. 查看相关 Cursor 规则文件（如 `authentication.mdc`）

### 更新开发进度

1. 更新对应阶段的 `progress.md`
2. 在 `notes.md` 中记录遇到的问题和解决方案
3. 如有技术决策，更新 `docs/DEVELOPER_GUIDE.md`

### 了解项目状态

1. 查看 `CURRENT_WORK.md` 了解当前正在做什么
2. 查看 `docs/DEVELOPMENT_PLAN.md` 了解整体进度
3. 查看各阶段的 `progress.md` 了解详细进度
4. 查看 `docs/FEATURES.md` 了解功能完成情况

### 文档更新规范

#### 文档先行原则 ⭐

**重要**：在开始新功能开发之前，必须先完成相关文档。这是确保开发质量、避免返工的关键原则。

**何时需要文档先行**：

1. **新功能开发**：开发新功能前，必须先写产品/功能文档
2. **新阶段开始**：开始新开发阶段前，必须先完成产品文档和开发计划
3. **重大技术决策**：做出重大技术决策前，必须先记录在文档中
4. **架构变更**：进行架构变更前，必须先更新架构文档

**文档先行的检查清单**：

**新功能开发前必须完成**：

- [ ] **产品/功能文档**（PRODUCT.md 或类似文档）
  - [ ] 产品价值和目标用户
  - [ ] 用户故事和使用场景
  - [ ] 功能特性描述（从用户角度）
  - [ ] 用户体验设计要点
  - [ ] 业务流程说明
  - [ ] 功能优先级（P0/P1/P2）

- [ ] **开发计划文档**（plan.md）
  - [ ] 技术实现方案
  - [ ] 开发任务清单
  - [ ] 技术决策记录
  - [ ] 开发顺序建议

- [ ] **相关文档更新**
  - [ ] 功能清单（FEATURES.md）- 标记新功能
  - [ ] 开发者指南（如需要）- 记录技术决策
  - [ ] 阶段 README.md - 更新阶段概览

**执行规则**：

1. **必须遵守**：新功能开发前，必须先完成产品文档
2. **AI 提醒**：如果用户跳过文档阶段直接开发，AI 应该提醒："在开始开发之前，请先完成产品/功能文档。这有助于明确需求、避免返工、提高开发效率。"
3. **文档质量**：文档应该清晰、完整，包含足够的信息供开发参考
4. **文档位置**：
   - 产品文档：`docs/phase-[阶段名]/PRODUCT.md`
   - 开发计划：`docs/phase-[阶段名]/plan.md`
   - 功能清单：`docs/FEATURES.md`

**文档先行的好处**：

- ✅ **明确需求**：通过文档明确功能需求，避免理解偏差
- ✅ **避免返工**：提前发现设计问题，减少开发过程中的修改
- ✅ **提高效率**：清晰的文档指导开发，减少沟通成本
- ✅ **知识沉淀**：文档记录决策过程，便于后续维护和扩展

**何时更新文档**：

1. **技术决策**：更新 `docs/DEVELOPER_GUIDE.md`
2. **开发进度**：更新对应阶段的 `progress.md`
3. **开发笔记**：更新对应阶段的 `notes.md`
4. **功能完成**：更新 `docs/FEATURES.md` 和 `engines/buildx_core/README.md`

**如何更新文档**：

1. **阶段内文档**：在对应阶段的文件夹中更新
2. **跨阶段文档**：在 `docs/` 根目录更新
3. **技术决策**：更新 `docs/DEVELOPER_GUIDE.md`
4. **功能清单**：更新 `docs/FEATURES.md`

**注意**：
- 更新日志文件创建和管理规范请参考 `.cursor/rules/changelog.mdc`
- **Markdown 文件格式检查**：更新 Markdown 文件时，必须检查并修复格式问题，详见 `.cursor/rules/markdown-formatting.mdc`

## ⚠️ 项目注意事项

1. **每日更新 CURRENT_WORK.md**：开始工作时查看，完成工作后更新
2. **不要重复文档内容**：根目录 `README.md` 保持精简（只做介绍和链接），详细内容在 `engines/buildx_core/README.md`
3. **及时更新进度**：开发过程中及时更新 progress.md 和 CURRENT_WORK.md
4. **记录技术决策**：重要决策记录在 DEVELOPER_GUIDE.md 和对应阶段的 notes.md
5. **遵循开发顺序**：按阶段顺序开发，不要跳跃
6. **业务文档隔离**：业务项目的文档应该放在 `docs/project-[项目名称]/` 目录下，不要修改根目录 `README.md`

## 重要文件和目录

### 核心应用

- `app/` - 主应用代码（控制器、模型、视图）
- `engines/buildx_core/` - 基础设施 engine（视图、JavaScript、样式）
- `config/` - 应用配置
- `db/` - 数据库迁移和 schema

### 文档

- `README.md` - 项目概述和快速开始
- `CURRENT_WORK.md` ⭐ - 当前任务和状态（每日必看）
- `docs/` - 所有文档
  - `docs/DEVELOPER_GUIDE.md` - 技术决策和架构
  - `docs/FEATURES.md` - 完整功能列表
  - `docs/DEVELOPMENT_PLAN.md` - 开发路线图
  - `docs/experiences/` - 开发经验和最佳实践
  - `docs/phase-*/` - 阶段特定文档

### 测试

- `test/` - 测试文件
- `test/test_helper.rb` - 测试配置（覆盖率、并行测试）
- `coverage/` - 覆盖率报告（测试后生成）

### 配置

- `.cursor/rules/` - Cursor AI 规则和指南
- `.cursor/commands/` - Cursor AI 命令
- `config/initializers/` - Rails 初始化器

## 🔗 重要链接

- **项目主页**：`README.md`（简单介绍和链接）
- **基础设施详细文档**：`engines/buildx_core/README.md` ⭐ 查看完整文档
- **当前工作**：`CURRENT_WORK.md` ⭐ 每日必看
- **文档索引**：`docs/README.md`
- **功能清单**：`docs/FEATURES.md`
- **开发计划**：`docs/DEVELOPMENT_PLAN.md`
- **开发者指南**：`docs/DEVELOPER_GUIDE.md`
- **规则文件创建指南**：`.cursor/rules/cursor-rules.mdc` ⭐ 创建新规则文件时参考
- **学习 Fizzy 新提交指令**：`.cursor/commands/84-learn-fizzy-commits.md` ⭐ 每日学习 Fizzy 新提交
- **Fizzy 学习日志**：`docs/fizzy-learning-log.md` ⭐ 记录学习历史（不对外输出）

## 📖 当前项目状态

### 当前开发阶段

- **阶段**：第三阶段 - 多租户支持
- **状态**：进行中
- **文档位置**：`docs/phase-3-multi-tenant/`
- **详细计划**：查看 `docs/DEVELOPMENT_PLAN.md`

### 技术栈核心

- **Ruby**: 3.3.5
- **Rails**: 8.1.1
- **认证**: Rails 8 Authentication Generator + Warden
- **前端**: Tailwind CSS 4 + DaisyUI 5
- **部署**: Kamal + Docker

## 关键开发原则

1. **优先参考 Fizzy**：在创建新功能之前，始终检查 Fizzy 的实现
2. **文档先行**：在实现之前记录重要决策
3. **测试覆盖率**：保持至少 85% 的测试覆盖率
4. **代码质量**：遵循 Rails 最佳实践和项目标准
5. **Engine 架构**：将基础设施代码保留在 engine 中，业务逻辑保留在主应用中

## 参考资料

- [BuildX.work GitHub](https://github.com/xiaohui-zhangxh/buildx.work)
- [Fizzy GitHub](https://github.com/basecamp/fizzy)
- [Fizzy AGENTS.md](https://github.com/basecamp/fizzy/blob/main/AGENTS.md) - 本文档的参考
- [Fizzy STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md) - 代码风格指南
- [Rails 指南](https://guides.rubyonrails.org/)
- [Hotwire 文档](https://hotwired.dev/)
- [Kamal 文档](https://kamal-deploy.org/)
