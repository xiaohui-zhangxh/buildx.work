# BuildX.work AI 使用教程

> 本教程帮助开发者快速上手使用 Cursor AI 助手进行开发，包括如何创建指令、规则、保存经验和记录技术栈。

## 📚 目录

- [快速开始](#快速开始)
- [创建和管理指令](#创建和管理指令)
- [创建和管理规则](#创建和管理规则)
- [保存开发经验](#保存开发经验)
- [记录技术栈规则](#记录技术栈规则)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)

## 快速开始

### 什么是 Cursor AI？

Cursor 是一个 AI 驱动的代码编辑器，它可以帮助你：

- 🤖 **智能代码生成**：根据上下文自动生成代码
- 🔍 **代码搜索和理解**：快速理解代码库结构
- 🛠️ **自动化任务**：执行重复性开发任务
- 📝 **文档生成**：自动生成文档和注释

### 项目中的 AI 功能

BuildX.work 项目集成了以下 AI 功能：

1. **指令系统**：定义 AI 的工作方式和行为模式
2. **规则系统**：提供开发规范和最佳实践
3. **经验库**：记录开发中遇到的问题和解决方案
4. **技术栈文档**：记录技术栈的使用规范和参考

## 创建和管理指令

### 什么是指令？

指令（Commands）是 `.md` 文件，用于定义 AI 助手在特定场景下的工作方式和行为模式。与规则不同，指令不是提供开发规范，而是定义 AI 的工作流程。

### 指令文件位置

所有指令文件存放在 `.cursor/commands/` 目录下，文件扩展名为 `.md`。

### 创建新指令

#### 1. 确定指令主题

在创建指令前，先思考：

- 需要定义什么工作方式？
- 需要规范什么行为模式？
- 这个指令适用于什么场景？

#### 2. 创建指令文件

在 `.cursor/commands/` 目录下创建新的 `.md` 文件：

```bash
# 使用命令行创建
touch .cursor/commands/my-command.md

# 或使用 Cursor 编辑器直接创建
```

**命名规范**：

- ✅ 使用小写字母和连字符：`my-command.md`
- ✅ 使用描述性名称：`autonomous-work.md`、`code-review.md`
- ✅ 可以使用数字前缀：`00-continue.md`、`01-smart-go.md`（方便快速执行）
- ❌ 避免使用下划线：`my_command.md`
- ❌ 避免使用空格：`my command.md`

#### 3. 编写指令内容

指令文件使用 Markdown 格式，**不需要**头部元数据字段（与规则文件不同）。

**推荐结构**：

```markdown
# 指令文件标题

## 触发场景

说明何时应该使用这个指令...

## 核心原则

1. 原则 1
2. 原则 2

## 工作流程

### 1. 步骤 1

详细说明...

### 2. 步骤 2

详细说明...

## 重要规则

- 规则 1
- 规则 2

## 注意事项

1. 注意事项 1
2. 注意事项 2
```

#### 4. 使用指令

在 Cursor 中使用斜线命令执行指令：

```bash
# 使用斜线命令
/continue-project-work

# 或直接描述
继续完成项目工作，项目：项目名
```

### 更新现有指令

直接编辑 `.cursor/commands/` 目录下的 `.md` 文件即可。修改后，AI 会自动识别新的指令内容。

### 指令文件示例

查看现有指令文件作为参考：

- **00-continue.md**：继续完成项目工作指令
- **01-smart-go.md**：智能继续工作指令
- **02-autonomous-work.md**：自主工作模式指令
- **03-daily-report.md**：日报管理指令

### 参考文档

详细指南请参考：`.cursor/rules/cursor-commands.mdc`

## 创建和管理规则

### 什么是规则？

规则（Rules）是 `.mdc` 文件，用于为 AI 助手提供开发规范和指导。当开发相关功能时，AI 会自动参考这些规则文件，确保遵循最佳实践。

### 规则文件位置

所有规则文件存放在 `.cursor/rules/` 目录下，文件扩展名为 `.mdc`。

### 创建新规则

#### 1. 确定规则主题

在创建规则前，先思考：

- 是否已有相关规则文件？
- 是否需要创建新的规则文件？
- 规则文件应该包含哪些内容？

#### 2. 创建规则文件

在 `.cursor/rules/` 目录下创建新的 `.mdc` 文件：

```bash
# 使用命令行创建
touch .cursor/rules/my-rule.mdc

# 或使用 Cursor 编辑器直接创建
```

**命名规范**：

- ✅ 使用小写字母和连字符：`my-rule.mdc`
- ✅ 使用描述性名称：`authentication.mdc`、`daisy-ui.mdc`
- ❌ 避免使用下划线：`my_rule.mdc`
- ❌ 避免使用空格：`my rule.mdc`

#### 3. 编写头部元数据

规则文件**必须**包含头部元数据字段：

```markdown
---
description: 规则文件的简短描述，说明内容和用途
alwaysApply: false  # 大多数情况下使用 false
---
```

**重要字段说明**：

- **`description`**（必需）：
  - 描述规则文件的内容和用途
  - 帮助 AI 理解何时应该参考这个规则文件
  - 长度建议：50-150 字符
  - 示例：`认证系统开发规则和参考`

- **`alwaysApply`**（必需）：
  - `true`：规则文件总是被应用（适用于通用基础规则）
  - `false`：规则文件只在相关上下文时被应用（大多数情况下使用）
  - 只有通用基础规则和项目特定规则使用 `true`

#### 4. 编写规则内容

规则内容应该包括：

- **核心原则**：规则文件遵循的核心原则
- **参考文件**：相关的文档和代码文件
- **开发规范**：具体的开发规范和最佳实践
- **示例代码**：示例代码和反例对比
- **常见任务**：常见开发任务的步骤
- **注意事项**：重要的注意事项和陷阱

**推荐结构**：

```markdown
---
description: 规则文件描述
alwaysApply: false
---

# 规则文件标题

## 核心原则

规则文件遵循的核心原则...

## 开发相关功能时的参考文件

### 1. 主要文档

**文件位置**：`docs/xxx.md`
**用途**：...

### 2. 相关代码

**文件位置**：`app/xxx/xxx.rb`
**用途**：...

## 开发规范

### 代码规范示例

```ruby
# 示例代码
```

## 常见任务

### 任务 1：...

步骤说明...

## 注意事项

1. 注意事项 1
2. 注意事项 2

## 相关文件索引

- 文档：`docs/xxx.md`
- 代码：`app/xxx/xxx.rb`
```

### 更新现有规则

直接编辑 `.cursor/rules/` 目录下的 `.mdc` 文件即可。修改后，AI 会自动识别新的规则内容。

### 规则文件示例

查看现有规则文件作为参考：

- **base.mdc**：通用基础规则（`alwaysApply: true`）
- **workspace.mdc**：项目特定规则（`alwaysApply: true`）
- **authentication.mdc**：认证系统开发规则（`alwaysApply: false`）
- **daisy-ui.mdc**：DaisyUI 前端开发规则（`alwaysApply: false`）

### 参考文档

详细指南请参考：`.cursor/rules/cursor-rules.mdc`

## 保存开发经验

### 什么是经验？

经验（Experiences）是开发过程中遇到的疑难问题和解决方案的记录，存放在 `docs/experiences/` 目录下，便于后续遇到类似问题时快速参考。

### 经验文件位置

所有经验文件存放在 `docs/experiences/` 目录下，文件扩展名为 `.md`。

### 创建新经验

#### 1. 确定经验主题

在创建经验前，先思考：

- 遇到了什么问题？
- 问题的根本原因是什么？
- 解决方案是什么？
- 有哪些关键经验可以总结？

#### 2. 创建经验文件

在 `docs/experiences/` 目录下创建新的 `.md` 文件：

```bash
# 使用命令行创建
touch docs/experiences/my-experience.md

# 或使用 Cursor 编辑器直接创建
```

**命名规范**：

- ✅ 使用小写字母和连字符：`my-experience.md`
- ✅ 使用描述性名称：`highlight.js.md`、`warden-custom-failure.md`
- ✅ 可以使用技术名称：`importmap-ssl-certificate-error.md`
- ❌ 避免使用下划线：`my_experience.md`
- ❌ 避免使用空格：`my experience.md`

#### 3. 编写经验内容

经验文件使用 Markdown 格式，**不需要**头部元数据字段。

**推荐结构**：

```markdown
# [问题标题]

**日期**：YYYY-MM-DD  
**问题类型**：前端集成 / 后端逻辑 / 配置问题 / 性能优化  
**状态**：✅ 已解决 / 🚧 进行中 / ❌ 未解决

## 问题描述

详细描述遇到的问题和现象。

## 问题原因分析

分析问题的根本原因。

## 解决方案

### 步骤 1：...

详细说明...

### 步骤 2：...

详细说明...

## 关键经验总结

总结关键经验和注意事项。

## 相关文件

- `path/to/file.rb`
- `path/to/file.js`

## 参考资料

- [链接标题](URL)
```

#### 4. 更新经验索引

在 `docs/experiences/README.md` 中添加经验索引：

```markdown
## 📋 经验列表

### 前端集成

- [Highlight.js 集成问题](./highlight.js.md) (2025-11-25)
  - Importmap 路径配置
  - ES Module vs CommonJS 兼容性
  - Stimulus Controller 初始化

### 后端逻辑 / 认证系统

- [Warden custom_failure! 使用经验](./warden-custom-failure.md) (2025-11-29)
  - API 控制器返回 401 时避免 Warden 拦截
  - custom_failure! 的使用场景和注意事项
```

### 查看经验

经验可以通过以下方式查看：

1. **本地文件**：直接查看 `docs/experiences/` 目录下的文件
2. **Web 界面**：访问 `/experiences` 路径查看所有经验列表
3. **单个经验**：访问 `/experiences/:id` 路径查看单个经验详情

### 经验文件示例

查看现有经验文件作为参考：

- **warden-custom-failure.md**：Warden custom_failure! 使用经验
- **importmap-ssl-certificate-error.md**：Importmap SSL 证书验证错误
- **highlight.js.md**：Highlight.js 集成问题

### 参考文档

详细指南请参考：`docs/experiences/README.md`

## 记录技术栈规则

### 什么是技术栈规则？

技术栈规则是记录项目使用的技术栈的开发规范和最佳实践，存放在 `.cursor/rules/` 目录下，可以通过 Web 界面查看。

### 技术栈规则位置

技术栈规则文件存放在 `.cursor/rules/` 目录下，文件扩展名为 `.mdc`。

### 创建技术栈规则

#### 1. 确定技术栈主题

在创建技术栈规则前，先思考：

- 项目使用了哪些技术栈？
- 每个技术栈有哪些开发规范？
- 有哪些最佳实践需要记录？

#### 2. 创建规则文件

技术栈规则就是普通的规则文件，按照[创建和管理规则](#创建和管理规则)的步骤创建即可。

**命名规范**：

- ✅ 使用技术栈名称：`daisy-ui.mdc`、`action-policy.mdc`
- ✅ 使用小写字母和连字符
- ❌ 避免使用下划线或空格

#### 3. 注册技术栈

在 `app/controllers/tech_stack_controller.rb` 中注册技术栈：

```ruby
TECH_STACK_RULES = {
  "daisy-ui" => {
    name: "DaisyUI",
    icon: "daisyui-logo.svg",  # 可选，SVG 图标文件名
    description: "Tailwind CSS 组件库"
  },
  "action-policy" => {
    name: "Action Policy",
    icon: nil,  # 如果没有图标，使用 nil
    description: "授权框架"
  }
}.freeze
```

#### 4. 编写规则内容

技术栈规则的内容应该包括：

- **核心原则**：技术栈使用的核心原则
- **参考文档**：官方文档和参考资料
- **开发规范**：具体的开发规范和最佳实践
- **代码示例**：示例代码和反例对比
- **常见任务**：常见开发任务的步骤
- **注意事项**：重要的注意事项和陷阱

**推荐结构**：

```markdown
---
description: [技术栈名称] 开发规则和最佳实践
alwaysApply: false
---

# [技术栈名称] 开发规则

## 核心原则

1. 原则 1
2. 原则 2

## 官方文档

- [官方文档](URL)
- [API 参考](URL)

## 开发规范

### 代码规范示例

```ruby
# 示例代码
```

## 常见任务

### 任务 1：...

步骤说明...

## 注意事项

1. 注意事项 1
2. 注意事项 2
```

### 查看技术栈规则

技术栈规则可以通过以下方式查看：

1. **本地文件**：直接查看 `.cursor/rules/` 目录下的文件
2. **Web 界面**：访问 `/tech_stack/:id` 路径查看技术栈规则详情

例如：

- `/tech_stack/daisy-ui`：查看 DaisyUI 规则
- `/tech_stack/action-policy`：查看 Action Policy 规则

### 技术栈规则示例

查看现有技术栈规则作为参考：

- **daisy-ui.mdc**：DaisyUI 前端开发规则
- **action-policy.mdc**：Action Policy 授权框架规则
- **authentication.mdc**：认证系统开发规则

## 最佳实践

### 指令 vs 规则

**指令（Commands）**：
- 定义 AI 的工作方式和行为模式
- 适用于特定场景下的工作流程
- 文件扩展名：`.md`
- 不需要头部元数据

**规则（Rules）**：
- 提供开发规范和最佳实践
- 适用于开发相关功能时的参考
- 文件扩展名：`.mdc`
- 需要头部元数据（`description` 和 `alwaysApply`）

### 何时创建指令？

创建指令的场景：

- ✅ 需要定义 AI 的工作流程
- ✅ 需要规范 AI 的行为模式
- ✅ 需要定义特定场景下的执行方式

示例：

- 继续完成项目工作
- 智能继续工作
- 自主工作模式
- 日报管理

### 何时创建规则？

创建规则的场景：

- ✅ 需要提供开发规范
- ✅ 需要记录最佳实践
- ✅ 需要记录技术栈使用规范

示例：

- 认证系统开发规范
- DaisyUI 前端开发规范
- Action Policy 授权框架规范
- Rails 缓存开发规范

### 何时保存经验？

保存经验的场景：

- ✅ 遇到疑难问题并已解决
- ✅ 解决方案有参考价值
- ✅ 需要记录关键经验

示例：

- 第三方库集成问题
- 配置问题
- 性能优化经验
- 安全相关经验

### 何时记录技术栈？

记录技术栈的场景：

- ✅ 项目使用了新的技术栈
- ✅ 技术栈有特定的使用规范
- ✅ 需要记录最佳实践

示例：

- 前端框架（DaisyUI、Tailwind CSS）
- 后端框架（Rails、Warden）
- 授权框架（Action Policy）
- 缓存系统（Solid Cache）

## 常见问题

### Q1: 指令和规则有什么区别？

**A**: 指令定义 AI 的工作方式，规则提供开发规范。指令是 `.md` 文件，不需要元数据；规则是 `.mdc` 文件，需要头部元数据。

### Q2: 如何让 AI 自动识别我的规则？

**A**: 确保规则文件的 `description` 字段清晰明确，包含相关的技术关键词。AI 会根据 `description` 自动识别何时应该参考这个规则。

### Q3: 经验文件可以放在其他目录吗？

**A**: 不建议。经验文件应该统一放在 `docs/experiences/` 目录下，这样可以：

- 统一管理
- 通过 Web 界面查看
- 便于索引和搜索

### Q4: 技术栈规则必须注册吗？

**A**: 不是必须的。如果只是作为开发参考，可以不注册。但如果需要通过 Web 界面查看，需要在 `TechStackController` 中注册。

### Q5: 如何让 AI 使用我的指令？

**A**: 在 Cursor 中使用斜线命令执行指令，例如：

```bash
/continue-project-work
/smart-go
/autonomous-work
```

或者直接描述指令内容，AI 会自动识别。

### Q6: 规则文件的 `alwaysApply` 应该设置为什么？

**A**: 大多数情况下使用 `false`。只有以下情况使用 `true`：

- 通用基础规则（如 `base.mdc`）
- 项目特定规则（如 `workspace.mdc`）

其他规则文件应该使用 `false`，避免增加 AI 的上下文负担。

### Q7: 如何更新现有的指令或规则？

**A**: 直接编辑对应的文件即可。修改后，AI 会自动识别新的内容。不需要重启或重新加载。

### Q8: 经验文件需要什么格式？

**A**: 经验文件使用 Markdown 格式，建议包含：

- 问题描述
- 问题原因分析
- 解决方案
- 关键经验总结
- 相关文件列表
- 参考资料

详细模板请参考 `docs/experiences/README.md`。

## 相关资源

### 文档索引

- [项目主页](../README.md)
- [开发者指南](DEVELOPER_GUIDE.md)
- [使用指南](USAGE_GUIDE.md)
- [功能清单](FEATURES.md)

### 规则文件

- [指令文件创建指南](../.cursor/rules/cursor-commands.mdc)
- [规则文件创建指南](../.cursor/rules/cursor-rules.mdc)
- [通用基础规则](../.cursor/rules/base.mdc)
- [项目特定规则](../.cursor/rules/workspace.mdc)

### 经验库

- [经验索引](experiences/README.md)
- [经验列表](experiences/)

---

**最后更新**：2025-12-02  
**维护者**：BuildX.work 团队

