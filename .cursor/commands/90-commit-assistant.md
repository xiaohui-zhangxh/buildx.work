# Git 提交助手

> 识别 git changes 内容，判断是否需要拆分 commit，协助用户签入代码

## 📋 指令说明

此指令帮助用户识别当前 git 工作区的变更内容，分析是否需要拆分成多条 commit，并协助用户进行代码签入。**重要**：每次 commit 之前都需要人工确认。

### 使用方式

**Cursor 斜线命令**：`/commit-assistant`  
**直接描述**：`协助提交代码`、`检查 git changes`、`分析提交内容`、`拆分 commit`

## 🎯 核心原则

1. **全面分析**：全面分析所有 git changes，包括 staged 和 unstaged 的文件
2. **智能分组**：根据变更类型、功能模块、文件类型等智能分组
3. **建议拆分**：识别需要拆分的变更，提供拆分建议
4. **人工确认**：每次 commit 之前必须等待用户确认
5. **规范提交**：使用规范的提交信息格式

## 🔍 工作流程

### 步骤 1：检查 Git 状态

**目标**：获取当前 git 工作区的完整状态。

**方法**：

1. **检查 Git 状态**：
   ```bash
   git status
   ```
   - 查看 staged 文件（已暂存）
   - 查看 unstaged 文件（未暂存）
   - 查看 untracked 文件（未跟踪）

2. **检查 Git 差异**：
   ```bash
   # 查看 staged 文件的差异
   git diff --cached
   
   # 查看 unstaged 文件的差异
   git diff
   
   # 查看所有变更（包括 untracked）
   git status --short
   ```

3. **检查 Git 日志**（可选）：
   ```bash
   # 查看最近的提交历史
   git log --oneline -10
   ```
   - 了解最近的提交模式
   - 参考提交信息格式

**输出**：
- Git 状态摘要
- 变更文件列表（staged、unstaged、untracked）
- 变更统计信息

### 步骤 2：分析变更内容

**目标**：详细分析每个变更文件的内容，理解变更的目的和类型。

**方法**：

1. **读取变更文件内容**：
   - 对于修改的文件，读取文件内容
   - 对于新增的文件，读取完整内容
   - 对于删除的文件，标记为删除

2. **分析变更类型**：
   - **功能新增**：新增功能、新文件、新方法
   - **功能修改**：修改现有功能、改进实现
   - **Bug 修复**：修复错误、处理异常
   - **重构**：代码重构、优化结构
   - **文档更新**：更新文档、注释
   - **配置变更**：修改配置、环境变量
   - **测试相关**：新增测试、修改测试
   - **样式调整**：CSS、样式文件变更
   - **资源文件**：图片、字体等资源文件

3. **分析变更范围**：
   - **单文件变更**：只修改一个文件
   - **多文件变更**：修改多个相关文件
   - **跨模块变更**：涉及多个模块的变更
   - **全局变更**：影响全局的变更（如配置、路由）

4. **分析变更关联性**：
   - **功能关联**：属于同一功能的变更
   - **模块关联**：属于同一模块的变更
   - **类型关联**：属于同一类型的变更（如都是测试、都是文档）
   - **独立变更**：相互独立的变更

**输出**：
- 变更文件详细列表
- 每个文件的变更类型
- 变更内容摘要
- 变更关联性分析

### 步骤 3：判断是否需要拆分

**目标**：根据变更内容，判断是否需要拆分成多条 commit。

**判断标准**：

1. **功能独立性**：
   - ✅ **应该拆分**：多个独立功能的变更
   - ❌ **不需要拆分**：同一功能的多个文件变更

2. **变更类型**：
   - ✅ **应该拆分**：不同类型的变更（如功能 + 测试、功能 + 文档）
   - ❌ **不需要拆分**：同一类型的变更（如都是功能、都是测试）

3. **模块独立性**：
   - ✅ **应该拆分**：不同模块的变更
   - ❌ **不需要拆分**：同一模块的变更

4. **提交信息清晰度**：
   - ✅ **应该拆分**：无法用一条清晰的提交信息描述所有变更
   - ❌ **不需要拆分**：可以用一条清晰的提交信息描述所有变更

5. **变更规模**：
   - ✅ **应该拆分**：变更规模很大，包含多个不相关的修改
   - ❌ **不需要拆分**：变更规模适中，所有修改都相关

**拆分建议格式**：

```
建议拆分为 N 条 commit：

1. [提交类型] 提交信息
   - 文件列表
   - 变更说明

2. [提交类型] 提交信息
   - 文件列表
   - 变更说明

...
```

**输出**：
- 是否需要拆分的判断
- 拆分建议（如需要）
- 每条 commit 的文件列表和变更说明

### 步骤 4：生成提交建议

**目标**：为每条 commit 生成规范的提交信息建议。

**提交信息格式**（遵循 [Conventional Commits](https://www.conventionalcommits.org/)）：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**提交类型（type）**：

- **feat**：新功能
- **fix**：Bug 修复
- **docs**：文档更新
- **style**：代码格式（不影响代码运行的变动）
- **refactor**：重构（既不是新增功能，也不是修复 Bug）
- **perf**：性能优化
- **test**：测试相关
- **chore**：构建过程或辅助工具的变动
- **ci**：CI 配置变更
- **build**：构建系统变更

**提交信息生成规则**：

1. **主题行（subject）**：
   - 使用祈使句，首字母小写，结尾不加句号
   - 不超过 50 个字符
   - 清晰描述变更内容

2. **正文（body）**（可选）：
   - 详细说明变更的原因和方式
   - 可以包含多行
   - 每行不超过 72 个字符

3. **页脚（footer）**（可选）：
   - 关联 Issue：`Closes #123`
   - 破坏性变更：`BREAKING CHANGE: <description>`

**输出**：
- 每条 commit 的提交信息建议
- 提交信息格式说明
- 提交信息示例

### 步骤 5：等待用户确认并执行

**目标**：等待用户确认每条 commit，然后执行提交。

**重要规则**：

1. **必须等待确认**：每次 commit 之前必须等待用户明确确认
2. **显示详细信息**：显示即将提交的文件列表和提交信息
3. **允许修改**：允许用户修改提交信息
4. **允许跳过**：允许用户跳过某条 commit
5. **允许取消**：允许用户取消整个提交流程

**执行流程**：

1. **显示提交信息**：
   ```
   准备提交以下变更：
   
   提交信息：feat(auth): 添加用户登录功能
   
   变更文件：
   - app/controllers/sessions_controller.rb
   - app/views/sessions/new.html.erb
   - test/controllers/sessions_controller_test.rb
   
   变更说明：
   - 新增用户登录控制器
   - 新增登录页面视图
   - 新增登录功能测试
   
   是否确认提交？(yes/no/skip/edit)
   ```

2. **处理用户响应**：
   - **yes**：执行提交
   - **no**：取消提交
   - **skip**：跳过这条 commit，继续下一条
   - **edit**：允许用户编辑提交信息

3. **执行提交**（用户确认后）：
   ```bash
   # 如果文件未暂存，先暂存
   git add <文件列表>
   
   # 执行提交
   git commit -m "提交信息"
   ```

4. **显示提交结果**：
   ```
   提交成功！
   
   Commit: abc1234
   提交信息：feat(auth): 添加用户登录功能
   
   继续下一条 commit？(yes/no)
   ```

5. **继续或结束**：
   - 如果还有下一条 commit，重复步骤 1-4
   - 如果所有 commit 都完成，显示总结

**输出**：
- 提交确认提示
- 提交执行结果
- 提交总结

## 📝 拆分示例

### 示例 1：需要拆分的情况

**场景**：同时修改了功能代码、测试代码和文档。

**分析**：

```
变更文件：
- app/controllers/users_controller.rb (修改)
- app/models/user.rb (修改)
- test/controllers/users_controller_test.rb (修改)
- test/models/user_test.rb (修改)
- docs/USER_GUIDE.md (修改)
- README.md (修改)

变更内容：
- 新增用户管理功能（功能代码）
- 新增用户管理测试（测试代码）
- 更新用户指南文档（文档）
```

**拆分建议**：

```
建议拆分为 3 条 commit：

1. feat(users): 添加用户管理功能
   - app/controllers/users_controller.rb
   - app/models/user.rb
   - 变更说明：新增用户 CRUD 功能

2. test(users): 添加用户管理测试
   - test/controllers/users_controller_test.rb
   - test/models/user_test.rb
   - 变更说明：新增用户功能测试用例

3. docs(users): 更新用户指南文档
   - docs/USER_GUIDE.md
   - README.md
   - 变更说明：更新用户管理功能文档
```

### 示例 2：不需要拆分的情况

**场景**：修改了同一功能的多个相关文件。

**分析**：

```
变更文件：
- app/controllers/sessions_controller.rb (修改)
- app/views/sessions/new.html.erb (修改)
- app/views/sessions/create.html.erb (修改)
- config/routes.rb (修改)

变更内容：
- 改进用户登录功能（所有文件都是登录功能相关）
```

**拆分建议**：

```
不需要拆分，可以合并为一条 commit：

feat(auth): 改进用户登录功能
- app/controllers/sessions_controller.rb
- app/views/sessions/new.html.erb
- app/views/sessions/create.html.erb
- config/routes.rb
- 变更说明：优化登录流程，改进用户体验
```

## 💡 使用示例

### 示例 1：分析并拆分提交

```
用户：/commit-assistant

AI 执行：
1. 检查 Git 状态：
   git status
   → 发现 8 个修改的文件，2 个新增的文件

2. 分析变更内容：
   - 功能代码：app/controllers/users_controller.rb
   - 测试代码：test/controllers/users_controller_test.rb
   - 文档：docs/USER_GUIDE.md
   - 配置：config/routes.rb

3. 判断是否需要拆分：
   → 建议拆分为 3 条 commit：
     1. feat(users): 添加用户管理功能
     2. test(users): 添加用户管理测试
     3. docs(users): 更新用户指南文档

4. 生成提交建议：
   → 为每条 commit 生成提交信息

5. 等待用户确认：
   → 显示第一条 commit 的详细信息
   → 等待用户确认

用户：yes

AI 执行：
→ 执行提交：git commit -m "feat(users): 添加用户管理功能"
→ 提交成功！
→ 继续下一条 commit？
```

### 示例 2：直接提交（不需要拆分）

```
用户：/commit-assistant

AI 执行：
1. 检查 Git 状态：
   git status
   → 发现 3 个修改的文件

2. 分析变更内容：
   - 都是修复 Bug 相关：修复登录验证问题

3. 判断是否需要拆分：
   → 不需要拆分，可以合并为一条 commit

4. 生成提交建议：
   fix(auth): 修复登录验证问题
   - app/controllers/sessions_controller.rb
   - app/models/user.rb
   - test/controllers/sessions_controller_test.rb

5. 等待用户确认：
   → 显示提交信息
   → 等待用户确认

用户：yes

AI 执行：
→ 执行提交：git commit -m "fix(auth): 修复登录验证问题"
→ 提交成功！
```

## ⚠️ 重要规则

1. **必须等待确认**：每次 commit 之前必须等待用户明确确认，不能自动提交
2. **显示详细信息**：显示即将提交的文件列表、提交信息和变更说明
3. **允许修改**：允许用户修改提交信息
4. **允许跳过**：允许用户跳过某条 commit
5. **允许取消**：允许用户取消整个提交流程
6. **规范提交**：使用规范的提交信息格式（Conventional Commits）
7. **智能分组**：根据变更类型、功能模块、文件类型等智能分组
8. **清晰建议**：提供清晰的拆分建议和提交信息建议

## 🔧 技术细节

### Git 命令参考

```bash
# 检查 Git 状态
git status
git status --short

# 查看差异
git diff                    # unstaged 文件差异
git diff --cached           # staged 文件差异
git diff HEAD               # 所有变更差异

# 暂存文件
git add <文件路径>          # 暂存单个文件
git add <目录路径>          # 暂存整个目录
git add -p                  # 交互式暂存

# 提交
git commit -m "提交信息"    # 使用 -m 参数提交
git commit                  # 打开编辑器编辑提交信息

# 查看提交历史
git log --oneline -10       # 查看最近 10 条提交
git log --oneline --graph   # 图形化显示提交历史
```

### 文件分析

使用 `read_file` 工具读取文件内容，然后：
1. 分析代码变更
2. 识别变更类型
3. 评估变更关联性
4. 提供拆分建议

### 提交信息生成

根据变更内容自动生成提交信息：
1. 识别变更类型（feat/fix/docs/等）
2. 识别变更范围（scope）
3. 生成主题行（subject）
4. 生成正文（body，如需要）

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-02  
**指令类型**：通用指令  
**适用项目**：所有项目  
**相关文档**：无

