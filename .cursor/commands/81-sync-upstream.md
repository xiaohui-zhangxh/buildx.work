# 同步基础平台更新

## 概述

将基础平台（buildx.work）的更新同步到业务项目（fork 项目），使用 rebase 方式保持提交历史的线性。适用于 fork 项目，用于同步基础平台的更新。

### 使用方式

**Cursor 斜线命令**：`/sync-upstream`  
**直接描述**：`同步基础平台更新`、`rebase upstream main`、`合并基础平台代码`、`同步上游代码`

## 🎯 核心原则

1. **安全检查**：在执行 rebase 前检查工作区状态，确保没有未提交的更改
2. **信息透明**：显示将要同步的更新内容，让用户了解变更
3. **自动处理**：使用 `GIT_EDITOR=true` 避免 vim 弹窗，自动完成 rebase
4. **冲突处理**：检测并协助处理 rebase 过程中的冲突
5. **可回退**：提供回退选项，确保操作安全

## 🔍 工作流程

### 步骤 1：检查项目类型和 Git 状态

**目标**：确认当前项目是 fork 项目，并检查 Git 状态。

**方法**：

1. **检查项目类型**：
   - 检查是否存在 `docs/project-*/` 目录
   - 检查 Git Remote 配置
   - 如果是 buildx.work 项目，提示用户此指令适用于 fork 项目

2. **检查 Git 状态**：
   ```bash
   git status
   ```
   - 如果有未提交的更改，提示用户先提交或暂存
   - 如果有未跟踪的文件，不影响 rebase，但会提示用户

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

### 步骤 4：分析更新内容

**目标**：分析基础平台的更新内容，让用户了解将要同步的变更。

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

**输出**：
- 更新提交列表（最近 10 条）
- 更新统计信息（文件数量、行数）
- 更新文件列表摘要
- 更新类型分析

### 步骤 5：确认并执行 rebase

**目标**：等待用户确认后执行 rebase 操作。

**重要规则**：

1. **必须等待确认**：执行 rebase 前必须等待用户明确确认
2. **显示详细信息**：显示将要同步的更新摘要
3. **使用 GIT_EDITOR=true**：避免 vim 弹窗，自动完成 rebase
4. **提供回退选项**：如果 rebase 失败，提供回退方法

**执行流程**：

1. **显示更新摘要**：
   ```
   准备同步以下更新：
   
   更新提交数：15 个提交
   更新文件数：23 个文件
   新增行数：+450
   删除行数：-120
   
   主要更新类型：
   - 功能更新：8 个提交
   - 修复更新：5 个提交
   - 文档更新：2 个提交
   
   是否确认执行 rebase？(yes/no)
   ```

2. **处理用户响应**：
   - **yes**：执行 rebase
   - **no**：取消操作

3. **执行 rebase**（用户确认后）：
   ```bash
   # 使用 GIT_EDITOR=true 避免 vim 弹窗
   GIT_EDITOR=true git rebase upstream/main
   ```

4. **检查 rebase 结果**：
   ```bash
   # 检查 rebase 状态
   git status
   ```

**输出**：
- 更新摘要
- rebase 执行结果
- 如果有冲突，显示冲突信息

### 步骤 6：处理冲突（如有）

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

### 步骤 7：验证和总结

**目标**：验证 rebase 结果，显示同步总结。

**方法**：

1. **检查最终状态**：
   ```bash
   git status
   git log --oneline -10
   ```

2. **显示同步总结**：
   ```
   Rebase 完成！
   
   同步结果：
   - 成功同步 15 个提交
   - 更新 23 个文件
   - 新增 450 行，删除 120 行
   
   当前状态：
   - 分支：main
   - 状态：干净（无冲突）
   - 领先 origin/main：15 个提交
   
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

1. **必须等待确认**：执行 rebase 前必须等待用户明确确认
2. **安全检查**：确保工作区干净，没有未提交的更改
3. **使用 GIT_EDITOR=true**：避免 vim 弹窗，自动完成 rebase
4. **冲突处理**：检测冲突并提供处理建议
5. **可回退**：提供回退选项（`git rebase --abort`）
6. **信息透明**：显示更新摘要，让用户了解变更
7. **验证结果**：rebase 后验证结果并提供总结

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

# 执行 rebase（使用 GIT_EDITOR=true 避免 vim 弹窗）
GIT_EDITOR=true git rebase upstream/main

# 处理冲突
git status                    # 查看冲突文件
git add <解决冲突的文件>      # 标记冲突已解决
GIT_EDITOR=true git rebase --continue  # 继续 rebase

# 取消 rebase
git rebase --abort

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

4. 分析更新内容：
   → 更新提交数：15 个
   → 更新文件数：23 个
   → 主要更新类型：功能更新、修复更新、文档更新

5. 显示更新摘要并等待确认：
   → 准备同步以下更新...
   → 是否确认执行 rebase？(yes/no)

用户：yes

AI 执行：
→ 执行 rebase：GIT_EDITOR=true git rebase upstream/main
→ Rebase 成功！
→ 显示同步总结
```

### 示例 2：处理冲突

```
用户：/sync-upstream

AI 执行：
1-4. （同上）

5. 执行 rebase：
   → GIT_EDITOR=true git rebase upstream/main
   → 检测到冲突！

6. 显示冲突信息：
   → 冲突文件：app/models/user.rb
   → 冲突说明：基础平台添加了新方法，你的项目修改了相同位置
   → 请手动解决冲突后继续

用户：（手动解决冲突）

用户：git add app/models/user.rb && git rebase --continue

AI 执行：
→ 继续 rebase：GIT_EDITOR=true git rebase --continue
→ Rebase 完成！
→ 显示同步总结
```

## 📚 相关资源

- [同步基础平台更新指南](../docs/SYNC_UPDATES.md) - 详细的同步更新指南
- [代码贡献指令](80-contribute-code.md) - 如何贡献代码到基础平台
- [Git 提交助手](90-commit-assistant.md) - 协助提交代码

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-02  
**指令类型**：通用指令  
**适用项目**：fork 项目（业务项目）  
**相关文档**：`docs/SYNC_UPDATES.md`

