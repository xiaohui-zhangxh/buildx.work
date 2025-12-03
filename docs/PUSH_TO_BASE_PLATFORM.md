# 将基础平台变更推送到 BuildX.work 仓库

> 如何将通用文档和基础功能的变更推送到 buildx.work 基础平台

## 📋 概述

当你在 fork 项目中对基础平台进行了改进（如通用文档更新、规则文件更新、基础功能修复等），需要将这些变更推送到 buildx.work 基础平台。

## 🔍 识别基础平台变更

### ✅ 属于基础平台的变更

- **通用文档**：
  - `docs/PROJECT_CREATION_GUIDE.md`
  - `docs/USAGE_GUIDE.md`
  - `docs/DEVELOPER_GUIDE.md`
  - `docs/CONTRIBUTING.md`
  - `docs/README.md`
  - `docs/phase-*/` 目录下的文档
  - `.cursor/rules/*.mdc` 规则文件
  - `.cursor/commands/*.md` 指令文件

- **基础功能代码**：
  - `app/controllers/application_controller.rb`
  - `app/models/user.rb`
  - `app/helpers/application_helper.rb`
  - `app/controllers/admin/` 下的文件
  - `app/controllers/sessions_controller.rb`
  - 其他基础设施相关的代码

### ❌ 不属于基础平台的变更

- **业务特定文档**：
  - `docs/project-*/` 目录下的所有文件
  - `CURRENT_WORK.md`（如果包含业务特定内容）

- **业务代码**：
  - `app/models/card.rb`（业务模型）
  - `app/controllers/cards_controller.rb`（业务控制器）
  - 其他业务特定的代码

## 🚀 推送流程

### 方法一：直接推送到本地 buildx.work 仓库（推荐）

如果你的 `origin` 指向本地的 buildx.work 仓库：

#### 步骤 1：检查当前状态

```bash
# 查看当前 git remote 配置
git remote -v

# 查看当前变更
git status
```

#### 步骤 2：识别基础平台变更

```bash
# 查看所有变更（排除业务文档）
git status --short | grep -v "project-cardx" | grep -v "CURRENT_WORK.md"

# 或者查看特定文件的变更
git diff docs/PROJECT_CREATION_GUIDE.md
git diff .cursor/rules/buildx-project-type.mdc
```

#### 步骤 3：创建提交（只包含基础平台变更）

```bash
# 方式 1：逐个添加基础平台文件
git add docs/PROJECT_CREATION_GUIDE.md
git add .cursor/rules/buildx-project-type.mdc
git add .cursor/commands/*.md
# ... 添加其他基础平台文件 ...

# 方式 2：使用 git add -p 交互式选择变更
git add -p docs/PROJECT_CREATION_GUIDE.md

# 提交
git commit -m "docs: 脱敏通用文档中的项目名称

- 将 project-cardx 替换为 project-[project-name]
- 将具体项目名称替换为通用占位符
- 更新所有规则和指令文件中的引用"
```

#### 步骤 4：推送到 buildx.work 仓库

```bash
# 推送到 origin（buildx.work 仓库）
git push origin main

# 或者推送到特定分支
git push origin main:main
```

### 方法二：创建补丁并应用到 buildx.work

适用于：需要更精确控制提交内容的情况

#### 步骤 1：在 fork 项目中创建提交

```bash
# 只提交基础平台变更
git add docs/PROJECT_CREATION_GUIDE.md .cursor/rules/buildx-project-type.mdc
git commit -m "docs: 脱敏通用文档中的项目名称"
```

#### 步骤 2：生成补丁文件

```bash
# 找到提交的 hash
git log --oneline -1

# 生成补丁文件（假设提交 hash 是 abc1234）
git format-patch -1 abc1234 --stdout > /tmp/base-platform-fix.patch
```

#### 步骤 3：切换到 buildx.work 仓库并应用补丁

```bash
# 切换到 buildx.work 目录
cd /path/to/buildx.work

# 创建新分支
git checkout -b docs/desensitize-project-names

# 应用补丁
git am /tmp/base-platform-fix.patch

# 检查变更
git diff main

# 提交
git commit -m "docs: 脱敏通用文档中的项目名称

- 将 project-cardx 替换为 project-[project-name]
- 将具体项目名称替换为通用占位符
- 更新所有规则和指令文件中的引用"

# 推送到 buildx.work 仓库
git push origin docs/desensitize-project-names
```

### 方法三：手动复制变更（适用于复杂变更）

#### 步骤 1：在 fork 项目中识别变更的文件

```bash
# 查看变更的文件列表
git status --short | grep -v "project-cardx"

# 查看具体变更内容
git diff docs/PROJECT_CREATION_GUIDE.md
```

#### 步骤 2：在 buildx.work 中创建分支并复制变更

```bash
# 切换到 buildx.work 目录
cd /path/to/buildx.work

# 创建新分支
git checkout -b docs/desensitize-project-names

# 复制变更的文件
cp /path/to/cardx/docs/PROJECT_CREATION_GUIDE.md \
   /path/to/buildx.work/docs/PROJECT_CREATION_GUIDE.md

cp /path/to/cardx/.cursor/rules/buildx-project-type.mdc \
   /path/to/buildx.work/.cursor/rules/buildx-project-type.mdc

# ... 复制其他文件 ...
```

#### 步骤 3：提交并推送

```bash
# 检查变更
git diff

# 提交
git add docs/PROJECT_CREATION_GUIDE.md .cursor/rules/buildx-project-type.mdc
git commit -m "docs: 脱敏通用文档中的项目名称"

# 推送到 buildx.work 仓库
git push origin docs/desensitize-project-names
```

## 📝 提交信息规范

提交信息应该清晰描述变更内容：

```
docs: 脱敏通用文档中的项目名称

- 将 project-cardx 替换为 project-[project-name]
- 将具体项目名称（如 CardX）替换为通用占位符
- 更新所有规则和指令文件中的引用
- 确保通用文档不包含内部项目信息

影响范围：
- docs/PROJECT_CREATION_GUIDE.md
- .cursor/rules/buildx-project-type.mdc
- .cursor/rules/project-creation-workflow.mdc
- .cursor/commands/*.md
```

## ✅ 推送前检查清单

在推送前，确保：

- [ ] 只包含基础平台的变更（不包含业务特定文件）
- [ ] 已排除 `docs/project-*/` 目录下的所有文件
- [ ] 已排除 `CURRENT_WORK.md`（如果包含业务特定内容）
- [ ] 提交信息清晰描述变更内容
- [ ] 变更已通过检查（文档格式、链接有效性等）

## 🔍 验证变更

推送后，验证变更是否正确：

```bash
# 在 buildx.work 仓库中检查
cd /path/to/buildx.work
git log --oneline -5
git show <commit-hash>

# 验证文件内容
grep -r "project-cardx" docs/ .cursor/
# 应该没有匹配结果（除了业务文档目录）
```

## ⚠️ 注意事项

1. **不要提交业务文档**：
   - 确保 `docs/project-*/` 目录下的文件不会被提交
   - 使用 `.gitignore` 或 `git add` 时明确排除

2. **保持提交信息清晰**：
   - 说明变更的原因和影响范围
   - 便于后续维护和追溯

3. **验证变更**：
   - 推送后检查 buildx.work 仓库中的变更
   - 确保没有意外提交业务特定内容

4. **同步到其他 fork 项目**：
   - 变更合并到 buildx.work 后，其他 fork 项目可以通过 `git merge` 同步

## 📚 相关文档

- [贡献指南](CONTRIBUTING.md) - 如何将修复贡献回基础设施
- [使用指南](USAGE_GUIDE.md) - 如何使用基础设施
- [项目类型识别规则](../.cursor/rules/buildx-project-type.mdc) - 项目类型识别和开发原则

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-02

