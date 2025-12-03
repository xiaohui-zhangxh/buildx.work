# 同步基础平台更新指南

> 如何检查基础平台更新并同步到业务项目

## 📋 概述

当你在业务项目中开发了很长时间后，基础平台（buildx.work）可能已经有了很多更新。本指南帮助你：

1. **检查基础平台更新**：查看基础平台有哪些新功能和改进
2. **同步更新到业务项目**：将基础平台的更新合并到你的项目
3. **处理合并冲突**：解决更新过程中的冲突
4. **验证更新结果**：确保更新后项目正常运行

## 🔍 检查基础平台更新

### 方法一：使用 Git 命令检查（推荐）

**步骤 1：检查 Git Remote 配置**

```bash
# 查看当前 remote 配置
git remote -v

# 如果没有 upstream，添加它
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
```

**步骤 2：获取基础平台最新代码**

```bash
# 获取基础平台 main 分支的最新代码（不合并）
git fetch upstream main
```

**步骤 3：查看更新内容**

```bash
# 查看基础平台有哪些新提交（你的项目还没有的）
git log HEAD..upstream/main --oneline

# 查看详细的更新内容
git log HEAD..upstream/main

# 查看更新的文件列表
git diff --name-status HEAD..upstream/main

# 查看特定文件的更新内容
git diff HEAD..upstream/main -- app/helpers/application_helper.rb
```

**步骤 4：查看更新摘要**

```bash
# 查看更新的统计信息
git diff --stat HEAD..upstream/main

# 查看更新的文件类型分布
git diff --name-only HEAD..upstream/main | grep -E '\.(rb|erb|js|css|md)$' | sed 's/.*\.//' | sort | uniq -c
```

### 方法二：查看 GitHub Release 和更新通知

1. **访问 GitHub 仓库**：https://github.com/xiaohui-zhangxh/buildx.work
2. **查看 Release**：查看是否有新版本发布
3. **查看提交历史**：查看最近的提交，了解更新内容
4. **查看 Issues 和 PR**：了解新功能和修复

### 方法三：使用 GitHub CLI（如果已安装）

```bash
# 查看基础平台的最近提交
gh repo view xiaohui-zhangxh/buildx.work --json defaultBranchRef --jq '.defaultBranchRef.target.history.nodes[0:10]'

# 查看基础平台的 Release
gh release list --repo xiaohui-zhangxh/buildx.work
```

## 📊 分析更新内容

### 1. 识别更新类型

**功能更新**：
- 新增功能
- 功能改进
- 新工具类、Helper 方法

**修复更新**：
- Bug 修复
- 安全修复
- 性能优化

**文档更新**：
- 文档改进
- 新增文档
- 规则文件更新

**配置更新**：
- 新增配置选项
- 配置改进
- 依赖更新

### 2. 评估更新影响

**低影响更新**（可以直接合并）：
- 文档更新
- 新增功能（不影响现有功能）
- 工具类更新

**中影响更新**（需要测试）：
- 功能改进（可能影响现有功能）
- 配置更新（可能需要调整配置）
- 依赖更新（可能需要更新依赖）

**高影响更新**（需要仔细评估）：
- 破坏性变更（Breaking Changes）
- 重大架构调整
- 数据库迁移

### 3. 查看更新详情

```bash
# 查看特定提交的详细内容
git show <commit-hash>

# 查看特定文件的变更历史
git log HEAD..upstream/main -- app/helpers/application_helper.rb

# 查看特定目录的变更
git diff --stat HEAD..upstream/main -- app/helpers/
git diff --stat HEAD..upstream/main -- lib/
git diff --stat HEAD..upstream/main -- config/initializers/
```

## 🚀 同步更新到业务项目

### 准备工作

**步骤 1：确保工作区干净**

```bash
# 检查当前状态
git status

# 如果有未提交的更改，先提交或暂存
git add .
git commit -m "Save current work before syncing updates"

# 或者使用 stash（临时保存）
git stash save "Before syncing updates"
```

**步骤 2：创建备份分支（推荐）**

```bash
# 创建备份分支
git checkout -b backup-before-sync-$(date +%Y%m%d)

# 提交当前状态
git add .
git commit -m "Backup before syncing updates"

# 切换回主分支
git checkout main
```

### 同步更新流程

**步骤 1：获取基础平台最新代码**

```bash
# 确保 upstream 已配置
git remote -v

# 获取基础平台最新代码
git fetch upstream main
```

**步骤 2：查看更新内容（再次确认）**

```bash
# 查看将要合并的更新
git log HEAD..upstream/main --oneline

# 查看更新的文件列表
git diff --name-status HEAD..upstream/main
```

**步骤 3：合并更新**

```bash
# 合并基础平台的 main 分支
git merge upstream/main

# 或者使用 rebase（如果更喜欢线性历史）
# git rebase upstream/main
```

**步骤 4：处理合并冲突**

如果出现冲突，Git 会标记冲突的文件：

```bash
# 查看冲突文件
git status

# 手动编辑冲突文件，解决冲突
# 冲突标记：
# <<<<<<< HEAD
# 你的代码
# =======
# 基础平台的代码
# >>>>>>> upstream/main

# 解决冲突后，标记为已解决
git add <resolved-file>
```

**冲突处理策略**：

1. **基础设施文件冲突**（如 `app/models/user.rb`）：
   - **策略**：优先保留基础平台的代码
   - **原因**：基础设施代码是标准实现，应该保持一致
   - **例外**：如果你的修改是通用改进，应该贡献回基础平台

2. **配置文件冲突**（如 `config/routes.rb`）：
   - **策略**：合并双方的更改
   - **原因**：路由配置需要同时保留基础设施和业务路由

3. **扩展模块冲突**（如 `app/models/concerns/user_extensions.rb`）：
   - **策略**：保留你的业务扩展
   - **原因**：扩展模块是业务特定的，不应该被覆盖

4. **文档冲突**（如 `README.md`）：
   - **策略**：保留基础平台的文档
   - **原因**：基础平台的文档是标准文档
   - **注意**：业务特定文档应该在 `docs/project-*/` 目录

**步骤 5：提交合并**

```bash
# 解决所有冲突后，提交合并
git add .
git commit -m "Merge upstream: sync updates from buildx.work

Updated features:
- Feature 1
- Feature 2

Fixes:
- Bug fix 1
- Bug fix 2"
```

**步骤 6：测试更新**

```bash
# 运行测试
bin/rails test

# 检查代码质量
bin/rubocop

# 启动开发服务器，手动测试
bin/dev
```

**步骤 7：推送更新**

```bash
# 推送更新到远程仓库
git push

# 如果使用了备份分支，也可以推送备份分支
git push origin backup-before-sync-$(date +%Y%m%d)
```

## 🔧 处理特殊情况

### 情况 1：更新后功能不工作

**可能原因**：
- 配置需要更新
- 依赖需要更新
- API 变更

**解决方法**：

```bash
# 1. 查看更新日志，了解变更
git log HEAD..upstream/main

# 2. 查看相关文档
# 查看 docs/DEVELOPER_GUIDE.md
# 查看 docs/FEATURES.md

# 3. 检查配置
# 查看 config/initializers/ 中的配置
# 查看环境变量配置

# 4. 更新依赖
bundle install
npm install

# 5. 运行数据库迁移（如果有）
bin/rails db:migrate
```

### 情况 2：合并冲突太多

**解决方法**：

1. **分批合并**：
   ```bash
   # 合并特定提交
   git cherry-pick <commit-hash>
   ```

2. **使用扩展模块**：
   - 如果冲突是因为直接修改了基础设施代码
   - 考虑将修改改为扩展模块

3. **创建新分支测试**：
   ```bash
   # 创建测试分支
   git checkout -b test-sync-updates
   git merge upstream/main
   # 在测试分支中解决冲突
   # 测试通过后，合并到主分支
   ```

### 情况 3：需要回退更新

**方法一：使用 revert（推荐）**

```bash
# 查看合并提交
git log --oneline --merges

# 回退合并提交
git revert -m 1 <merge-commit-hash>
```

**方法二：使用 reset（谨慎使用）**

```bash
# 查看合并前的提交
git log --oneline

# 回退到合并前（会丢失合并后的提交）
git reset --hard <commit-before-merge>
```

### 情况 4：只想更新特定文件

**方法一：使用 checkout**

```bash
# 从基础平台获取特定文件
git checkout upstream/main -- app/helpers/application_helper.rb

# 提交更新
git add app/helpers/application_helper.rb
git commit -m "Update: sync application_helper from upstream"
```

**方法二：使用 cherry-pick**

```bash
# 查看特定文件的更新提交
git log upstream/main -- app/helpers/application_helper.rb

# 选择性地合并特定提交
git cherry-pick <commit-hash>
```

## 📋 更新检查清单

### 更新前

- [ ] 检查基础平台更新内容
- [ ] 评估更新影响
- [ ] 创建工作区备份
- [ ] 创建备份分支（推荐）
- [ ] 提交或暂存当前工作

### 更新中

- [ ] 获取基础平台最新代码
- [ ] 查看更新内容（再次确认）
- [ ] 合并更新
- [ ] 解决所有冲突
- [ ] 提交合并

### 更新后

- [ ] 运行测试（`bin/rails test`）
- [ ] 检查代码质量（`bin/rubocop`）
- [ ] 手动测试关键功能
- [ ] 更新依赖（`bundle install`、`npm install`）
- [ ] 运行数据库迁移（如有）
- [ ] 检查配置是否需要更新
- [ ] 推送更新到远程仓库
- [ ] 更新项目文档（如需要）

## 💡 最佳实践

### 1. 定期同步更新

**建议频率**：
- **开发阶段**：每周或每两周同步一次
- **生产阶段**：每月同步一次，或根据基础平台发布节奏

**好处**：
- 避免积累太多更新，减少冲突
- 及时获得新功能和修复
- 保持与基础平台的同步

### 2. 分批合并

**策略**：
- 如果更新太多，考虑分批合并
- 先合并低影响的更新（文档、工具类）
- 再合并中影响的更新（功能改进）
- 最后合并高影响的更新（破坏性变更）

### 3. 使用扩展模块

**原则**：
- 尽量通过扩展模块添加功能，而不是直接修改基础设施代码
- 这样可以减少合并冲突
- 保持代码的可维护性

### 4. 记录更新日志

**建议**：
- 在项目文档中记录每次更新的内容
- 记录遇到的问题和解决方案
- 便于后续参考和排查问题

### 5. 测试充分

**建议**：
- 更新后运行所有测试
- 手动测试关键功能
- 在测试环境验证后再部署到生产环境

## 📚 相关资源

- [使用指南](USAGE_GUIDE.md) - 如何使用基础设施
- [贡献指南](CONTRIBUTING.md) - 如何贡献修复和改进
- [功能贡献指南](FEATURE_CONTRIBUTION.md) - 如何贡献新功能
- [开发者指南](DEVELOPER_GUIDE.md) - 技术决策和架构设计

## ❓ 常见问题

### Q1: 如何知道基础平台有更新？

**A**: 使用以下方法：

```bash
# 方法 1：使用 Git 命令
git fetch upstream
git log HEAD..upstream/main --oneline

# 方法 2：查看 GitHub Release
# 访问 https://github.com/xiaohui-zhangxh/buildx.work/releases

# 方法 3：订阅更新通知
# 在 GitHub 上 Watch 仓库，接收更新通知
```

### Q2: 更新后测试失败怎么办？

**A**: 

1. **查看更新日志**：了解更新内容
2. **检查配置**：查看是否需要更新配置
3. **检查依赖**：运行 `bundle install` 和 `npm install`
4. **查看文档**：查看相关文档了解变更
5. **回退更新**：如果问题严重，可以回退更新

### Q3: 可以跳过某些更新吗？

**A**: 可以，但不推荐：

```bash
# 方法 1：使用 cherry-pick 选择性合并
git cherry-pick <commit-hash>

# 方法 2：手动合并特定文件
git checkout upstream/main -- <file-path>
```

**注意**：跳过更新可能导致：
- 功能不完整
- 安全问题
- 兼容性问题

### Q4: 更新后如何验证？

**A**: 

1. **运行测试**：`bin/rails test`
2. **检查代码质量**：`bin/rubocop`
3. **手动测试**：启动开发服务器，测试关键功能
4. **检查日志**：查看是否有错误或警告

### Q5: 更新频率应该是多少？

**A**: 

- **开发阶段**：每周或每两周一次
- **生产阶段**：每月一次，或根据基础平台发布节奏
- **安全更新**：立即更新

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-02  
**维护者**：BuildX.work 团队

