# 同步基础平台更新

## 概述

将基础平台（buildx.work）的更新同步到业务项目（fork 项目），使用 rebase 方式保持提交历史的线性。适用于 fork 项目，用于同步基础平台的更新。

### 使用方式

**Cursor 斜线命令**：`/sync-upstream`  
**直接描述**：`同步基础平台更新`、`rebase upstream main`、`合并基础平台代码`、`同步上游代码`

## 🎯 核心原则

1. **自动保存工作**：如果分支不干净，自动创建分支保存当前工作，不询问用户
2. **风险分析优先**：先分析更新内容和潜在影响，给出详细风险提示
3. **用户确认**：必须等待用户明确确认后才执行 rebase
4. **信息透明**：显示将要同步的更新内容、风险分析和影响评估
5. **自动处理**：使用 `GIT_EDITOR=true` 避免 vim 弹窗，自动完成 rebase
6. **冲突处理**：检测并协助处理 rebase 过程中的冲突
7. **可回退**：提供回退选项，确保操作安全

## 🔍 工作流程

### 步骤 1：检查项目类型和 Git 状态

**目标**：确认当前项目是 fork 项目，并检查 Git 状态。

**方法**：

1. **检查项目类型**：
   - 检查是否存在 `docs/project-*/` 目录
   - 检查 Git Remote 配置
   - 如果是 buildx.work 项目，提示用户此指令适用于 fork 项目

2. **检查 Git 状态并自动处理**：
   ```bash
   git status --short
   ```
   - **如果当前分支不干净**（有未提交的变更）：
     - **自动创建分支保存当前工作**，不询问用户：
       ```bash
       # 记录当前分支名称
       CURRENT_BRANCH=$(git branch --show-current)
       
       # 创建临时分支保存当前工作（包含操作类型和时间戳，便于识别）
       git checkout -b wip/sync-upstream-$(date +%Y%m%d-%H%M%S)
       git add .
       git commit -m "WIP: 保存当前工作进度（同步 upstream 前自动暂存）"
       
       # 切换回原分支（此时原分支应该是干净的）
       git checkout $CURRENT_BRANCH
       ```
     - **记录暂存分支名称**，用于步骤 8 切换回去
     - **继续执行下一步**（不再停止）
   - **如果当前分支干净**：
     - 继续执行下一步

3. **检查当前分支**：
   ```bash
   git branch --show-current
   ```
   - 建议在 main 分支执行
   - 如果不在 main 分支，提示用户切换

**输出**：
- 项目类型确认
- Git 状态摘要
- 当前分支信息
- 如果有未提交的变更：
  - 列出变更文件
  - 自动创建暂存分支
  - 显示暂存分支名称
  - 提示已自动处理，继续执行

**注意**：
- 这是**必须步骤**，如果当前分支不干净，**自动创建分支保存当前工作**，然后继续执行
- 暂存分支命名格式：`wip/sync-upstream-{timestamp}`，包含操作类型（sync-upstream）和时间戳，便于识别和恢复
- 暂存分支会在步骤 8 中用于切换回之前的工作

### 步骤 2：检查 upstream remote 配置

**目标**：确保 upstream remote 已配置。

**方法**：

1. **检查 remote 配置**：
   ```bash
   git remote -v
   ```

2. **如果没有 upstream，添加它**：
   ```bash
   git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
   ```

3. **验证 upstream 配置**：
   ```bash
   git remote show upstream
   ```

**输出**：
- upstream remote 配置状态
- 如果已配置，显示 upstream URL
- 如果未配置，自动添加并提示用户

### 步骤 3：获取 upstream 最新代码

**目标**：获取基础平台 main 分支的最新代码。

**方法**：

```bash
# 获取基础平台 main 分支的最新代码（不合并）
git fetch upstream main
```

**输出**：
- 获取结果
- 如果有新代码，显示获取的提交数量

### 步骤 4：深度分析更新内容和风险评估

**目标**：深度分析基础平台的更新内容，识别可能影响业务项目的文件，评估冲突风险，给出详细的风险提示。

**方法**：

1. **查看更新摘要**：
   ```bash
   # 查看基础平台有哪些新提交（你的项目还没有的）
   git log HEAD..upstream/main --oneline
   ```

2. **查看更新统计**：
   ```bash
   # 查看更新的统计信息
   git diff --stat HEAD..upstream/main
   ```

3. **查看更新的文件列表**：
   ```bash
   # 查看更新的文件列表
   git diff --name-status HEAD..upstream/main
   ```

4. **分析更新类型**：
   - 功能更新
   - 修复更新
   - 文档更新
   - 配置更新

5. **识别可能冲突的文件**（重要）：
   ```bash
   # 检查哪些文件在基础平台和业务项目中都被修改了
   git diff --name-only HEAD..upstream/main | while read file; do
     if git diff --quiet HEAD -- "$file" 2>/dev/null; then
       # 文件在业务项目中没有修改，风险低
       echo "LOW:$file"
     else
       # 文件在业务项目中有修改，风险高
       echo "HIGH:$file"
     fi
   done
   ```

6. **分析关键文件变更**：
   - **基础设施文件**（如 `app/models/user.rb`、`app/controllers/application_controller.rb`）：
     - 检查基础平台的变更是否会影响业务项目的扩展
     - 识别可能被覆盖的业务扩展代码
   
   - **配置文件**（如 `config/routes.rb`、`config/application.rb`）：
     - 检查是否有路由冲突
     - 检查是否有配置冲突
   
   - **业务特定文件**（如 `app/models/concerns/*_extensions.rb`）：
     - 检查基础平台是否修改了业务扩展文件
     - 评估是否会被覆盖
   
   - **数据库迁移**（如 `db/migrate/*.rb`）：
     - 检查是否有新的迁移文件
     - 评估是否需要运行迁移
   
   - **测试文件**（如 `test/**/*_test.rb`）：
     - 检查测试文件的变更
     - 评估是否会影响业务项目的测试

7. **评估影响范围**：
   - **高风险文件**：业务项目和基础平台都修改的文件
   - **中风险文件**：基础平台修改了业务项目可能依赖的文件
   - **低风险文件**：新增文件或业务项目未修改的文件

8. **生成风险报告**：
   - 列出所有可能冲突的文件
   - 分析每个文件的风险等级
   - 给出处理建议

**输出**：
- 更新提交列表（最近 10 条）
- 更新统计信息（文件数量、行数）
- 更新文件列表摘要
- 更新类型分析
- **风险分析报告**：
  - 高风险文件列表（可能冲突）
  - 中风险文件列表（需要关注）
  - 低风险文件列表（安全）
  - 每个文件的风险说明和处理建议
- **影响评估**：
  - 可能影响的业务功能
  - 需要手动处理的文件
  - 建议的处理策略

### 步骤 5：显示风险报告并等待确认

**目标**：基于步骤 4 的风险分析，生成详细的风险报告，等待用户确认后再执行 rebase。

**重要规则**：

1. **必须等待确认**：执行 rebase 前必须等待用户明确确认
2. **显示详细风险报告**：显示更新摘要、风险分析和影响评估
3. **提供处理建议**：针对高风险文件给出处理建议

**执行流程**：

1. **生成并显示风险报告**：
   ```
   ⚠️ 同步基础平台更新 - 风险分析报告
   
   📊 更新摘要：
   - 更新提交数：15 个提交
   - 更新文件数：23 个文件
   - 新增行数：+450
   - 删除行数：-120
   
   📝 主要更新类型：
   - 功能更新：8 个提交
   - 修复更新：5 个提交
   - 文档更新：2 个提交
   
   ⚠️ 风险评估：
   
   🔴 高风险文件（可能冲突，需要手动处理）：
   1. app/models/user.rb
      - 风险：基础平台添加了新方法，你的项目修改了相同位置
      - 影响：可能覆盖你的业务扩展代码
      - 建议：rebase 后检查并合并你的扩展代码
   
   2. config/routes.rb
      - 风险：基础平台添加了新路由，你的项目也添加了路由
      - 影响：路由可能冲突
      - 建议：rebase 后手动合并路由配置
   
   🟡 中风险文件（需要关注）：
   1. app/controllers/application_controller.rb
      - 风险：基础平台修改了基础控制器
      - 影响：可能影响你的控制器继承
      - 建议：rebase 后检查控制器功能是否正常
   
   🟢 低风险文件（安全）：
   - .cursor/commands/changelog.md（新增）
   - CHANGELOG.md（新增）
   - docs/FEATURE_CONTRIBUTION.md（更新）
   
   💡 处理建议：
   1. 建议先备份当前代码（已完成，已保存到 wip/sync-upstream-{timestamp} 分支）
   2. 执行 rebase 后，优先处理高风险文件的冲突
   3. 运行测试确保功能正常：bin/rails test
   4. 如有问题，可以使用 git rebase --abort 回退
   
   ⚠️ 重要提示：
   - 如果 rebase 过程中出现冲突，需要手动解决
   - 解决冲突后，使用 git add <文件> 和 git rebase --continue 继续
   - 如果遇到无法解决的问题，可以使用 git rebase --abort 取消 rebase
   
   是否确认执行 rebase 同步这些更新？(yes/no)
   ```

2. **处理用户响应**：
   - **yes**：执行 rebase（进入步骤 6）
   - **no**：取消操作，提示用户可以稍后再试

**输出**：
- 详细的风险分析报告
- 更新摘要和统计
- 风险评估和处理建议
- 等待用户确认

### 步骤 6：执行 rebase

**目标**：用户确认后执行 rebase 操作。

**执行流程**：

1. **执行 rebase**（用户确认后）：
   ```bash
   # 使用 GIT_EDITOR=true 避免 vim 弹窗
   GIT_EDITOR=true git rebase upstream/main
   ```

2. **检查 rebase 结果**：
   ```bash
   # 检查 rebase 状态
   git status
   ```

**输出**：
- rebase 执行结果
- 如果有冲突，显示冲突信息（进入步骤 7）
- 如果成功，进入步骤 8

### 步骤 7：处理冲突（如有）

**目标**：如果 rebase 过程中出现冲突，协助用户处理。

**方法**：

1. **检测冲突**：
   ```bash
   git status
   ```
   - 查看冲突文件列表
   - 查看冲突状态

2. **显示冲突信息**：
   ```
   检测到冲突，需要手动解决：
   
   冲突文件：
   - app/models/user.rb
   - config/routes.rb
   
   冲突说明：
   - app/models/user.rb：基础平台添加了新方法，你的项目修改了相同位置
   - config/routes.rb：基础平台添加了新路由，你的项目也添加了路由
   
   请手动解决冲突后，使用以下命令继续：
   git add <解决冲突的文件>
   git rebase --continue
   
   或者取消 rebase：
   git rebase --abort
   ```

3. **等待用户解决冲突**：
   - 用户手动解决冲突
   - 用户标记冲突已解决（`git add`）
   - 用户继续 rebase（`git rebase --continue`）

4. **继续 rebase**（用户解决冲突后）：
   ```bash
   # 使用 GIT_EDITOR=true 继续 rebase
   GIT_EDITOR=true git rebase --continue
   ```

**输出**：
- 冲突文件列表
- 冲突说明和建议
- 继续或取消的选项

### 步骤 8：清理并切换回之前的工作

**目标**：rebase 完成后，清理并切换回之前的工作分支（如果之前自动创建了暂存分支）。

**方法**：

1. **记录之前的工作分支**：
   - 在步骤 1 中，如果分支不干净，自动创建了暂存分支（如 `wip/sync-upstream-20251203-213335`），记录该分支名称
   - 如果分支干净，记录当前分支名称（如 `main`）

2. **切换回之前的工作分支**（如果需要）：

```bash
# 如果之前的工作在 wip 分支（步骤 1 自动创建的）
git checkout wip/sync-upstream-{timestamp}

# 如果之前的工作在 main 分支或其他分支
git checkout {原分支名称}
```

3. **合并 rebase 后的更新**（如果需要）：
   - 如果之前的工作在 wip 分支，可以合并 main 分支的更新：
     ```bash
     git merge main
     ```
   - 或者继续在 main 分支工作（如果之前的工作已经不重要）

**输出**：
- 切换回之前的工作分支
- 提示可以继续业务开发

### 步骤 9：验证和总结

**目标**：验证 rebase 结果，显示同步总结。

**目标**：验证 rebase 结果，显示同步总结。

**方法**：

1. **检查最终状态**：
   ```bash
   git status
   git log --oneline -10
   ```

2. **显示同步总结**：
   ```
   ✅ Rebase 完成！
   
   同步结果：
   - 成功同步 15 个提交
   - 更新 23 个文件
   - 新增 450 行，删除 120 行
   
   当前状态：
   - 分支：main
   - 状态：干净（无冲突）
   - 领先 origin/main：15 个提交
   
   ⚠️ 重要提醒：
   - 如果之前自动创建了暂存分支（wip/sync-upstream-{timestamp}），记得切换回去或合并更新
   - 建议运行测试确保功能正常
   
   下一步：
   - 运行测试：bin/rails test
   - 检查代码：bin/rubocop
   - 推送更新：git push
   ```

**输出**：
- 同步结果摘要
- 当前 Git 状态
- 下一步建议

## ⚠️ 重要规则

1. **自动保存工作**：如果分支不干净，自动创建分支保存当前工作，不询问用户
2. **风险分析优先**：必须先进行深度风险分析，识别可能冲突的文件
3. **必须等待确认**：执行 rebase 前必须等待用户明确确认
4. **显示详细风险报告**：显示更新摘要、风险分析和影响评估
5. **使用 GIT_EDITOR=true**：避免 vim 弹窗，自动完成 rebase
6. **冲突处理**：检测冲突并提供处理建议
7. **可回退**：提供回退选项（`git rebase --abort`）
8. **信息透明**：显示更新摘要和风险分析，让用户充分了解变更和风险
9. **验证结果**：rebase 后验证结果并提供总结
10. **清理工作**：rebase 完成后，切换回之前的工作分支（如果自动创建了暂存分支）

## 🔧 技术细节

### Git 命令参考

```bash
# 检查 Git 状态
git status
git status --short

# 检查 remote 配置
git remote -v
git remote show upstream

# 添加 upstream remote
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git

# 获取 upstream 最新代码
git fetch upstream main

# 查看更新内容
git log HEAD..upstream/main --oneline
git diff --stat HEAD..upstream/main
git diff --name-status HEAD..upstream/main

# 自动保存当前工作到分支（如果分支不干净）
CURRENT_BRANCH=$(git branch --show-current)
git checkout -b wip/sync-upstream-$(date +%Y%m%d-%H%M%S)
git add .
git commit -m "WIP: 保存当前工作进度（同步 upstream 前自动暂存）"
git checkout $CURRENT_BRANCH  # 切换回原分支（现在干净了）

# 执行 rebase（使用 GIT_EDITOR=true 避免 vim 弹窗）
GIT_EDITOR=true git rebase upstream/main

# 处理冲突
git status                    # 查看冲突文件
git add <解决冲突的文件>      # 标记冲突已解决
GIT_EDITOR=true git rebase --continue  # 继续 rebase

# 取消 rebase
git rebase --abort

# 切换回之前的工作分支（如果自动创建了暂存分支）
git checkout wip/sync-upstream-{timestamp}

# 查看提交历史
git log --oneline -10
git log --oneline --graph
```

### 冲突处理策略

根据 `docs/SYNC_UPDATES.md` 的冲突处理策略：

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
   - **策略**：保留你的业务文档
   - **原因**：业务项目的文档应该保持独立

### 回退方法

如果 rebase 失败或需要回退：

```bash
# 取消 rebase，回到 rebase 前的状态
git rebase --abort

# 或者使用 reflog 查看历史
git reflog

# 回退到指定提交
git reset --hard <commit-hash>
```

## 💡 使用示例

### 示例 1：成功同步更新

```
用户：/sync-upstream

AI 执行：
1. 检查项目类型和 Git 状态：
   → 确认是 fork 项目
   → 工作区干净，无未提交更改
   → 当前分支：main

2. 检查 upstream remote 配置：
   → upstream 已配置：https://github.com/xiaohui-zhangxh/buildx.work.git

3. 获取 upstream 最新代码：
   → 获取成功，发现 15 个新提交

4. 深度分析更新内容和风险评估：
   → 更新提交数：15 个
   → 更新文件数：23 个
   → 主要更新类型：功能更新、修复更新、文档更新
   → 风险分析：
     - 高风险文件：2 个（app/models/user.rb, config/routes.rb）
     - 中风险文件：1 个（app/controllers/application_controller.rb）
     - 低风险文件：20 个

5. 显示详细风险报告并等待确认：
   → ⚠️ 同步基础平台更新 - 风险分析报告
   → 显示更新摘要、风险评估、处理建议
   → 是否确认执行 rebase？(yes/no)

用户：yes

AI 执行：
6. 执行 rebase：
   → GIT_EDITOR=true git rebase upstream/main
   → Rebase 成功！

7. 处理冲突（如有）：
   → 无冲突

8. 清理并切换回之前的工作：
   → 之前分支干净，无需切换

9. 验证和总结：
   → Rebase 完成！
   → 显示同步总结
```

### 示例 2：处理冲突

```
用户：/sync-upstream

AI 执行：
1. 检查项目类型和 Git 状态：
   → 确认是 fork 项目
   → 工作区不干净，有未提交更改
   → 自动创建暂存分支：wip/sync-upstream-20251203-213335
   → 当前分支：main（现在干净了）

2-3. （同上）

4. 深度分析更新内容和风险评估：
   → 风险分析：
     - 高风险文件：2 个（app/models/user.rb, config/routes.rb）
     - 中风险文件：1 个
     - 低风险文件：20 个

5. 显示详细风险报告并等待确认：
   → ⚠️ 同步基础平台更新 - 风险分析报告
   → 显示更新摘要、风险评估、处理建议
   → 是否确认执行 rebase？(yes/no)

用户：yes

AI 执行：
6. 执行 rebase：
   → GIT_EDITOR=true git rebase upstream/main
   → 检测到冲突！

7. 显示冲突信息：
   → 冲突文件：app/models/user.rb
   → 冲突说明：基础平台添加了新方法，你的项目修改了相同位置
   → 请手动解决冲突后继续

用户：（手动解决冲突）

用户：git add app/models/user.rb && git rebase --continue

AI 执行：
→ 继续 rebase：GIT_EDITOR=true git rebase --continue
→ Rebase 完成！

8. 清理并切换回之前的工作：
   → 切换回 wip/sync-upstream-20251203-213335 分支
   → 可以合并 main 分支的更新或继续在 main 分支工作

9. 验证和总结：
   → Rebase 完成！
   → 显示同步总结
```

## 📚 相关资源

- [同步基础平台更新指南](../docs/SYNC_UPDATES.md) - 详细的同步更新指南
- [代码贡献指令](80-contribute-code.md) - 如何贡献代码到基础平台
- [Git 提交助手](90-commit-assistant.md) - 协助提交代码

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-03  
**指令类型**：通用指令  
**适用项目**：fork 项目（业务项目）  
**相关文档**：`docs/SYNC_UPDATES.md`  
**优化说明**：
- 统一使用分支保存代码（`wip/sync-upstream-{timestamp}`），与代码贡献指令保持一致
- 增强风险分析，先分析更新内容和潜在影响，给出详细风险提示
- 必须等待用户确认后才执行 rebase，确保操作安全

