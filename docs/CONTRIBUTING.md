# 贡献指南

> 如何将子项目中的修复和改进贡献回 BuildX.work 基础设施

## 📋 概述

当你在子项目中发现基础设施代码的问题或需要改进时，可以通过以下流程将修复贡献回基础设施项目。

**重要**：BuildX.work 是 GitHub 开源项目，所有贡献必须通过 **GitHub Pull Request** 提交。请遵循 GitHub 最佳实践，确保贡献流程清晰、可维护。

**本文档与 [功能贡献指南](FEATURE_CONTRIBUTION.md) 的区别**：
- **贡献指南**（本文档）：主要说明如何贡献**修复**（bug fix）和改进
- **功能贡献指南**：主要说明如何贡献**新功能**（feature）和通用代码

如果你要贡献新功能，请参考 [功能贡献指南](FEATURE_CONTRIBUTION.md)。

**贡献方式**：
- ✅ **唯一方式**：通过 GitHub Pull Request 提交
- ❌ **不支持**：Git 补丁、直接提交、邮件等方式

## 🔍 识别基础设施代码

在贡献之前，需要识别哪些修复属于基础设施：

### ✅ 属于基础设施的修复

- **核心功能修复**：认证、授权、用户管理、会话管理等
- **基础设施组件**：ApplicationController、ApplicationHelper、ApplicationMailer 等
- **配置和初始化**：initializers、环境配置等
- **通用工具类**：FormBuilder、Helper 方法等
- **数据库迁移**：基础设施相关的表结构变更

### ❌ 不属于基础设施的修复

- **业务特定功能**：业务模型、业务控制器、业务视图
- **业务配置**：业务特定的路由、业务特定的初始化
- **业务测试**：业务功能的测试用例

## 🚀 贡献流程

> **重要**：BuildX.work 是 GitHub 开源项目，所有贡献必须通过 GitHub Pull Request 提交。请遵循 GitHub 最佳实践，确保贡献流程清晰、可维护。

### 通过 GitHub Pull Request 贡献（唯一方式）

**这是唯一推荐的贡献方式**，遵循 GitHub 最佳实践，便于代码审查和维护。

#### 步骤 1：Fork 基础设施仓库

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

#### 步骤 3：创建修复分支

```bash
# 确保 main 分支是最新的
git checkout main
git pull upstream main

# 创建修复分支（使用清晰的命名）
git checkout -b fix/issue-description
# 或
git checkout -b fix/daisy-form-with-parameter-wrapping
```

**分支命名规范**：
- 修复：`fix/issue-description` 或 `fix/bug-description`
- 功能：`feature/feature-name`
- 文档：`docs/update-documentation`

#### 步骤 4：应用修复

在修复分支上进行以下操作：

1. **应用修复**：
   - 修复基础设施代码
   - 确保修复正确
   - 移除业务特定逻辑（如有）

2. **添加测试**：
   - 为新修复添加测试
   - 确保测试覆盖率至少 85%
   - 确保所有测试通过

3. **更新文档**：
   - 更新相关文档说明修复
   - 添加使用示例（如需要）

4. **提交代码**：

```bash
# 添加文件
git add app/helpers/application_helper.rb
git add test/helpers/application_helper_test.rb

# 提交（使用规范的提交信息）
git commit -m "Fix: daisy_form_with parameter wrapping when both model and url provided

When daisy_form_with receives both model and url parameters, it was
ignoring the model parameter, causing form parameters to not be wrapped
in the model namespace (e.g., user[email_address]).

This fix prioritizes model over url, ensuring parameters are correctly
wrapped while still allowing url to override the default form action.

Fixes issue where user registration failed with:
  ActionController::ParameterMissing: param is missing or the value is empty: user

Closes #123"  # 如果有相关 Issue
```

**提交信息规范**：
- 使用 `Fix:` 前缀表示修复
- 第一行简短描述（50 字符以内）
- 详细说明问题、修复方案、影响范围
- 如果有关联 Issue，使用 `Closes #123` 或 `Fixes #123`

#### 步骤 5：推送分支并创建 Pull Request

```bash
# 推送分支到你的 Fork
git push origin fix/issue-description
```

然后在 GitHub 上创建 Pull Request：

1. **访问你的 Fork**：https://github.com/your-username/buildx.work
2. **点击 "New Pull Request"**
3. **选择分支**：base: `main` ← compare: `fix/issue-description`
4. **填写 PR 描述**（使用模板）：

```markdown
## 🐛 问题描述

简要描述问题是什么，在什么场景下出现。

## 🔧 修复方案

如何修复的？修复的关键点是什么？

## ✅ 测试结果

- [ ] 所有测试通过
- [ ] 测试覆盖率至少 85%
- [ ] 代码质量检查通过（RuboCop）

测试覆盖率：XX%
测试结果：XXX 个测试，XXX 个断言，0 失败

## 🔄 影响范围

- [ ] 不破坏现有功能
- [ ] 保持向后兼容
- [ ] 已测试相关功能

## 📚 文档更新

- [ ] 已更新相关文档（如需要）

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
git checkout fix/issue-description
git merge upstream/main
# 解决冲突（如果有）
git push origin fix/issue-description
```

4. **合并后**：PR 合并后，可以删除修复分支：

```bash
git checkout main
git pull upstream main
git branch -d fix/issue-description
git push origin --delete fix/issue-description
```

## 📝 提交信息规范

提交信息应该清晰描述修复内容：

```
Fix: short description (50 chars max)

Longer explanation of what was fixed and why. This can span
multiple lines and should explain:
- What the problem was
- How it was fixed
- Why this fix is correct
- Any breaking changes (if applicable)
```

示例：

```
Fix: daisy_form_with parameter wrapping when both model and url provided

When daisy_form_with receives both model and url parameters, it was
ignoring the model parameter, causing form parameters to not be wrapped
in the model namespace (e.g., user[email_address]).

This fix prioritizes model over url, ensuring parameters are correctly
wrapped while still allowing url to override the default form action.

Fixes issue where user registration failed with:
  ActionController::ParameterMissing: param is missing or the value is empty: user
```

## ✅ 贡献检查清单

在提交修复前，确保：

- [ ] 修复确实属于基础设施代码
- [ ] 修复已通过所有测试（`bin/rails test`）
- [ ] 代码符合项目规范（`bin/rubocop`）
- [ ] 提交信息清晰描述问题和修复
- [ ] 修复不破坏现有功能
- [ ] 如果有新功能，已添加相应测试
- [ ] 已更新相关文档（如果需要）

## 🔄 同步修复到其他子项目

修复通过 GitHub Pull Request 合并到基础设施后，需要同步到其他子项目：

```bash
cd /path/to/other-sub-project

# 获取上游更新（从 GitHub）
git fetch upstream

# 合并更新
git merge upstream/main

# 解决冲突（如果有）
# ...

# 测试
bin/rails test
```

**注意**：同步更新时，确保从 GitHub 仓库（upstream）获取更新，而不是本地路径。

## 📚 相关资源

- [功能贡献指南](FEATURE_CONTRIBUTION.md) ⭐ - 如何贡献新功能和通用代码
- [使用指南](USAGE_GUIDE.md) - 如何使用基础设施
- [开发者指南](DEVELOPER_GUIDE.md) - 技术决策和架构设计
- [Git 工作流最佳实践](https://guides.github.com/introduction/flow/)

## 💡 最佳实践

1. **及时贡献**：发现问题后尽快贡献修复，避免在其他子项目中重复修复
2. **详细说明**：提交信息要详细，方便维护者理解问题和修复
3. **测试充分**：确保修复通过所有测试，不引入新问题
4. **保持同步**：定期从上游合并更新，保持子项目与基础设施同步
5. **沟通优先**：对于重大修复，建议先创建 Issue 讨论方案

## ⚠️ 注意事项

1. **不要直接修改基础设施代码**：在子项目中，基础设施代码应该通过扩展模块扩展，而不是直接修改
2. **区分基础设施和业务代码**：确保只贡献基础设施相关的修复
3. **保持向后兼容**：修复应该保持向后兼容，除非是修复安全漏洞
4. **测试覆盖**：新功能或修复应该包含测试用例

---

**最后更新**：2025-11-27  
**维护者**：BuildX.work 团队

