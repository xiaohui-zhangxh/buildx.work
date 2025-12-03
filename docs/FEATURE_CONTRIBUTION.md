# 功能贡献指南

> 如何从新项目中识别、提取和贡献通用功能到 BuildX.work 基础平台

## 📋 概述

当你在新项目中开发了有用的通用功能时，可以通过以下流程将其贡献回 BuildX.work 基础平台，让所有项目都能受益。

**重要**：BuildX.work 是 GitHub 开源项目，所有贡献必须通过 **GitHub Pull Request** 提交。请遵循 GitHub 最佳实践，确保贡献流程清晰、可维护。

**本文档与 [贡献指南](CONTRIBUTING.md) 的区别**：
- **贡献指南**：主要说明如何贡献**修复**（bug fix）和改进
- **功能贡献指南**（本文档）：主要说明如何贡献**新功能**（feature）和通用代码

**贡献方式**：
- ✅ **推荐方式**：使用 AI 指令自动识别和贡献（`/contribute-code`）
- ✅ **备选方式**：手动通过 GitHub Pull Request 提交
- ❌ **不支持**：Git 补丁、直接提交、邮件等方式

## 🚀 快速开始：使用 AI 指令自动贡献（推荐）

**最简单的方式**：使用 Cursor 的代码贡献指令自动识别和贡献代码。

### 使用步骤

1. **在 Cursor 中执行指令**：
   ```
   /contribute-code
   ```
   或直接描述：
   ```
   找出可以贡献的代码
   贡献代码到基础平台
   ```

2. **AI 自动执行**：
   - ✅ 检查 upstream remote 配置
   - ✅ 拉取基础平台最新代码
   - ✅ 检查当前分支状态
   - ✅ 对比代码差异，识别可贡献代码
   - ✅ 生成贡献建议报告
   - ✅ 等待你确认

3. **确认贡献**：
   - 查看贡献建议报告
   - 确认要贡献的代码
   - AI 自动创建贡献分支并智能合并代码

4. **提交 PR**：
   - 按照 AI 生成的 PR 提交指南操作
   - 推送贡献分支到 GitHub
   - 创建 Pull Request

### AI 指令的优势

- ✅ **自动化**：自动执行所有步骤，减少手动操作
- ✅ **智能识别**：智能识别可贡献代码，区分基础功能和业务功能
- ✅ **智能合并**：智能合并代码到贡献分支，处理位置差异和冲突
- ✅ **详细报告**：生成详细的贡献建议报告和 PR 提交指南

**详细说明**：参考 [代码贡献指令](../.cursor/commands/80-contribute-code.md)

## 🎯 贡献场景

### 场景 1：在新项目中开发了通用功能

**示例**：
- 开发了一个通用的文件上传组件
- 实现了一个通用的数据导出功能
- 创建了一个通用的表单验证工具
- 开发了一个通用的通知系统

**判断标准**：这个功能是否可以在其他项目中复用？

### 场景 2：在业务代码中发现了通用模式

**示例**：
- 多个业务模型都使用了类似的验证逻辑
- 多个控制器都使用了类似的权限检查
- 多个视图都使用了类似的 UI 组件

**判断标准**：这个模式是否可以抽象为通用功能？

### 场景 3：优化了基础平台的功能

**示例**：
- 改进了认证流程的用户体验
- 优化了权限检查的性能
- 增强了管理后台的功能
- 更新了通用文档和规则文件

**判断标准**：这个优化是否对所有项目都有价值？

### 场景 4：更新了通用文档和规则

**示例**：
- 更新了 `.cursor/rules/*.mdc` 规则文件
- 更新了 `.cursor/commands/*.md` 指令文件
- 更新了 `docs/` 目录下的通用文档（排除 `docs/project-*/`）

**判断标准**：这个文档更新是否对所有项目都有价值？

## 🔍 识别可贡献代码

### ✅ 应该贡献的代码

#### 1. 通用工具类和 Helper 方法

**特征**：
- 不依赖业务逻辑
- 可以在多个场景下使用
- 提供通用的功能

**示例**：
- `app/helpers/application_helper.rb` 中的通用方法
- `lib/` 目录下的工具类
- `app/forms/` 中的通用表单类

**判断问题**：
- ❓ 这个方法是否只适用于当前业务？
- ❓ 如果去掉业务特定逻辑，是否还有通用价值？
- ❓ 其他项目是否也需要这个功能？

#### 2. 通用组件和 Partial

**特征**：
- 不包含业务特定内容
- 可以通过参数配置
- 可以在多个页面复用

**示例**：
- 通用的表单组件
- 通用的列表组件
- 通用的模态框组件

**判断问题**：
- ❓ 这个组件是否包含业务特定的样式或逻辑？
- ❓ 是否可以通过参数化使其通用化？
- ❓ 其他项目是否也需要类似的组件？

#### 3. 通用控制器功能

**特征**：
- 提供通用的 CRUD 操作
- 不依赖业务模型
- 可以通过配置或继承使用

**示例**：
- 通用的资源管理控制器
- 通用的搜索功能
- 通用的批量操作功能

**判断问题**：
- ❓ 这个功能是否依赖特定的业务模型？
- ❓ 是否可以通过抽象使其通用化？
- ❓ 其他项目是否也需要类似的功能？

#### 4. 通用模型功能（Concern/Module）

**特征**：
- 提供通用的模型行为
- 不依赖业务特定逻辑
- 可以通过 include 使用

**示例**：
- 通用的软删除功能
- 通用的状态机
- 通用的审计日志功能

**判断问题**：
- ❓ 这个功能是否只适用于特定业务场景？
- ❓ 是否可以通过配置使其通用化？
- ❓ 其他项目是否也需要类似的功能？

#### 5. 通用配置和初始化

**特征**：
- 提供通用的配置选项
- 不依赖业务特定设置
- 可以通过环境变量或配置文件使用

**示例**：
- 通用的第三方服务配置
- 通用的缓存配置
- 通用的任务队列配置

**判断问题**：
- ❓ 这个配置是否只适用于当前业务？
- ❓ 是否可以通过参数化使其通用化？
- ❓ 其他项目是否也需要类似的配置？

#### 6. 通用测试工具和 Fixture

**特征**：
- 提供通用的测试辅助方法
- 不依赖业务特定数据
- 可以在多个测试中使用

**示例**：
- 通用的测试 Helper
- 通用的 Factory 定义
- 通用的测试 Fixture

**判断问题**：
- ❓ 这个测试工具是否只适用于特定业务？
- ❓ 是否可以通过参数化使其通用化？
- ❓ 其他项目是否也需要类似的测试工具？

#### 7. 通用文档和规则

**特征**：
- 提供通用的文档和规则
- 不包含业务特定内容
- 可以在多个项目中使用

**示例**：
- `.cursor/rules/*.mdc` 规则文件
- `.cursor/commands/*.md` 指令文件
- `docs/` 目录下的通用文档（排除 `docs/project-*/`）

**判断问题**：
- ❓ 这个文档是否只适用于当前业务？
- ❓ 是否可以通过通用化使其适用于所有项目？
- ❓ 其他项目是否也需要这个文档？

### ❌ 不应该贡献的代码

#### 1. 业务特定功能

**特征**：
- 包含业务特定的逻辑
- 依赖业务特定的模型
- 只适用于特定业务场景

**示例**：
- 业务特定的控制器（如 `CardsController`）
- 业务特定的模型（如 `Card`、`Deck`）
- 业务特定的视图和路由

#### 2. 业务特定配置

**特征**：
- 包含业务特定的设置
- 依赖业务特定的环境变量
- 只适用于特定业务场景

**示例**：
- 业务特定的第三方服务配置
- 业务特定的路由配置
- 业务特定的初始化代码

#### 3. 业务特定测试

**特征**：
- 测试业务特定的功能
- 使用业务特定的数据
- 只适用于特定业务场景

**示例**：
- 业务功能的测试用例
- 业务特定的测试数据
- 业务特定的测试场景

#### 4. 业务文档

**特征**：
- 包含业务特定的内容
- 只适用于特定业务场景

**示例**：
- `docs/project-*/` 目录下的所有文件
- `CURRENT_WORK.md`（如果包含业务特定内容）

## 🔧 提取和通用化处理

### 步骤 1：识别代码边界

**目标**：确定哪些代码需要提取，哪些需要保留在业务项目中。

**方法**：

1. **分析代码依赖**：
   - 列出所有依赖的业务模型
   - 列出所有依赖的业务配置
   - 列出所有依赖的业务 Helper

2. **识别通用部分**：
   - 找出不依赖业务逻辑的部分
   - 找出可以通过参数配置的部分
   - 找出可以抽象为接口的部分

3. **确定提取范围**：
   - 哪些文件需要提取？
   - 哪些方法需要提取？
   - 哪些配置需要提取？

### 步骤 2：移除业务特定逻辑

**目标**：将业务特定逻辑替换为通用接口或配置。

**方法**：

1. **参数化业务特定值**：

```ruby
# ❌ 业务特定代码
def find_cards_by_user(user)
  Card.where(user_id: user.id)
end

# ✅ 通用化代码
def find_resources_by_user(resource_class, user)
  resource_class.where(user_id: user.id)
end
```

2. **抽象业务特定逻辑**：

```ruby
# ❌ 业务特定代码
def validate_card_number(card_number)
  card_number.length == 16
end

# ✅ 通用化代码
def validate_with_custom_rule(value, rule)
  rule.call(value)
end
```

3. **使用配置替代硬编码**：

```ruby
# ❌ 业务特定代码
def max_cards_per_user
  10
end

# ✅ 通用化代码
def max_resources_per_user
  Rails.application.config.max_resources_per_user || 10
end
```

### 步骤 3：确保向后兼容

**目标**：确保新功能不会破坏现有功能。

**方法**：

1. **检查现有功能**：
   - 列出所有可能受影响的功能
   - 运行所有测试确保通过
   - 检查是否有破坏性变更

2. **提供迁移路径**：
   - 如果引入新功能，提供清晰的迁移指南
   - 如果修改现有功能，保持向后兼容
   - 如果删除功能，提供替代方案

3. **更新文档**：
   - 更新相关文档说明新功能
   - 更新使用指南
   - 更新 API 文档（如有）

### 步骤 4：编写测试

**目标**：确保新功能有完整的测试覆盖。

**方法**：

1. **单元测试**：
   - 测试每个方法的正常情况
   - 测试边界情况
   - 测试错误情况

2. **集成测试**：
   - 测试功能与其他组件的集成
   - 测试配置选项
   - 测试扩展点

3. **测试覆盖率**：
   - 确保测试覆盖率至少 85%
   - 确保关键路径有测试覆盖
   - 确保边界情况有测试覆盖

## 🚀 贡献流程

> **重要**：BuildX.work 是 GitHub 开源项目，所有贡献必须通过 GitHub Pull Request 提交。请遵循 GitHub 最佳实践，确保贡献流程清晰、可维护。

### 方式一：使用 AI 指令自动贡献（推荐）

**这是最简单的方式**，AI 会自动执行所有步骤：

1. **执行指令**：在 Cursor 中执行 `/contribute-code`
2. **AI 自动执行**：
   - 检查 upstream remote 配置
   - 拉取基础平台最新代码
   - 检查当前分支状态
   - 对比代码差异，识别可贡献代码
   - 生成贡献建议报告
3. **确认贡献**：查看报告，确认要贡献的代码
4. **AI 自动合并**：AI 创建贡献分支并智能合并代码
5. **提交 PR**：按照 AI 生成的 PR 提交指南操作

**详细说明**：参考 [代码贡献指令](../.cursor/commands/80-contribute-code.md)

### 方式二：手动通过 GitHub Pull Request 贡献

如果不想使用 AI 指令，可以手动执行以下步骤：

#### 步骤 1：Fork 基础平台仓库

在 GitHub 上 Fork `xiaohui-zhangxh/buildx.work` 到你的账户。

**重要**：如果已经 Fork 过，请先同步上游更新：

```bash
cd buildx.work
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

#### 步骤 2：克隆你的 Fork

```bash
git clone https://github.com/your-username/buildx.work.git
cd buildx.work
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
```

#### 步骤 3：创建功能分支

```bash
# 确保 main 分支是最新的
git checkout main
git pull upstream main

# 创建功能分支（使用清晰的命名）
git checkout -b feature/feature-name
# 或
git checkout -b feature/add-generic-file-upload
```

**分支命名规范**：
- 功能：`feature/feature-name` 或 `feature/add-feature-name`
- 修复：`fix/issue-description`
- 文档：`docs/update-documentation`

#### 步骤 4：提取和通用化代码

在功能分支上进行以下操作：

1. **提取代码**：
   - 从业务项目中提取通用代码
   - 创建新文件或修改现有文件
   - 移除业务特定逻辑

2. **通用化处理**：
   - 参数化业务特定值
   - 抽象业务特定逻辑
   - 使用配置替代硬编码

3. **添加测试**：
   - 为新功能添加测试
   - 确保测试覆盖率至少 85%
   - 确保所有测试通过

4. **更新文档**：
   - 更新相关文档说明新功能
   - 添加使用示例
   - 更新功能清单（如需要）

5. **提交代码**：

```bash
# 添加文件
git add lib/generic_feature.rb
git add test/lib/generic_feature_test.rb
git add docs/DEVELOPER_GUIDE.md

# 提交（使用规范的提交信息）
git commit -m "Add: generic feature name

Description of the feature and why it's useful for all projects.

Features:
- Feature 1
- Feature 2

Usage:
  # Example usage

Closes #123"  # 如果有相关 Issue
```

**提交信息规范**：
- 使用 `Add:` 前缀表示新功能
- 第一行简短描述（50 字符以内）
- 详细说明功能、使用场景、实现方案
- 如果有关联 Issue，使用 `Closes #123` 或 `Fixes #123`

#### 步骤 5：推送分支并创建 Pull Request

```bash
# 推送分支到你的 Fork
git push origin feature/feature-name
```

然后在 GitHub 上创建 Pull Request：

1. **访问你的 Fork**：https://github.com/your-username/buildx.work
2. **点击 "New Pull Request"**
3. **选择分支**：base: `main` ← compare: `feature/feature-name`
4. **填写 PR 描述**（使用模板）：

```markdown
## 📋 功能描述

简要描述这个功能是什么，解决了什么问题。

## 🎯 使用场景

在什么场景下使用？有哪些项目需要这个功能？

## 🔧 实现方案

如何实现的？有哪些设计决策？

## ✅ 测试结果

- [ ] 所有测试通过
- [ ] 测试覆盖率至少 85%
- [ ] 代码质量检查通过（RuboCop）

测试覆盖率：XX%
测试结果：XXX 个测试，XXX 个断言，0 失败

## 🔄 向后兼容

- [ ] 不破坏现有功能
- [ ] 保持向后兼容
- [ ] 提供迁移指南（如需要）

## 📚 文档更新

- [ ] 已更新相关文档
- [ ] 已添加使用示例
- [ ] 已更新功能清单（如需要）

## 🔗 相关资源

- 相关 Issue：#123
- 相关文档：[链接]
```

#### 步骤 6：代码审查和合并

1. **等待审查**：维护者会审查你的 PR
2. **响应反馈**：根据审查意见进行修改
3. **保持更新**：如果上游有更新，及时同步：

```bash
git fetch upstream
git checkout feature/feature-name
git merge upstream/main
# 解决冲突（如果有）
git push origin feature/feature-name
```

4. **合并后**：PR 合并后，可以删除功能分支：

```bash
git checkout main
git pull upstream main
git branch -d feature/feature-name
git push origin --delete feature/feature-name
```

## 📝 提交信息规范

提交信息应该清晰描述功能内容：

```
Add: short description (50 chars max)

Longer explanation of what was added and why. This can span
multiple lines and should explain:
- What the feature is
- Why it's useful for all projects
- How to use it
- Any breaking changes (if applicable)
```

示例：

```
Add: generic file upload component with progress tracking

This component provides a reusable file upload interface with
progress tracking, drag-and-drop support, and validation.

Features:
- Drag-and-drop file upload
- Upload progress tracking
- File type and size validation
- Error handling and retry mechanism

Usage:
  <%= render "shared/file_upload", 
      model: @document, 
      field: :file,
      accept: "image/*" %>

This feature is extracted from project-x where it was used for
document uploads, but it's generic enough to be useful for all
projects that need file upload functionality.
```

## ✅ 贡献检查清单

在提交功能前，确保：

### 代码质量

- [ ] 代码已通过所有测试（`bin/rails test`）
- [ ] 代码符合项目规范（`bin/rubocop`）
- [ ] 测试覆盖率至少 85%
- [ ] 代码已移除所有业务特定逻辑
- [ ] 代码已参数化或配置化
- [ ] 代码已添加必要的注释和文档

### 功能完整性

- [ ] 功能确实属于通用功能，可以在多个项目中使用
- [ ] 功能已通过通用化处理，不依赖业务特定逻辑
- [ ] 功能已提供清晰的接口和使用方法
- [ ] 功能已提供必要的配置选项
- [ ] 功能已提供扩展点（如需要）

### 向后兼容

- [ ] 新功能不破坏现有功能
- [ ] 如果修改现有功能，保持向后兼容
- [ ] 如果删除功能，提供替代方案
- [ ] 已提供迁移指南（如需要）

### 文档和测试

- [ ] 已添加必要的测试用例
- [ ] 已更新相关文档（如 `docs/DEVELOPER_GUIDE.md`）
- [ ] 已更新功能清单（如 `docs/FEATURES.md`）
- [ ] 已添加使用示例（如需要）
- [ ] 已更新 API 文档（如有）

### 提交信息

- [ ] 提交信息清晰描述功能和用途
- [ ] 提交信息说明为什么这个功能对所有项目有价值
- [ ] 提交信息包含使用示例或链接（如需要）

## 🔄 同步功能到其他项目

功能通过 GitHub Pull Request 合并到基础平台后，需要同步到其他项目：

```bash
cd /path/to/other-project

# 1. 获取上游更新（从 GitHub）
git fetch upstream

# 2. 合并更新
git merge upstream/main

# 3. 解决冲突（如果有）
# ...

# 4. 测试
bin/rails test

# 5. 如果项目中有类似的业务实现，考虑迁移到新功能
# 6. 移除业务特定的实现（如果新功能可以替代）
```

**注意**：同步更新时，确保从 GitHub 仓库（upstream）获取更新，而不是本地路径。

## 💡 最佳实践

### 1. 及时贡献

**原则**：在开发过程中，如果发现某个功能具有通用价值，应该及时考虑贡献。

**方法**：
- 在开发时，思考这个功能是否可以在其他项目中使用
- 如果答案是肯定的，考虑将其设计为通用功能
- 在业务项目中验证功能后，及时贡献回基础平台

### 2. 通用化设计

**原则**：在设计功能时，优先考虑通用性。

**方法**：
- 避免硬编码业务特定值
- 使用配置或参数替代业务特定逻辑
- 提供清晰的接口和扩展点
- 考虑不同项目的使用场景

### 3. 充分测试

**原则**：确保新功能有完整的测试覆盖。

**方法**：
- 编写单元测试覆盖正常情况
- 编写测试覆盖边界情况
- 编写测试覆盖错误情况
- 确保测试覆盖率至少 85%

### 4. 详细文档

**原则**：提供清晰的使用文档和示例。

**方法**：
- 在代码中添加必要的注释
- 更新开发者指南说明新功能
- 提供使用示例和最佳实践
- 说明配置选项和使用场景

### 5. 沟通优先

**原则**：对于重大功能，建议先讨论方案。

**方法**：
- 创建 Issue 讨论功能需求
- 说明功能的使用场景和价值
- 讨论实现方案和设计决策
- 获得反馈后再开始实现

## ⚠️ 注意事项

### 1. 不要贡献业务特定功能

**原则**：只贡献通用功能，不贡献业务特定功能。

**方法**：
- 仔细评估功能是否真的通用
- 如果功能包含业务特定逻辑，先进行通用化处理
- 如果不确定，可以先创建 Issue 讨论

### 2. 保持代码质量

**原则**：确保贡献的代码符合项目规范。

**方法**：
- 运行代码检查工具（`bin/rubocop`）
- 确保测试通过
- 确保测试覆盖率达标
- 遵循项目的代码风格

### 3. 保持向后兼容

**原则**：新功能不应该破坏现有功能。

**方法**：
- 检查新功能是否影响现有功能
- 如果修改现有功能，保持向后兼容
- 如果必须破坏兼容性，提供迁移指南

### 4. 提供扩展点

**原则**：通用功能应该提供扩展点，允许项目定制。

**方法**：
- 使用配置选项允许定制
- 提供回调或钩子方法
- 使用 Module/Concern 便于扩展
- 提供清晰的扩展指南

## 🎯 贡献示例

### 示例 1：贡献通用 Helper 方法

**场景**：在业务项目中开发了一个通用的日期格式化方法。

**步骤**：

1. **识别通用性**：
   - 方法不依赖业务逻辑
   - 可以在多个场景下使用
   - 其他项目也需要类似功能

2. **提取代码**：

```ruby
# 从业务项目中提取
# app/helpers/application_helper.rb
def format_date(date, format = :long)
  # 通用实现
end
```

3. **通用化处理**：
   - 移除业务特定逻辑
   - 添加配置选项
   - 添加测试

4. **贡献到基础平台**：
   - 使用 `/contribute-code` 指令自动贡献
   - 或手动在 buildx.work 中创建功能分支
   - 添加通用方法
   - 添加测试
   - 提交 PR

### 示例 2：贡献通用组件

**场景**：在业务项目中开发了一个通用的文件上传组件。

**步骤**：

1. **识别通用性**：
   - 组件不包含业务特定内容
   - 可以通过参数配置
   - 其他项目也需要类似组件

2. **提取代码**：
   - 提取视图 partial
   - 提取 JavaScript 控制器
   - 提取 Helper 方法

3. **通用化处理**：
   - 移除业务特定样式
   - 参数化配置选项
   - 添加测试

4. **贡献到基础平台**：
   - 使用 `/contribute-code` 指令自动贡献
   - 或手动在 buildx.work 中创建功能分支
   - 添加通用组件
   - 添加测试
   - 更新文档
   - 提交 PR

## 📚 相关资源

- [代码贡献指令](../.cursor/commands/80-contribute-code.md) ⭐ - 使用 AI 指令自动贡献（推荐）
- [贡献指南](CONTRIBUTING.md) - 如何贡献修复和改进
- [使用指南](USAGE_GUIDE.md) - 如何使用基础设施
- [开发者指南](DEVELOPER_GUIDE.md) - 技术决策和架构设计
- [新项目创建指南](PROJECT_CREATION_GUIDE.md) - 如何创建新项目
- [Git 工作流最佳实践](https://guides.github.com/introduction/flow/)

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-03  
**维护者**：BuildX.work 团队
