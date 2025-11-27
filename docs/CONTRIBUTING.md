# 贡献指南

> 如何将子项目中的修复和改进贡献回 BuildX.work 基础设施

## 📋 概述

当你在子项目中发现基础设施代码的问题或需要改进时，可以通过以下流程将修复贡献回基础设施项目。

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

### 方法一：通过 Git 补丁（推荐用于简单修复）

适用于：小的修复、bug 修复、配置调整

#### 步骤 1：在子项目中创建修复

```bash
cd /path/to/your-sub-project
# 修复基础设施代码
# ... 进行修复 ...

# 提交修复
git add app/helpers/application_helper.rb
git commit -m "Fix daisy_form_with: prioritize model over url"
```

#### 步骤 2：生成补丁文件

```bash
# 找到修复的提交
git log --oneline -5

# 生成补丁文件（假设修复的提交是 abc1234）
git format-patch -1 abc1234 --stdout > /tmp/infrastructure-fix.patch
```

#### 步骤 3：在基础设施项目中应用补丁

```bash
cd /path/to/buildx.work

# 创建新分支
git checkout -b fix/daisy-form-with-parameter-wrapping

# 应用补丁
git am /tmp/infrastructure-fix.patch

# 检查更改
git diff main

# 运行测试确保修复正确
bin/rails test

# 提交
git commit -m "Fix daisy_form_with: prioritize model over url to ensure parameter wrapping

When both model and url are provided, the form should still use model
to wrap parameters (e.g., user[email_address]) while allowing url to
override the default form action URL."
```

### 方法二：手动复制修复（推荐用于复杂修复）

适用于：涉及多个文件的修复、需要调整的修复

#### 步骤 1：在子项目中识别修复的文件

```bash
cd /path/to/your-sub-project

# 查看最近的提交
git log --oneline -10

# 查看特定提交的更改
git show <commit-hash> --stat
```

#### 步骤 2：在基础设施项目中创建修复分支

```bash
cd /path/to/buildx.work
git checkout -b fix/description-of-fix
```

#### 步骤 3：手动复制修复

```bash
# 复制修复的文件（从子项目到基础设施）
cp /path/to/your-sub-project/app/helpers/application_helper.rb \
   /path/to/buildx.work/app/helpers/application_helper.rb

# 或者使用 diff 查看差异，然后手动应用
diff -u \
  /path/to/buildx.work/app/helpers/application_helper.rb \
  /path/to/your-sub-project/app/helpers/application_helper.rb
```

#### 步骤 4：测试和提交

```bash
# 运行测试
bin/rails test

# 检查代码质量
bin/rubocop

# 提交修复
git add app/helpers/application_helper.rb
git commit -m "Fix: description of the fix

Detailed explanation of what was fixed and why."
```

### 方法三：通过 Pull Request（如果使用 GitHub）

如果基础设施项目托管在 GitHub 上：

#### 步骤 1：Fork 基础设施仓库

在 GitHub 上 Fork `xiaohui-zhangxh/buildx.work` 到你的账户

#### 步骤 2：克隆你的 Fork

```bash
git clone https://github.com/your-username/buildx.work.git
cd buildx.work
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
```

#### 步骤 3：创建修复分支并应用修复

```bash
git checkout -b fix/description-of-fix

# 应用修复（使用方法一或方法二）
# ...

# 推送分支
git push origin fix/description-of-fix
```

#### 步骤 4：创建 Pull Request

在 GitHub 上创建 Pull Request，详细说明：
- 问题描述
- 修复方案
- 测试结果
- 相关 Issue（如果有）

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

修复被合并到基础设施后，需要同步到其他子项目：

```bash
cd /path/to/other-sub-project

# 获取上游更新
git fetch upstream

# 合并更新
git merge upstream/main

# 解决冲突（如果有）
# ...

# 测试
bin/rails test
```

## 📚 相关资源

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

