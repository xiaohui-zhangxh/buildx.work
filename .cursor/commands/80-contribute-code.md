# 代码贡献指令

## 概述

识别当前项目中可以贡献给 BuildX.work 基础平台的代码，并协助提取、通用化处理和贡献。适用于 fork 项目（业务项目），用于识别和贡献通用功能到基础平台。

### 使用方式

**Cursor 斜线命令**：`/contribute-code`  
**直接描述**：`找出可以贡献的代码`、`检查是否有可以贡献的代码`、`贡献代码到基础平台`

## 🎯 核心原则

1. **主动分析，不要等待**：AI 应该主动分析代码，识别可贡献的代码，而不是等待用户提供信息
2. **全面检查**：检查所有可能包含通用功能的目录和文件
3. **详细说明**：对每个可贡献的代码，详细说明为什么可以贡献、如何通用化
4. **协助提取**：协助用户提取代码并进行通用化处理
5. **协助贡献**：协助用户将代码贡献到基础平台

## 🔍 工作流程

### 步骤 1：识别项目类型

**目标**：确定当前项目是 buildx.work 还是 fork 项目。

**方法**：

1. **检查文档结构**：
   - 检查是否存在 `docs/project-*/` 目录
   - 如果存在，说明是 fork 项目
   - 如果不存在，说明是 buildx.work 项目

2. **检查 Git Remote**：
   ```bash
   git remote -v
   ```
   - 如果 origin 指向业务项目仓库，说明是 fork 项目
   - 如果 origin 指向 buildx.work 仓库，说明是 buildx.work 项目

3. **检查 README.md**：
   - 根目录 `README.md` 只做简单介绍和链接，指向 `engines/buildx_core/README.md`
   - 详细的基础设施文档在 `engines/buildx_core/README.md`
   - 如果存在 `docs/project-*/` 目录，说明是 fork 项目
   - 如果不存在 `docs/project-*/` 目录，说明是 buildx.work 项目

**输出**：
- 项目类型（buildx.work / fork 项目）
- 如果是 fork 项目，项目名称和文档路径

**注意**：如果当前项目是 buildx.work，提示用户此指令适用于 fork 项目。

### 步骤 2：分析代码结构

**目标**：全面分析项目代码，找出可能包含通用功能的代码。

**方法**：

1. **检查通用工具类和 Helper**：
   - 检查 `app/helpers/application_helper.rb` 中的方法
   - 检查 `lib/` 目录下的工具类
   - 检查 `app/forms/` 中的通用表单类
   - 检查 `app/controllers/concerns/` 中的通用 Concern

2. **检查通用组件和 Partial**：
   - 检查 `app/views/shared/` 目录下的组件
   - 检查 `app/views/application/` 目录下的组件
   - 检查 JavaScript 控制器（`app/javascript/controllers/`）

3. **检查通用控制器功能**：
   - 检查 `app/controllers/` 中的通用控制器
   - 检查 `app/controllers/concerns/` 中的通用功能

4. **检查通用模型功能**：
   - 检查 `app/models/concerns/` 中的通用 Concern
   - 检查 `app/models/` 中的通用模型功能

5. **检查通用配置和初始化**：
   - 检查 `config/initializers/` 中的通用配置
   - 检查 `config/` 中的通用配置文件

6. **检查通用测试工具**：
   - 检查 `test/test_helpers/` 中的通用测试工具
   - 检查 `test/supports/` 中的通用测试支持

**输出**：
- 所有可能包含通用功能的文件列表
- 每个文件的简要说明

### 步骤 2.5：对比基础平台代码（重要）

**目标**：对比业务项目的代码和基础平台 main 分支的代码，识别更改内容。

**重要**：这是关键步骤，可以准确识别哪些是新增功能、哪些是改进、哪些已经存在。

**方法**：

1. **检查 Git Remote 配置**：
   ```bash
   git remote -v
   ```
   - 检查是否有 `upstream` remote 指向基础平台
   - 如果没有，提示用户添加：
     ```bash
     git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git
     ```

2. **获取基础平台最新代码**：
   ```bash
   # 获取基础平台 main 分支的最新代码
   git fetch upstream main
   ```

3. **对比文件差异**：
   ```bash
   # 对比当前分支和基础平台 main 分支的所有文件差异
   git diff upstream/main --name-status
   
   # 对比特定目录的文件差异
   git diff upstream/main --name-status -- app/helpers/
   git diff upstream/main --name-status -- lib/
   git diff upstream/main --name-status -- app/views/shared/
   git diff upstream/main --name-status -- app/controllers/concerns/
   git diff upstream/main --name-status -- app/models/concerns/
   git diff upstream/main --name-status -- config/initializers/
   git diff upstream/main --name-status -- test/test_helpers/
   ```

4. **分析文件变更类型**：
   - **新增文件（A）**：业务项目新增的文件，可能是通用功能
   - **修改文件（M）**：业务项目修改的文件，可能是改进或修复
   - **删除文件（D）**：业务项目删除的文件（通常不需要贡献）

5. **对比具体文件内容**：
   ```bash
   # 对比特定文件的内容差异
   git diff upstream/main -- app/helpers/application_helper.rb
   
   # 查看文件的详细变更统计
   git diff upstream/main --stat -- app/helpers/application_helper.rb
   
   # 查看基础平台版本的文件内容（用于对比）
   git show upstream/main:app/helpers/application_helper.rb
   ```

6. **读取基础平台文件内容**：
   - 对于修改的文件，读取基础平台版本和业务项目版本
   - 对比两个版本，识别具体的变更：
     - 新增的方法
     - 修改的方法
     - 删除的方法
     - 修改的配置
     - 其他变更

7. **识别可贡献的变更**：
   - **新增的通用功能**：新增的文件，且不包含业务特定逻辑
   - **改进的基础功能**：修改的文件，改进了基础平台的功能
   - **修复的 Bug**：修改的文件，修复了基础平台的 Bug
   - **业务特定功能**：新增或修改的文件，但包含业务特定逻辑（需要通用化）

**输出**：
- 文件变更列表（新增、修改、删除）
- 每个变更文件的详细对比
- 变更类型分类（新增功能、改进、修复、业务特定）

**注意**：
- 如果无法访问 upstream，提示用户配置 upstream remote
- 如果 upstream 不存在，提示用户添加 upstream remote
- 对比时，确保使用基础平台的 main 分支作为基准

### 步骤 3：识别可贡献代码

**目标**：基于对比分析结果，对每个变更文件进行分析，识别哪些代码可以贡献。

**方法**：

1. **基于对比结果分析**：
   - **新增文件**：
     - 读取文件内容
     - 分析是否包含业务特定逻辑
     - 判断是否可以贡献
   - **修改文件**：
     - 读取文件内容
     - 对比基础平台版本和业务项目版本
     - 分析修改内容（新增方法、修改方法、删除方法）
     - 判断修改是否具有通用价值
   - **删除文件**：
     - 通常不需要贡献（除非是清理无用代码）

2. **读取文件内容**：
   - 读取业务项目中的文件内容
   - 如果是修改的文件，同时读取基础平台版本进行对比
   - 分析代码逻辑和依赖

3. **判断通用性**：
   - **检查业务特定逻辑**：
     - 是否包含业务特定的模型引用？
     - 是否包含业务特定的配置？
     - 是否包含业务特定的常量？
   - **检查依赖关系**：
     - 依赖哪些业务模型？
     - 依赖哪些业务配置？
     - 依赖哪些业务 Helper？
   - **检查可参数化程度**：
     - 是否可以参数化业务特定值？
     - 是否可以抽象为接口？
     - 是否可以通过配置使用？

3. **评估贡献价值**：
   - **通用性**：是否可以在多个项目中使用？
   - **价值**：是否解决了通用问题？
   - **完整性**：功能是否完整？
   - **测试覆盖**：是否有测试覆盖？

4. **分类可贡献代码**：
   - **新增的通用功能**：新增的文件，代码已经是通用的，可以直接贡献
   - **改进的基础功能**：修改的文件，改进了基础平台的功能，可以直接贡献
   - **修复的 Bug**：修改的文件，修复了基础平台的 Bug，可以直接贡献
   - **需要通用化**：新增或修改的文件，代码包含业务逻辑，需要通用化处理
   - **需要重构**：代码结构需要重构才能贡献
   - **不适合贡献**：代码包含太多业务特定逻辑，不适合贡献
   - **已存在**：基础平台已经存在相同或类似的功能，不需要贡献

**输出**：
- 可贡献代码列表（按分类和变更类型）
- 每个代码的详细说明：
  - 文件路径
  - 变更类型（新增/修改/删除）
  - 变更内容（如果是修改，说明具体修改了什么）
  - 代码功能
  - 通用性评估
  - 贡献价值
  - 通用化建议（如需要）
  - 与基础平台的对比（如果是修改，说明与基础平台的差异）

### 步骤 4：生成贡献建议报告

**目标**：生成详细的贡献建议报告，帮助用户了解可以贡献的代码。

**方法**：

1. **创建报告结构**：
   - 可以直接贡献的代码列表
   - 需要通用化的代码列表
   - 需要重构的代码列表
   - 不适合贡献的代码列表（说明原因）

2. **为每个代码提供详细信息**：
   - **代码位置**：文件路径和行号范围
   - **变更类型**：新增（A）/ 修改（M）/ 删除（D）
   - **变更内容**：如果是修改，说明具体修改了什么（新增方法、修改方法、删除方法等）
   - **与基础平台对比**：如果是修改，说明与基础平台版本的差异
   - **代码功能**：功能描述
   - **通用性评估**：为什么可以贡献或为什么不能贡献
   - **贡献价值**：贡献后对基础平台的价值
   - **通用化建议**：如何通用化（如需要）
   - **贡献步骤**：如何贡献（如需要）

3. **提供优先级建议**：
   - **高优先级**：通用性强、价值高、可以直接贡献
   - **中优先级**：通用性强、价值高、需要通用化
   - **低优先级**：通用性一般、价值一般、需要重构

**输出**：
- 贡献建议报告（Markdown 格式）
- 保存到临时文件或直接显示给用户

### 步骤 5：协助提取和通用化（如果用户选择）

**目标**：协助用户提取代码并进行通用化处理。

**方法**：

1. **提取代码**：
   - 从业务项目中提取代码
   - 创建新的通用文件（如需要）
   - 移除业务特定逻辑

2. **通用化处理**：
   - 参数化业务特定值
   - 抽象业务特定逻辑
   - 使用配置替代硬编码
   - 确保向后兼容

3. **添加测试**：
   - 为通用代码添加测试
   - 确保测试覆盖率至少 85%

4. **更新文档**：
   - 更新相关文档说明新功能
   - 添加使用示例

**输出**：
- 通用化后的代码文件
- 测试文件
- 文档更新

### 步骤 6：协助贡献到基础平台（如果用户选择）

**目标**：协助用户通过 GitHub Pull Request 将代码贡献到基础平台。

**重要**：BuildX.work 是 GitHub 开源项目，所有贡献必须通过 GitHub Pull Request 提交。

**方法**：

1. **检查 GitHub 仓库**：
   - 确认 buildx.work 的 GitHub 仓库地址
   - 确认用户是否已 Fork 仓库
   - 如果未 Fork，提示用户先 Fork

2. **指导 Fork 和克隆**：
   - 指导用户在 GitHub 上 Fork 仓库
   - 指导用户克隆 Fork 的仓库
   - 指导用户添加上游仓库（upstream）

3. **指导创建功能分支**：
   - 确保 main 分支是最新的
   - 创建功能分支（使用清晰的命名）
   - 说明分支命名规范

4. **指导提取和通用化代码**：
   - 在功能分支上提取代码
   - 进行通用化处理
   - 添加测试
   - 更新文档

5. **指导提交代码**：
   - 使用规范的提交信息格式
   - 确保提交信息清晰描述功能和用途
   - 如果有关联 Issue，使用 `Closes #123`

6. **指导创建 Pull Request**：
   - 推送分支到 GitHub
   - 提供 PR 模板
   - 说明需要填写的内容：
     - 功能描述
     - 使用场景
     - 实现方案
     - 测试结果
     - 向后兼容性
     - 文档更新
     - 相关 Issue

7. **指导代码审查流程**：
   - 说明如何响应审查意见
   - 说明如何同步上游更新
   - 说明 PR 合并后的清理工作

**输出**：
- GitHub 贡献流程指导
- PR 模板
- 下一步操作建议

## 📝 识别规则

### ✅ 应该贡献的代码特征

1. **通用工具类和 Helper 方法**：
   - 不依赖业务逻辑
   - 可以在多个场景下使用
   - 提供通用的功能

2. **通用组件和 Partial**：
   - 不包含业务特定内容
   - 可以通过参数配置
   - 可以在多个页面复用

3. **通用控制器功能**：
   - 提供通用的 CRUD 操作
   - 不依赖业务模型
   - 可以通过配置或继承使用

4. **通用模型功能（Concern/Module）**：
   - 提供通用的模型行为
   - 不依赖业务特定逻辑
   - 可以通过 include 使用

5. **通用配置和初始化**：
   - 提供通用的配置选项
   - 不依赖业务特定设置
   - 可以通过环境变量或配置文件使用

6. **通用测试工具和 Fixture**：
   - 提供通用的测试辅助方法
   - 不依赖业务特定数据
   - 可以在多个测试中使用

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

## 💡 使用示例

### 示例 1：识别可贡献代码

```
用户：/contribute-code

AI 执行：
1. 识别项目类型：fork 项目（project-example）
2. 分析代码结构：检查所有可能包含通用功能的目录
3. 对比基础平台代码：
   - 检查 git remote upstream 配置
   - 获取基础平台 main 分支最新代码
   - 对比文件差异：
     * app/helpers/application_helper.rb (M) - 修改
     * lib/generic_validator.rb (A) - 新增
     * app/views/shared/file_upload.html.erb (A) - 新增
   - 分析每个文件的变更内容
4. 识别可贡献代码：
   - app/helpers/application_helper.rb (M)：
     * 新增 format_date 方法（可以直接贡献）
     * 修改 existing_method 方法（改进，可以直接贡献）
   - lib/generic_validator.rb (A)：
     * 新增通用验证器类（可以直接贡献）
   - app/views/shared/file_upload.html.erb (A)：
     * 新增文件上传组件（需要通用化）
5. 生成贡献建议报告（包含对比信息）
6. 显示报告给用户
```

### 示例 2：对比分析详细流程

```
用户：/contribute-code

AI 执行步骤 2.5（对比基础平台代码）：

1. 检查 Git Remote：
   git remote -v
   → 发现已有 upstream: https://github.com/xiaohui-zhangxh/buildx.work.git

2. 获取基础平台最新代码：
   git fetch upstream main

3. 对比文件差异：
   git diff upstream/main --name-status
   → 输出：
     M  app/helpers/application_helper.rb
     A  lib/generic_validator.rb
     A  app/views/shared/file_upload.html.erb

4. 分析每个文件的变更：
   - app/helpers/application_helper.rb (M)：
     git diff upstream/main -- app/helpers/application_helper.rb
     → 发现：
       + def format_date(date, format = :long)
       +   # 新增方法
       + end
       - def old_method
       + def improved_method
       * 修改了 existing_method 方法
   
   - lib/generic_validator.rb (A)：
     → 新增文件，读取内容分析
   
   - app/views/shared/file_upload.html.erb (A)：
     → 新增文件，读取内容分析

5. 识别可贡献代码：
   - format_date 方法：新增，通用，可直接贡献
   - improved_method：改进，通用，可直接贡献
   - generic_validator.rb：新增，通用，可直接贡献
   - file_upload.html.erb：新增，包含业务逻辑，需要通用化
```

### 示例 3：协助提取和贡献

```
用户：/contribute-code
AI：发现 3 个可以贡献的代码，是否协助提取和贡献？
用户：是，协助提取 format_date 方法

AI 执行：
1. 对比基础平台代码，确认 format_date 是新增方法
2. 提取 format_date 方法
3. 检查是否包含业务特定逻辑（无）
4. 检查是否有测试（有）
5. 指导用户在 GitHub 上 Fork 和创建功能分支
6. 指导用户复制代码和测试
7. 指导用户运行测试确保通过
8. 指导用户提交贡献和创建 PR
```

## ⚠️ 重要规则

1. **必须主动分析**：不要等待用户提供信息，主动分析代码
2. **全面检查**：检查所有可能包含通用功能的目录和文件
3. **详细说明**：对每个可贡献的代码，详细说明为什么可以贡献
4. **提供建议**：提供通用化建议和贡献步骤
5. **协助但不强制**：协助用户提取和贡献，但不强制用户贡献
6. **尊重用户选择**：如果用户选择不贡献，尊重其选择
7. **必须使用 GitHub Pull Request**：所有贡献必须通过 GitHub Pull Request 提交，不要使用其他方式（如 Git 补丁、直接提交等）
8. **遵循 GitHub 最佳实践**：
   - 使用清晰的分支命名
   - 使用规范的提交信息
   - 提供详细的 PR 描述
   - 响应审查意见
   - 保持分支更新
9. **一个 PR 一个功能**：每个 PR 只包含一个功能或修复，避免混合多个不相关的更改
10. **保持 PR 简洁**：如果功能很大，考虑拆分为多个 PR
11. **提供完整信息**：PR 描述要包含功能描述、使用场景、测试结果、向后兼容性等信息

## 📚 相关资源

- [功能贡献指南](../docs/FEATURE_CONTRIBUTION.md) - 详细的贡献指南（GitHub PR 流程）
- [贡献指南](../docs/CONTRIBUTING.md) - 修复贡献指南（GitHub PR 流程）
- [开发者指南](../docs/DEVELOPER_GUIDE.md) - 技术决策和架构设计
- [GitHub 最佳实践](https://guides.github.com/introduction/flow/) - GitHub 工作流最佳实践

## 🔧 技术细节

### 代码分析命令

#### 对比基础平台代码

```bash
# 检查 Git Remote 配置
git remote -v

# 添加 upstream remote（如果没有）
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git

# 获取基础平台最新代码
git fetch upstream main

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

# 对比特定文件的内容差异
git diff upstream/main -- app/helpers/application_helper.rb

# 查看文件的详细变更统计
git diff upstream/main --stat -- app/helpers/application_helper.rb

# 查看文件的详细变更内容
git diff upstream/main -- app/helpers/application_helper.rb | head -100

# 读取基础平台版本的文件内容（用于对比）
git show upstream/main:app/helpers/application_helper.rb

# 读取业务项目版本的文件内容
cat app/helpers/application_helper.rb
```

#### 查找文件

```bash
# 查找所有 Helper 文件
find app/helpers -name "*.rb" -type f

# 查找所有 Concern 文件
find app -path "*/concerns/*.rb" -type f

# 查找所有 JavaScript 控制器
find app/javascript/controllers -name "*_controller.js" -type f

# 查找所有共享视图
find app/views/shared -name "*.html.erb" -type f

# 查找所有工具类
find lib -name "*.rb" -type f
```

### 文件内容分析

使用 `read_file` 工具读取文件内容，然后：
1. 分析代码逻辑
2. 检查业务特定引用
3. 评估通用性
4. 提供通用化建议

---

**创建时间**：2025-12-02  
**最后更新**：2025-12-02  
**指令类型**：通用指令  
**适用项目**：Fork 项目（业务项目）  
**相关文档**：`docs/FEATURE_CONTRIBUTION.md`

