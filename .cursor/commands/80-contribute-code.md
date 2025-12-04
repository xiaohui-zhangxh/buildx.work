# 代码贡献指令

## 概述

自动识别当前项目中可以贡献给 BuildX.work 基础平台的代码，并协助智能合并到贡献分支，准备通过 GitHub Pull Request 提交。适用于 fork 项目（业务项目），用于识别和贡献通用功能到基础平台。

### 使用方式

**Cursor 斜线命令**：`/contribute-code`  
**直接描述**：`找出可以贡献的代码`、`检查是否有可以贡献的代码`、`贡献代码到基础平台`

## 🎯 核心原则

1. **自动化流程**：AI 应该自动执行所有步骤，减少用户手动操作
2. **自动处理分支状态**：如果分支不干净，自动暂存到独立分支，不询问用户
3. **严格检查**：必须满足所有前置条件才能继续（upstream remote 必须正确）
4. **智能识别**：智能识别可贡献代码，区分基础功能和业务功能
5. **智能合并**：智能合并代码到贡献分支，处理位置差异
6. **用户确认**：关键步骤需要用户确认，确保贡献的代码正确

## 🔍 工作流程

### 步骤 1：检查 Upstream Remote（必须）

**目标**：确保 upstream remote 存在且指向正确的 buildx.work GitHub 仓库。

**方法**：

```bash
# 检查 Git Remote 配置
git remote -v
```

**检查规则**：

1. **必须存在 `upstream` remote**：
   - 如果不存在，提示用户添加：
     ```bash
     git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
     ```
   - **如果不存在，停止执行，不继续工作**

2. **upstream 必须指向 buildx.work GitHub 仓库**：
   - 正确的 URL：`https://github.com/xiaohui-zhangxh/buildx.work.git` 或 `git@github.com:xiaohui-zhangxh/buildx.work.git`
   - 如果指向错误，提示用户修正：
     ```bash
     git remote set-url upstream https://github.com/xiaohui-zhangxh/buildx.work.git
     ```
   - **如果指向错误，停止执行，不继续工作**

**输出**：
- upstream remote 状态（存在/不存在，URL 是否正确）
- 如果不符合要求，提示用户如何配置

**注意**：这是**必须步骤**，如果 upstream 不存在或指向错误，**必须停止执行**，提示用户配置后再继续。

### 步骤 2：拉取 Upstream 最新代码

**目标**：确保本地有最新的基础平台代码用于对比。

**方法**：

```bash
# 获取基础平台 main 分支的最新代码
git fetch upstream main
```

**输出**：
- 拉取结果（成功/失败）
- 如果失败，提示用户检查网络连接或权限

### 步骤 3：检查当前分支状态并自动处理（必须）

**目标**：确保当前分支是干净的，没有未提交的变更。如果分支不干净，自动暂存到独立分支。

**方法**：

```bash
# 检查当前分支状态
git status --short
```

**检查规则**：

1. **如果当前分支不干净**（有未提交的变更）：
   - **自动使用方式 2（暂存到独立分支）**，不询问用户：
     ```bash
     # 记录当前分支名称
     CURRENT_BRANCH=$(git branch --show-current)
     
    # 创建临时分支保存当前工作（包含操作类型和时间戳，便于识别）
    git checkout -b wip/contribute-code-$(date +%Y%m%d-%H%M%S)
    git add .
    git commit -m "WIP: 保存当前工作进度（贡献代码前自动暂存）"
     
     # 切换回原分支（此时原分支应该是干净的）
     git checkout $CURRENT_BRANCH
     ```
   - **记录暂存分支名称**，用于步骤 8 切换回去
   - **继续执行下一步**（不再停止）

2. **如果当前分支干净**：
   - 继续执行下一步

**输出**：
- 当前分支状态（干净/不干净）
- 如果有未提交的变更：
  - 列出变更文件
  - 自动创建暂存分支
  - 显示暂存分支名称
  - 提示已自动处理，继续执行

**注意**：
- 这是**必须步骤**，如果当前分支不干净，**自动使用方式 2 暂存到独立分支**，然后继续执行
- 暂存分支命名格式：`wip/contribute-code-{timestamp}`，包含操作类型（contribute-code）和时间戳，便于识别和恢复
- 暂存分支会在步骤 8 中用于切换回之前的工作

### 步骤 4：对比代码差异并识别可贡献代码

**目标**：对比当前分支和 upstream/main 的代码差异，识别可以贡献给基础平台的代码。

**方法**：

1. **对比文件差异**：

```bash
# 对比当前分支和基础平台 main 分支的所有文件差异
git diff upstream/main --name-status

# 对比特定目录的文件差异（基础功能相关目录）
git diff upstream/main --name-status -- app/helpers/
git diff upstream/main --name-status -- lib/
git diff upstream/main --name-status -- app/views/shared/
git diff upstream/main --name-status -- app/controllers/concerns/
git diff upstream/main --name-status -- app/models/concerns/
git diff upstream/main --name-status -- config/initializers/
git diff upstream/main --name-status -- test/test_helpers/
git diff upstream/main --name-status -- .cursor/rules/
git diff upstream/main --name-status -- .cursor/commands/
git diff upstream/main --name-status -- docs/ -- ':!docs/project-*/**'
```

2. **分析文件变更类型**：
   - **新增文件（A）**：业务项目新增的文件，可能是通用功能
   - **修改文件（M）**：业务项目修改的文件，可能是改进或修复
   - **删除文件（D）**：业务项目删除的文件（通常不需要贡献）

3. **读取并分析每个变更文件**（重要：分析部分代码，不只是整个文件）：
   - 对于新增文件：读取文件内容，分析是否包含业务特定逻辑，识别可以贡献的部分代码
   - 对于修改文件：对比基础平台版本和业务项目版本，分析具体变更（新增方法、修改方法、删除方法等），识别可以贡献的部分代码
   - 对于删除文件：通常不需要贡献（除非是清理无用代码）

4. **识别可贡献的代码**（支持部分代码贡献）：

   **重要原则**：
   - **不一定要贡献整个文件**：一个文件中的部分代码也可以贡献
   - **代码的贡献位置不一定一样**：可能最优解是贡献到另外一个地方
   - **分析代码的最佳贡献位置**：考虑代码的功能、依赖关系、项目结构等因素

   **识别粒度**：
   - **整个文件**：如果文件完全通用，可以贡献整个文件
   - **部分代码**：如果文件中只有部分代码通用，只贡献这部分代码
     - 新增的方法
     - 修改的方法
     - 新增的类或模块
     - 修改的配置项
     - 新增的测试用例

   **可贡献的代码类型**：
   - **新增的通用功能**：新增的文件或方法，且不包含业务特定逻辑
   - **改进的基础功能**：修改的文件或方法，改进了基础平台的功能
   - **修复的 Bug**：修改的文件或方法，修复了基础平台的 Bug
   - **通用文档和规则**：`.cursor/rules/`、`.cursor/commands/`、`docs/`（排除 `docs/project-*/`）
   - **业务特定功能**：新增或修改的文件或方法，但包含业务特定逻辑（需要通用化或排除）

5. **分析代码的最佳贡献位置**（重要）：

   **分析因素**：
   - **代码功能**：代码的功能是什么？应该放在哪里？
   - **依赖关系**：代码依赖哪些类、方法、模块？这些依赖在哪里？
   - **项目结构**：基础平台的项目结构是什么？代码应该放在哪个目录？
   - **代码组织**：代码是否应该放在新文件、现有文件、还是新的模块中？

   **贡献位置策略**：
   - **相同位置**：如果代码在业务项目中的位置合理，可以贡献到相同位置
   - **不同位置**：如果代码在业务项目中的位置不合理，应该贡献到更合适的位置
     - 例如：业务项目中的 `app/models/concerns/user_extensions.rb` 中的方法，可能应该贡献到基础平台的 `app/models/user.rb`
     - 例如：业务项目中的 `app/helpers/application_helper.rb` 中的方法，可能应该贡献到基础平台的 `app/helpers/application_helper.rb` 或新的 Helper 模块
   - **新建文件**：如果代码适合独立存在，可以创建新文件
   - **合并到现有文件**：如果代码适合合并到现有文件，应该合并

6. **判断通用性**（针对部分代码，不只是整个文件）：
   - **检查业务特定逻辑**：
     - 是否包含业务特定的模型引用（如 `Card`、`Deck` 等）？
     - 是否包含业务特定的配置？
     - 是否包含业务特定的常量？
   - **检查文件路径**：
     - 是否在 `docs/project-*/` 目录下？（业务文档，不贡献）
     - 是否在业务特定目录下？（如 `app/models/card.rb`，不贡献）
   - **检查依赖关系**：
     - 依赖哪些业务模型？
     - 依赖哪些业务配置？
     - 依赖哪些业务 Helper？

**输出**：
- 文件变更列表（新增、修改、删除）
- 每个变更文件的详细分析
- **可贡献代码列表（支持部分代码）**：
  - 整个文件（如果整个文件可以贡献）
  - 部分代码（如果只有部分代码可以贡献）
    - 文件路径和行号范围
    - 代码片段
    - 代码功能
- **每个可贡献代码的详细信息**：
  - 代码位置（原文件路径和行号范围）
  - 建议贡献位置（目标文件路径和位置）
  - 变更类型（新增/修改/删除）
  - 变更内容（如果是修改，说明具体修改了什么）
  - 代码功能
  - 通用性评估
  - 贡献价值
  - 贡献位置分析（为什么贡献到这个位置）

### 步骤 5：生成贡献建议并等待用户确认

**目标**：生成详细的贡献建议报告，等待用户确认是否贡献这些代码。

**方法**：

1. **创建贡献建议报告**：
   - 可以直接贡献的代码列表
   - 需要通用化的代码列表（说明如何通用化）
   - 不适合贡献的代码列表（说明原因）

2. **为每个可贡献代码提供详细信息**（支持部分代码）：
   - **原代码位置**：文件路径和行号范围（如果是部分代码，标注具体的行号范围）
   - **建议贡献位置**：目标文件路径和位置（可能不是原文件位置）
   - **贡献类型**：
     - 整个文件（如果整个文件可以贡献）
     - 部分代码（如果只有部分代码可以贡献）
       - 新增的方法（方法名和行号范围）
       - 修改的方法（方法名和行号范围）
       - 新增的类或模块（类名和行号范围）
       - 配置项（配置项名称和行号范围）
   - **变更类型**：新增（A）/ 修改（M）/ 删除（D）
   - **变更内容**：如果是修改，说明具体修改了什么
   - **代码功能**：功能描述
   - **通用性评估**：为什么可以贡献
   - **贡献价值**：贡献后对基础平台的价值
   - **贡献位置分析**：为什么贡献到这个位置（如果位置不同，说明原因）

3. **保存贡献建议到临时文件**：
   - 保存到 `tmp/contribution-report-{timestamp}.md`
   - 包含所有可贡献代码的详细信息

**输出**：
- 贡献建议报告（Markdown 格式）
- 保存到临时文件
- 显示给用户，等待确认

**用户确认选项**：
- ✅ **确认贡献**：继续执行步骤 6，创建贡献分支并合并代码
- ❌ **取消贡献**：停止执行，不创建贡献分支
- 🔄 **修改选择**：用户可以选择只贡献部分代码

### 步骤 6：创建贡献分支并智能合并代码

**目标**：如果用户确认贡献，创建基于 upstream/main 的贡献分支，并智能合并可贡献的代码。

**方法**：

1. **创建贡献分支**：

```bash
# 确保当前分支是最新的（基于 upstream/main）
git fetch upstream main
git checkout -b contribute/feature-description upstream/main
```

**分支命名规范**：
- 功能：`contribute/add-feature-name` 或 `contribute/improve-feature-name`
- 修复：`contribute/fix-issue-description`
- 文档：`contribute/docs-update-description`

2. **智能合并代码**（支持部分代码贡献和位置优化）：

对于每个可贡献的代码（可能是整个文件，也可能是部分代码）：

- **整个文件贡献**：
  - 如果文件在基础平台中不存在，直接复制文件
  - 如果文件在基础平台中存在但内容不同，智能合并（AI 理解差异并合并）

- **部分代码贡献**（重要）：
  - 读取业务项目文件中的特定代码片段（根据步骤 4 识别的行号范围）
  - 读取基础平台的目标文件（如果存在）
  - 分析代码的最佳贡献位置（可能不是原文件位置）
  - 智能合并代码片段到目标位置：
    - 如果是新增方法，添加到目标文件的合适位置
    - 如果是修改方法，更新目标文件中的对应方法
    - 如果是新增类或模块，创建新文件或添加到现有文件
    - 如果是配置项，添加到配置文件

- **删除文件**：
  - 通常不需要贡献（除非是清理无用代码）

**智能合并策略**：

1. **位置相同的情况**：
   - 如果代码在业务项目中的位置合理，贡献到相同位置
   - 直接对比内容差异，合并新增的方法、修改的方法等

2. **位置不同的情况**（重要）：
   - 如果代码在业务项目中的位置不合理，应该贡献到更合适的位置
   - AI 需要分析代码的功能、依赖关系、项目结构，决定最佳贡献位置
   - 例如：业务项目中的 `app/models/concerns/user_extensions.rb` 中的方法，可能应该贡献到基础平台的 `app/models/user.rb`
   - 例如：业务项目中的 `app/helpers/application_helper.rb` 中的方法，可能应该贡献到基础平台的 `app/helpers/application_helper.rb` 或新的 Helper 模块
   - 例如：业务项目中的 `config/initializers/100_system_config.rb` 中的部分配置逻辑，可能应该贡献到基础平台的 `config/initializers/100_system_config.rb` 或新的配置文件

3. **部分代码合并**（重要）：
   - 如果只有部分代码可以贡献，只合并这部分代码
   - 提取代码片段，分析其依赖关系
   - 将代码片段合并到目标文件的合适位置
   - 确保代码的上下文和依赖关系正确

4. **代码冲突处理**：
   - 如果合并时出现冲突，AI 需要智能解决冲突
   - 保留基础平台的代码结构，只合并业务项目的改进

5. **通用化处理**：
   - 如果代码包含业务特定逻辑，在合并时进行通用化处理
   - 参数化业务特定值
   - 抽象业务特定逻辑

**执行过程**：

```bash
# 对于每个可贡献的代码（可能是整个文件，也可能是部分代码），执行合并操作
# AI 需要智能理解如何合并，可能不是一比一相同位置的合并

# 示例 1：合并整个文件
# 1. 读取业务项目文件
# 2. 读取基础平台文件（如果存在）
# 3. 智能合并（添加新方法、修改现有方法等）
# 4. 保存到贡献分支

# 示例 2：合并部分代码（新增方法）
# 1. 读取业务项目文件中的特定方法（根据行号范围）
# 2. 分析方法的最佳贡献位置（可能不是原文件位置）
# 3. 读取基础平台的目标文件（如果存在）
# 4. 将方法添加到目标文件的合适位置
# 5. 保存到贡献分支

# 示例 3：合并部分代码（修改方法）
# 1. 读取业务项目文件中的修改后的方法
# 2. 读取基础平台文件中的原方法
# 3. 智能合并方法的变更
# 4. 保存到贡献分支

# 示例 4：合并部分代码到不同位置
# 1. 读取业务项目文件中的代码片段
# 2. 分析代码的功能和依赖关系
# 3. 决定最佳贡献位置（可能不是原文件位置）
# 4. 读取基础平台的目标文件（如果不存在，创建新文件）
# 5. 将代码片段合并到目标位置
# 6. 保存到贡献分支
```

3. **深度分析代码依赖和影响**（重要）：

在合并代码后，必须深入分析代码的依赖关系和潜在影响：

- **分析每个文件的依赖关系**：
  - 检查新增或修改的文件引用了哪些类、方法、模块
  - 检查这些依赖是否在基础平台中存在
  - 检查是否有缺失的方法、类或模块需要添加
  - 检查是否有循环依赖或不当依赖

- **分析代码变更的影响范围**：
  - 检查修改的文件是否会影响其他文件
  - 检查是否有其他文件依赖被修改的文件
  - 检查是否有测试文件需要更新
  - 检查是否有文档需要更新

- **识别缺失的依赖**：
  - 如果代码引用了不存在的方法，必须识别并添加
  - 如果代码引用了不存在的类，必须识别并添加
  - 如果代码引用了不存在的模块，必须识别并添加

**示例分析过程**：

```ruby
# 如果贡献的代码使用了 SystemConfig.ensure_config
# 必须检查 SystemConfig 模型是否有 ensure_config 方法
# 如果没有，必须添加该方法，否则代码无法运行
```

**输出**：
- 依赖关系分析报告
- 缺失依赖列表（如果有）
- 影响范围分析
- 需要添加的代码列表（如果有）

4. **提交合并结果**：

```bash
# 添加所有合并的文件
git add .

# 提交（使用规范的提交信息）
git commit -m "Add: feature description

Description of what was added and why it's useful for all projects.

Changes:
- File 1: description
- File 2: description

Closes #123"  # 如果有相关 Issue
```

**输出**：
- 贡献分支创建结果
- 每个文件的合并结果（成功/失败/需要手动处理）
- 合并后的代码变更摘要
- 依赖分析结果
- 如果有冲突或问题，提示用户

### 步骤 6.5：测试贡献分支代码（必须）

**目标**：在贡献分支上运行测试，确保代码可以正常运行，没有缺失的依赖。

**重要规则**：

1. **必须测试**：在创建贡献分支后，必须运行测试，确保代码可以正常运行
2. **必须修复问题**：如果测试失败或代码无法运行，必须修复问题后再继续
3. **不能跳过**：不能跳过测试步骤，即使看起来代码很简单

**方法**：

1. **安装依赖**：

```bash
# 确保所有依赖都已安装
bundle install
```

2. **运行测试**：

```bash
# 运行所有测试
bin/rails test

# 如果测试失败，必须分析失败原因并修复
```

3. **检查代码质量**：

```bash
# 运行 RuboCop 检查
bin/rubocop

# 如果有问题，必须修复
```

4. **验证代码可以加载**：

```bash
# 尝试加载 Rails 环境，检查是否有语法错误或缺失的依赖
bin/rails runner "puts 'Environment loaded successfully'"
```

5. **分析测试失败原因**（如果测试失败）：

- **缺失的方法或类**：
  - 检查错误信息，识别缺失的方法或类
  - 检查依赖分析步骤是否遗漏了某些依赖
  - 添加缺失的方法或类

- **语法错误**：
  - 检查代码语法是否正确
  - 修复语法错误

- **依赖问题**：
  - 检查 Gemfile 是否缺少依赖
  - 添加缺失的依赖

**输出**：
- 测试结果（通过/失败）
- 代码质量检查结果
- 环境加载结果
- 如果有问题：
  - 错误信息
  - 问题分析
  - 修复建议
  - 修复后的验证结果

**注意**：
- 这是**必须步骤**，不能跳过
- 如果测试失败，必须修复问题后再继续
- 如果发现缺失的依赖，必须回到步骤 6 添加依赖

### 步骤 7：生成 PR 提交指南

**目标**：生成详细的 GitHub Pull Request 提交指南，告诉用户如何提交贡献。

**方法**：

1. **检查贡献分支状态**：

```bash
# 检查贡献分支的提交
git log upstream/main..HEAD --oneline

# 检查贡献分支的变更
git diff upstream/main --stat
```

2. **生成 PR 提交指南**：

包含以下内容：

- **贡献分支信息**：
  - 分支名称
  - 基于哪个分支（upstream/main）
  - 包含哪些变更

- **推送分支到 GitHub**：

```bash
# 如果用户还没有 Fork buildx.work 仓库，提示先 Fork
# 然后在用户的 Fork 中推送贡献分支

# 方式 1：如果用户的 origin 指向自己的 Fork
git push origin contribute/feature-description

# 方式 2：如果用户的 origin 指向业务项目，需要添加 buildx.work Fork 的 remote
git remote add buildx-work-fork https://github.com/your-username/buildx.work.git
git push buildx-work-fork contribute/feature-description
```

- **创建 Pull Request**：
  - 访问 GitHub：https://github.com/xiaohui-zhangxh/buildx.work
  - 点击 "New Pull Request"
  - 选择分支：base: `main` ← compare: `contribute/feature-description`
  - 填写 PR 描述（使用模板）

- **PR 描述模板**：

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

- **代码审查流程**：
  - 等待审查
  - 响应审查意见
  - 同步上游更新
  - PR 合并后的清理工作

**输出**：
- PR 提交指南（Markdown 格式）
- 保存到临时文件：`tmp/pr-guide-{timestamp}.md`
- 显示给用户

### 步骤 8：清理贡献分支，回到之前的工作

**目标**：贡献完成后，清理贡献分支，切换回之前的工作分支，继续业务开发。

**背景**：
- 贡献代码后，基础平台需要时间审查，可能合并也可能拒绝
- 贡献分支已经完成使命（代码已提交或推送到远程）
- 应该回到之前的工作分支，继续业务开发

**方法**：

1. **记录之前的工作分支**：
   - 在步骤 3 中，如果分支不干净，自动创建了暂存分支（如 `wip/contribute-code-20251203-213335`），记录该分支名称
   - 如果分支干净，记录当前分支名称（如 `main`）

2. **切换回之前的工作分支**：

```bash
# 如果之前的工作在 wip 分支（步骤 3 自动创建的）
git checkout wip/contribute-code-{timestamp}

# 如果之前的工作在 main 分支或其他分支
git checkout {原分支名称}
```

3. **删除贡献分支**（可选，但推荐）：

```bash
# 删除本地贡献分支
git branch -d contribute/feature-description

# 如果分支未完全合并，使用强制删除
git branch -D contribute/feature-description
```

**注意**：
- 如果贡献分支已推送到远程，可以选择保留或删除
- 如果后续需要根据审查意见修改，可以保留贡献分支
- 如果贡献已完成（已合并或已拒绝），可以删除贡献分支

**输出**：
- 当前分支信息（已切换回之前的工作分支）
- 贡献分支删除结果（如果删除）
- 提示用户可以继续业务开发

**重要**：
- 贡献完成后，应该立即清理贡献分支，回到之前的工作
- 不要长时间停留在贡献分支上，影响业务开发
- 如果后续需要修改贡献，可以重新创建贡献分支

## 📝 识别规则

### ✅ 应该贡献的代码特征

**重要**：不一定要贡献整个文件，一个文件中的部分代码也可以贡献。必须分析代码的最佳贡献位置（可能不是原文件位置）。

1. **通用工具类和 Helper 方法**（可以是整个文件，也可以是部分方法）：
   - 不依赖业务逻辑
   - 可以在多个场景下使用
   - 提供通用的功能
   - **部分代码示例**：`app/helpers/application_helper.rb` 中的某个通用方法

2. **通用组件和 Partial**（可以是整个文件，也可以是部分组件）：
   - 不包含业务特定内容
   - 可以通过参数配置
   - 可以在多个页面复用
   - **部分代码示例**：视图文件中的某个通用 partial

3. **通用控制器功能**（可以是整个文件，也可以是部分方法）：
   - 提供通用的 CRUD 操作
   - 不依赖业务模型
   - 可以通过配置或继承使用
   - **部分代码示例**：控制器中的某个通用方法

4. **通用模型功能（Concern/Module）**（可以是整个文件，也可以是部分方法）：
   - 提供通用的模型行为
   - 不依赖业务特定逻辑
   - 可以通过 include 使用
   - **部分代码示例**：模型中的某个通用方法，可能应该贡献到 Concern 或基础模型

5. **通用配置和初始化**（可以是整个文件，也可以是部分配置）：
   - 提供通用的配置选项
   - 不依赖业务特定设置
   - 可以通过环境变量或配置文件使用
   - **部分代码示例**：初始化文件中的某个通用配置逻辑

6. **通用测试工具和 Fixture**（可以是整个文件，也可以是部分测试方法）：
   - 提供通用的测试辅助方法
   - 不依赖业务特定数据
   - 可以在多个测试中使用
   - **部分代码示例**：测试文件中的某个通用测试方法

7. **通用文档和规则**（可以是整个文件，也可以是部分内容）：
   - `.cursor/rules/*.mdc` 规则文件
   - `.cursor/commands/*.md` 指令文件
   - `docs/` 目录下的通用文档（排除 `docs/project-*/`）
   - **部分代码示例**：文档中的某个通用章节

### 📍 贡献位置分析原则

1. **分析代码功能**：代码的功能是什么？应该放在哪里？
2. **分析依赖关系**：代码依赖哪些类、方法、模块？这些依赖在哪里？
3. **分析项目结构**：基础平台的项目结构是什么？代码应该放在哪个目录？
4. **分析代码组织**：代码是否应该放在新文件、现有文件、还是新的模块中？
5. **优化贡献位置**：如果代码在业务项目中的位置不合理，应该贡献到更合适的位置

### ❌ 不应该贡献的代码特征

1. **业务特定功能**：
   - 包含业务特定的逻辑
   - 依赖业务特定的模型
   - 只适用于特定业务场景

2. **业务特定配置**：
   - 包含业务特定的设置
   - 依赖业务特定的环境变量
   - 只适用于特定业务场景

3. **业务特定测试**：
   - 测试业务特定的功能
   - 使用业务特定的数据
   - 只适用于特定业务场景

4. **业务文档**：
   - `docs/project-*/` 目录下的所有文件
   - `CURRENT_WORK.md`（如果包含业务特定内容）

## 💡 使用示例

### 示例 1：完整流程

```
用户：/contribute-code

AI 执行：
1. 检查 upstream remote：
   git remote -v
   → 发现 upstream: https://github.com/xiaohui-zhangxh/buildx.work.git ✅

2. 拉取 upstream 最新代码：
   git fetch upstream main ✅

3. 检查当前分支状态：
   git status --short
   → 分支干净 ✅
   （如果分支不干净，自动暂存到 wip/contribute-code-{timestamp}，然后继续）

4. 对比代码差异：
   git diff upstream/main --name-status
   → 发现：
     M  app/helpers/application_helper.rb
     A  lib/generic_validator.rb
     A  app/views/shared/file_upload.html.erb
     M  app/models/user.rb
   
5. 分析每个文件（支持部分代码贡献）：
   - app/helpers/application_helper.rb (M)：
     * 新增 format_date 方法（第 15-25 行，通用，可贡献）
     * 修改 existing_method 方法（第 30-40 行，改进，可贡献）
     * 新增 business_specific_method 方法（第 45-55 行，业务特定，不贡献）
     * **贡献位置**：贡献到基础平台的 `app/helpers/application_helper.rb`（相同位置）
   - lib/generic_validator.rb (A)：
     * 新增通用验证器类（整个文件，通用，可贡献）
     * **贡献位置**：贡献到基础平台的 `lib/generic_validator.rb`（相同位置）
   - app/views/shared/file_upload.html.erb (A)：
     * 新增文件上传组件（整个文件，包含业务逻辑，需要通用化）
     * **贡献位置**：通用化后贡献到基础平台的 `app/views/shared/file_upload.html.erb`
   - app/models/user.rb (M)：
     * 新增 validate_email_format 方法（第 20-30 行，通用，可贡献）
     * **贡献位置**：贡献到基础平台的 `app/models/user.rb`（相同位置）
     * 新增 business_specific_method 方法（第 35-45 行，业务特定，不贡献）

6. 生成贡献建议报告（支持部分代码）：
   - 可以直接贡献：
     * format_date 方法（app/helpers/application_helper.rb:15-25 → app/helpers/application_helper.rb）
     * existing_method 方法（app/helpers/application_helper.rb:30-40 → app/helpers/application_helper.rb）
     * validate_email_format 方法（app/models/user.rb:20-30 → app/models/user.rb）
     * generic_validator.rb（整个文件，lib/generic_validator.rb → lib/generic_validator.rb）
   - 需要通用化：file_upload.html.erb
   - 不贡献：business_specific_method 方法（业务特定）
   - 保存到 tmp/contribution-report-{timestamp}.md

7. 等待用户确认：
   用户确认贡献 format_date 方法、existing_method、validate_email_format 方法、generic_validator.rb

8. 创建贡献分支：
   git checkout -b contribute/add-format-date-and-validator upstream/main

9. 智能合并代码（支持部分代码贡献）：
   - 合并 format_date 方法到 app/helpers/application_helper.rb（部分代码）
   - 合并 existing_method 方法到 app/helpers/application_helper.rb（部分代码）
   - 合并 validate_email_format 方法到 app/models/user.rb（部分代码）
   - 复制 lib/generic_validator.rb（整个文件）

10. 提交合并结果：
    git add .
    git commit -m "Add: format_date helper and generic validator"

11. 生成 PR 提交指南：
    - 保存到 tmp/pr-guide-{timestamp}.md
    - 显示给用户

12. 清理贡献分支，回到之前的工作：
    - 切换回 wip/contribute-code-{timestamp} 分支（如果之前自动创建的）
    - 删除贡献分支 contribute/add-format-date-and-validator
    - 提示用户可以继续业务开发
```

### 示例 2：部分代码贡献到不同位置

```
用户：/contribute-code

AI 执行：
1-3. （同上）

4. 对比代码差异：
   git diff upstream/main --name-status
   → 发现：
     M  app/models/concerns/user_extensions.rb
     M  app/helpers/application_helper.rb
   
5. 分析每个文件（支持部分代码贡献和位置优化）：
   - app/models/concerns/user_extensions.rb (M)：
     * 新增 validate_email_format 方法（第 10-20 行，通用，可贡献）
     * 新增 business_specific_method 方法（第 25-35 行，业务特定，不贡献）
     * **贡献位置分析**：
       - 原位置：app/models/concerns/user_extensions.rb
       - 建议位置：app/models/user.rb（因为这是基础平台的 User 模型，应该直接添加方法，而不是通过 Concern）
       - 原因：基础平台没有 user_extensions.rb，应该直接添加到 User 模型
   
   - app/helpers/application_helper.rb (M)：
     * 新增 format_date 方法（第 15-25 行，通用，可贡献）
     * 新增 business_helper_method 方法（第 30-40 行，业务特定，不贡献）
     * **贡献位置分析**：
       - 原位置：app/helpers/application_helper.rb
       - 建议位置：app/helpers/application_helper.rb（相同位置，合理）
   
6. 生成贡献建议报告（支持部分代码和位置优化）：
   - 可以直接贡献：
     * validate_email_format 方法（app/models/concerns/user_extensions.rb:10-20 → app/models/user.rb）
     * format_date 方法（app/helpers/application_helper.rb:15-25 → app/helpers/application_helper.rb）
   - 不贡献：business_specific_method、business_helper_method（业务特定）
   - 保存到 tmp/contribution-report-{timestamp}.md

7. 等待用户确认：
   用户确认贡献 validate_email_format 方法（到 app/models/user.rb）、format_date 方法

8. 创建贡献分支：
   git checkout -b contribute/add-email-validation-and-date-format upstream/main

9. 智能合并代码（部分代码贡献到不同位置）：
   - 提取 validate_email_format 方法（从 app/models/concerns/user_extensions.rb:10-20）
   - 分析方法的依赖关系（无业务特定依赖）
   - 将方法添加到 app/models/user.rb 的合适位置（不是原文件位置）
   - 合并 format_date 方法到 app/helpers/application_helper.rb（相同位置）

10. 深度分析代码依赖和影响：
    - 检查 validate_email_format 方法的依赖（无缺失依赖）
    - 检查 format_date 方法的依赖（无缺失依赖）

11. 测试贡献分支代码：
    - 运行测试：bin/rails test ✅
    - 代码质量检查：bin/rubocop ✅

12. 生成 PR 提交指南：✅

13. 清理贡献分支，回到之前的工作：✅
```

### 示例 2：分支不干净的情况（自动处理）

```
用户：/contribute-code

AI 执行：
1. 检查 upstream remote：✅
2. 拉取 upstream 最新代码：✅
3. 检查当前分支状态：
   git status --short
   → 发现未提交的变更：
     M  app/models/user.rb
     ?? app/controllers/cards_controller.rb
   
   → 分支不干净，自动使用方式 2 暂存到独立分支
   
   自动执行：
   CURRENT_BRANCH=$(git branch --show-current)  # 记录当前分支：main
   git checkout -b wip/contribute-code-20251203-213335
   git add .
   git commit -m "WIP: 保存当前工作进度（贡献代码前自动暂存）"
   git checkout main  # 切换回原分支（现在干净了）
   
   → 已自动暂存到 wip/contribute-code-20251203-213335
   → 继续执行下一步...
   
4. 对比代码差异：✅
5. 生成贡献建议：✅
6. 创建贡献分支：✅
7. 生成 PR 提交指南：✅
8. 清理贡献分支，回到之前的工作：
   git checkout wip/contribute-code-20251203-213335
   → 已切换回之前的工作分支，可以继续业务开发
```

## ⚠️ 重要规则

1. **必须检查 upstream**：upstream remote 必须存在且指向正确的 buildx.work GitHub 仓库，否则停止执行
2. **自动处理分支状态**：如果当前分支不干净，自动使用方式 2（暂存到独立分支）处理，然后继续执行，不询问用户
3. **自动化执行**：AI 应该自动执行所有步骤，减少用户手动操作
4. **智能识别**：智能识别可贡献代码，区分基础功能和业务功能，支持识别文件中的部分代码（不只是整个文件）
5. **智能合并**：智能合并代码到贡献分支，支持部分代码贡献，分析代码的最佳贡献位置（可能不是原文件位置），处理位置差异和冲突
6. **部分代码贡献**：不一定要贡献整个文件，一个文件中的部分代码也可以贡献，必须分析代码的最佳贡献位置（可能不是原文件位置）
7. **深度分析依赖**：必须深入分析代码的依赖关系，不能只关注文件名，必须分析代码内容、方法调用、类引用等，识别所有缺失的依赖
8. **必须测试代码**：在创建贡献分支后，必须运行测试，确保代码可以正常运行，不能跳过测试步骤
9. **必须修复问题**：如果测试失败或发现缺失的依赖，必须修复问题后再继续，不能提交无法运行的代码
9. **用户确认**：关键步骤需要用户确认，确保贡献的代码正确
10. **必须使用 GitHub Pull Request**：所有贡献必须通过 GitHub Pull Request 提交
11. **遵循 GitHub 最佳实践**：
    - 使用清晰的分支命名
    - 使用规范的提交信息
    - 提供详细的 PR 描述
    - 响应审查意见
    - 保持分支更新
12. **贡献后清理**：贡献完成后，必须清理贡献分支，回到之前的工作分支，继续业务开发
   - 贡献代码后，基础平台需要时间审查，可能合并也可能拒绝
   - 不要长时间停留在贡献分支上，影响业务开发
   - 如果后续需要修改贡献，可以重新创建贡献分支

## 📚 相关资源

- [功能贡献指南](../docs/FEATURE_CONTRIBUTION.md) - 详细的贡献指南（GitHub PR 流程）
- [开发者指南](../docs/DEVELOPER_GUIDE.md) - 技术决策和架构设计
- [GitHub 最佳实践](https://guides.github.com/introduction/flow/) - GitHub 工作流最佳实践

## 🔧 技术细节

### 代码分析命令

#### 检查 Upstream Remote

```bash
# 检查 Git Remote 配置
git remote -v

# 添加 upstream remote（如果没有）
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git

# 修改 upstream URL（如果指向错误）
git remote set-url upstream https://github.com/xiaohui-zhangxh/buildx.work.git
```

#### 拉取最新代码

```bash
# 获取基础平台 main 分支的最新代码
git fetch upstream main
```

#### 检查分支状态（自动处理）

```bash
# 检查当前分支状态
git status --short

# 如果有未提交的变更，自动暂存到独立分支（AI 自动执行，不询问用户）
CURRENT_BRANCH=$(git branch --show-current)
git checkout -b wip/contribute-code-$(date +%Y%m%d-%H%M%S)
git add .
git commit -m "WIP: 保存当前工作进度（贡献代码前自动暂存）"
git checkout $CURRENT_BRANCH  # 切换回原分支（现在干净了）
```

#### 对比代码差异

```bash
# 对比所有文件差异
git diff upstream/main --name-status

# 对比特定目录的文件差异
git diff upstream/main --name-status -- app/helpers/
git diff upstream/main --name-status -- lib/
git diff upstream/main --name-status -- app/views/shared/
git diff upstream/main --name-status -- app/controllers/concerns/
git diff upstream/main --name-status -- app/models/concerns/
git diff upstream/main --name-status -- config/initializers/
git diff upstream/main --name-status -- test/test_helpers/
git diff upstream/main --name-status -- .cursor/rules/
git diff upstream/main --name-status -- .cursor/commands/
git diff upstream/main --name-status -- docs/ -- ':!docs/project-*/**'

# 对比特定文件的内容差异
git diff upstream/main -- app/helpers/application_helper.rb

# 查看文件的详细变更统计
git diff upstream/main --stat -- app/helpers/application_helper.rb

# 读取基础平台版本的文件内容（用于对比）
git show upstream/main:app/helpers/application_helper.rb
```

#### 创建贡献分支

```bash
# 创建基于 upstream/main 的贡献分支
git fetch upstream main
git checkout -b contribute/feature-description upstream/main
```

#### 检查贡献分支状态

```bash
# 检查贡献分支的提交
git log upstream/main..HEAD --oneline

# 检查贡献分支的变更
git diff upstream/main --stat
```

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-03  
**变更说明**：优化步骤 3，自动处理分支不干净的情况，不再询问用户，直接使用方式 2 暂存到独立分支  
**指令类型**：通用指令  
**适用项目**：Fork 项目（业务项目）  
**相关文档**：`docs/FEATURE_CONTRIBUTION.md`
