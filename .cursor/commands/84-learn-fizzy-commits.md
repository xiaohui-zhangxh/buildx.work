# 学习 Fizzy 新提交指令

## 概述

每日学习 Basecamp Fizzy 项目的新提交代码变更，学习他们的新思路和最佳实践。一天只学习一次，通过学习日志文件记录最后的学习时间和学习到的 commit 信息，避免重复学习。

**核心功能**：
- 自动克隆或更新 Fizzy 仓库到 `tmp/fizzy` 目录
- 智能辨识哪些 commit 值得记录为经验文档
- 自动更新现有经验文档或创建新文档
- 更新总览文档，保持文档索引完整
- **敏感信息保护**：确保不将敏感信息写入经验文档（经验文档会对外输出）
- **敏感信息保护**：确保不将敏感信息写入经验文档（经验文档会对外输出）

### 使用方式

**Cursor 斜线命令**：`/learn-fizzy-commits`  
**直接描述**：`学习 Fizzy 新提交`、`查看 Fizzy 最新代码变更`、`学习 Fizzy 新思路`

## 🎯 核心原则

1. **自主学习**：**AI 必须自主决定学习策略，不需要询问用户**。包括：
   - 自主决定每次学习多少内容（建议每次学习 5-10 天的 commit，或 20-50 个 commit）
   - 自主判断什么时候停下来总结（学习完一批后自动总结）
   - 自主判断什么时候写出有用的经验总结（发现值得记录的经验时立即更新文档）
   - 自主决定学习节奏，不需要询问用户意见
2. **每日一次**：一天只学习一次，通过日志文件避免重复学习
3. **记录学习历史**：记录最后学习时间和学习到的 commit 信息
4. **学习新思路**：重点学习代码变更背后的设计思路和最佳实践
5. **避免重复**：只学习新的 commit，跳过已学习的 commit
6. **生成学习笔记**：为每个 commit 生成学习笔记，记录关键要点
7. **智能辨识经验**：智能辨识哪些 commit 值得记录为经验文档
8. **敏感信息保护**：**必须**遵守敏感信息保护规则，确保不将敏感信息写入经验文档（经验文档会对外输出）
9. **管理经验文档**：自动更新现有经验文档或创建新文档，保持文档结构清晰
10. **及时总结**：学习完一批 commit 后，自动生成学习总结，更新学习日志，更新经验文档

## 🔍 工作流程

### 步骤 1：检查或克隆 Fizzy 仓库

**目标**：确保 Fizzy 仓库已克隆到项目的 tmp 目录。

**方法**：

```bash
# Fizzy 仓库位置：tmp/fizzy
FIZZY_DIR="tmp/fizzy"

# 如果不存在，自动克隆
if [ ! -d "$FIZZY_DIR" ]; then
  echo "📥 Fizzy 仓库不存在，正在克隆到 $FIZZY_DIR..."
  git clone https://github.com/basecamp/fizzy.git "$FIZZY_DIR"
  echo "✅ Fizzy 仓库克隆完成"
else
  echo "✅ Fizzy 仓库已存在：$FIZZY_DIR"
fi
```

**输出**：
- Fizzy 仓库路径（`tmp/fizzy`）
- 如果不存在，自动克隆
- 如果已存在，确认路径

### 步骤 2：读取或创建学习日志文件

**目标**：读取学习日志文件，获取最后学习时间和已学习的 commit 列表。

**方法**：

1. **学习日志文件位置**：`docs/fizzy-learning-log.md`（不对外输出，仅内部使用）

2. **日志文件格式**：

```markdown
# Fizzy 学习日志

## 最后学习时间

2025-12-08 10:30:00

## 已学习的 Commit

### 2025-12-08

#### Commit: abc1234
- **作者**：DHH
- **时间**：2025-12-08 09:00:00
- **消息**：Improve dialog controller performance
- **变更文件**：
  - app/javascript/controllers/dialog_controller.js
  - app/assets/stylesheets/dialog.css
- **学习要点**：
  - 优化了 dialog 控制器的性能
  - 使用 requestAnimationFrame 优化动画
  - 改进了事件监听器的清理逻辑

#### Commit: def5678
- **作者**：Basecamp Team
- **时间**：2025-12-08 08:00:00
- **消息**：Add turbo frame loading state
- **变更文件**：
  - app/javascript/controllers/turbo_frame_controller.js
- **学习要点**：
  - 添加了 turbo frame 加载状态
  - 使用 CSS 动画显示加载指示器
```

3. **读取日志文件**：
   - 如果文件不存在，创建新文件
   - 读取最后学习时间
   - 读取已学习的 commit hash 列表

**输出**：
- 最后学习时间（如果存在）
- 已学习的 commit 数量

### 步骤 3：获取 Fizzy 仓库最新代码

**目标**：拉取 Fizzy 仓库的最新代码，确保有最新的 commit。

**方法**：

```bash
cd tmp/fizzy
git fetch origin main
git pull origin main
```

**输出**：
- 拉取结果（成功/失败）
- 最新 commit 信息

### 步骤 4：获取新的 Commit 列表

**目标**：获取从上次学习到的 Fizzy 日期之后的所有新 commit（按日期学习）。

**方法**：

```bash
cd tmp/fizzy

# 如果日志文件存在，获取最后学习到的 Fizzy 日期
LAST_FIZZY_DATE=$(grep -A 1 "## 最后学习到的 Fizzy 日期" ../../docs/fizzy-learning-log.md | tail -1 | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -1)

# 如果最后学习到的 Fizzy 日期存在，获取该日期之后的所有 commit
if [ -n "$LAST_FIZZY_DATE" ]; then
  # 获取该日期之后的所有 commit（从下一天开始）
  NEXT_DATE=$(date -j -v+1d -f "%Y-%m-%d" "$LAST_FIZZY_DATE" +"%Y-%m-%d" 2>/dev/null || date -d "$LAST_FIZZY_DATE +1 day" +"%Y-%m-%d" 2>/dev/null || echo "")
  if [ -n "$NEXT_DATE" ]; then
    # 获取从下一天开始到昨天的所有 commit
    YESTERDAY=$(date -j -v-1d +"%Y-%m-%d" 2>/dev/null || date -d "yesterday" +"%Y-%m-%d" 2>/dev/null || echo "")
    git log --since="$NEXT_DATE" --until="$YESTERDAY 23:59:59" --format="%ad|%H|%an|%s" --date=format:"%Y-%m-%d"
  else
    # 如果日期计算失败，使用简单的方式：从该日期之后开始
    git log --since="$LAST_FIZZY_DATE" --format="%ad|%H|%an|%s" --date=format:"%Y-%m-%d"
  fi
else
  # 如果不存在，从第一个 commit 的日期开始学习
  FIRST_COMMIT_DATE=$(git log --reverse --format="%ad" --date=format:"%Y-%m-%d" | head -1)
  git log --since="$FIRST_COMMIT_DATE" --format="%ad|%H|%an|%s" --date=format:"%Y-%m-%d"
fi
```

**输出**：
- 新 commit 列表（日期|hash, 作者, 消息），按日期分组
- 如果今天已经学习过，提示"今天已经学习过了"

**注意**：
- 学习策略是按日期学习，每次学习某一天的所有 commit
- 首次学习时，从第一个 commit 的日期开始
- 后续学习时，从"最后学习到的 Fizzy 日期"的下一天开始，学到昨天为止

### 步骤 5：检查今天是否已学习

**目标**：检查今天是否已经学习过，避免重复学习。

**方法**：

```bash
# 获取今天的日期
TODAY=$(date +%Y-%m-%d)

# 检查日志文件中最后学习时间是否是今天
if [ -f docs/fizzy-learning-log.md ]; then
  LAST_LEARN_DATE=$(grep -A 1 "## 最后学习时间" docs/fizzy-learning-log.md | tail -1 | cut -d' ' -f1)
  
  if [ "$LAST_LEARN_DATE" = "$TODAY" ]; then
    echo "✅ 今天已经学习过了（最后学习时间：$LAST_LEARN_DATE）"
    echo "💡 如果想重新学习，可以手动修改日志文件中的最后学习时间"
    exit 0
  fi
fi
```

**输出**：
- 如果今天已学习，提示并退出
- 如果未学习，继续执行

### 步骤 6：自主学习策略（重要）

**目标**：AI 必须自主决定学习策略，不需要询问用户。

**自主学习规则**：

1. **学习数量**：
   - 每次学习 5-10 天的 commit（如果每天 commit 较少）
   - 或者学习 20-50 个 commit（如果单天 commit 较多）
   - 根据 commit 的复杂度和价值自主调整
   - **不需要询问用户**，AI 自主决定

2. **学习节奏**：
   - 学习完一批 commit 后，自动停下来总结
   - 更新学习日志和经验文档
   - 然后继续学习下一批（如果还有未学习的 commit）
   - **不需要询问用户**，AI 自主决定

3. **经验总结**：
   - 发现值得记录的经验时，立即更新经验文档
   - 不需要等待用户确认
   - **不需要询问用户**，AI 自主决定

4. **停止条件**：
   - 学习完一批 commit 后，自动生成总结
   - 如果还有未学习的 commit，继续学习下一批
   - 如果已经学习了足够的内容（如 50 个 commit 或 10 天的内容），可以停止
   - **不需要询问用户**，AI 自主决定

**重要**：AI 在执行学习指令时，必须完全自主，不要询问用户"要不要继续"、"学习多少"等问题。直接执行学习、分析、总结、更新文档的完整流程。

### 步骤 7：分析每个新 Commit

**目标**：分析每个新 commit 的代码变更，学习新的思路。

**方法**：

对于每个新 commit：

1. **获取 commit 详细信息**：

```bash
# 获取 commit 信息
COMMIT_HASH="abc1234"
cd tmp/fizzy
git show --stat "$COMMIT_HASH"
git show --name-status "$COMMIT_HASH"
cd ../..
```

2. **获取变更文件列表**：

```bash
git show --name-status "$COMMIT_HASH" | grep -E "^[AMD]"
```

3. **分析代码变更**：

```bash
# 获取代码变更内容
git show "$COMMIT_HASH"
```

4. **学习要点分析**（AI 分析）：
   - 代码变更的目的和原因
   - 设计思路和最佳实践
   - 可以应用到 BuildX 的实践
   - 技术亮点和值得学习的地方

**输出**：
- 每个 commit 的详细信息
- 变更文件列表
- 代码变更内容
- 学习要点（AI 分析生成）

### 步骤 7.5：智能辨识值得记录经验的 Commit

**目标**：智能辨识哪些 commit 的更改值得记录为经验文档。

**方法**：

1. **判断标准**（AI 分析每个 commit）：

   **值得记录经验的 commit 特征**：
   - ✅ **代码风格改进**：代码风格、命名规范、代码组织方式的改进
   - ✅ **设计模式**：新的设计模式、架构决策、代码组织方式
   - ✅ **最佳实践**：性能优化、错误处理、测试策略等最佳实践
   - ✅ **Hotwire 使用**：Turbo Streams、Turbo Frames、Stimulus 的新用法
   - ✅ **业务设计**：多租户、权限控制、通知系统等业务设计
   - ✅ **技术技巧**：Rails 技巧、JavaScript 技巧、CSS 技巧等
   - ✅ **问题解决**：解决特定问题的方案
   - ❌ **不值得记录**：简单的 bug 修复、文档更新、配置调整（除非有特殊价值）

2. **分析每个 commit**：
   - 阅读 commit 消息和代码变更
   - 判断是否包含值得学习的经验
   - 识别经验的主题和分类
   - 评估经验的价值和适用性

3. **分类经验**：
   - **代码风格**：`fizzy-code-style-guide.md`
   - **模型设计**：`fizzy-model-design.md`
   - **控制器设计**：`fizzy-controller-design.md`
   - **Hotwire 使用**：`fizzy-hotwire-practices.md` 或相关专题文档
   - **业务设计**：相关业务设计文档（如 `fizzy-notification-system.md`）
   - **新主题**：可能需要创建新文档

**输出**：
- 值得记录经验的 commit 列表
- 每个 commit 的经验分类
- 经验主题和适用文档

### 步骤 8：生成学习笔记

**目标**：为每个新 commit 生成学习笔记，记录关键要点。

**方法**：

1. **分析每个 commit**：
   - 阅读代码变更
   - 理解变更目的
   - 提取设计思路
   - 总结最佳实践

2. **生成学习笔记**：

```markdown
#### Commit: {hash}
- **作者**：{author}
- **时间**：{date}
- **消息**：{message}
- **变更文件**：
  - {file1}
  - {file2}
- **学习要点**：
  - {要点1}
  - {要点2}
  - {要点3}
- **是否值得记录经验**：{是/否}
- **经验分类**：{分类}（如果值得记录）
```

3. **保存到日志文件**：
   - 追加到日志文件
   - 按日期分组
   - 按时间倒序排列

**输出**：
- 学习笔记（Markdown 格式）
- 保存到日志文件

### 步骤 8.5：检查并更新经验文档

**目标**：对于值得记录经验的 commit，检查是否需要更新现有经验文档或创建新文档。

**⚠️ 重要：敏感信息保护**

在记录经验时，**必须**遵守以下规则，确保不将敏感信息写入经验文档：

1. **禁止记录的内容**：
   - ❌ API 密钥、密码、令牌等敏感凭证
   - ❌ 内部业务逻辑细节（如果涉及商业机密）
   - ❌ 用户数据、个人信息
   - ❌ 内部系统架构细节（如果涉及安全）
   - ❌ 具体的业务数据、配置值（除非是通用的最佳实践）
   - ❌ 内部工具、流程的详细信息

2. **允许记录的内容**：
   - ✅ 代码风格和最佳实践
   - ✅ 设计模式和架构思路（通用部分）
   - ✅ 技术实现方案（不涉及具体业务）
   - ✅ 问题解决思路和方法
   - ✅ 通用的配置方式（不包含具体值）
   - ✅ 代码示例（去除敏感信息后）

3. **处理原则**：
   - 如果 commit 包含敏感信息，只记录通用的设计思路和最佳实践
   - 使用占位符替代具体的敏感值（如 `API_KEY`、`SECRET` 等）
   - 如果无法去除敏感信息，跳过该 commit 的经验记录
   - 在记录经验时，重点记录"为什么这样做"和"如何做"，而不是"具体做了什么"

4. **检查清单**（在记录经验前必须检查）：
   - [ ] 是否包含 API 密钥、密码等敏感凭证？
   - [ ] 是否包含内部业务逻辑细节？
   - [ ] 是否包含用户数据或个人信息？
   - [ ] 是否包含具体的配置值（而非通用方式）？
   - [ ] 代码示例是否已去除敏感信息？

**方法**：

1. **检查现有经验文档**：
   - 读取 `docs/experiences/fizzy-overview.md` 了解现有文档索引
   - 根据经验分类，查找相关的经验文档
   - 检查文档内容是否已经包含类似经验

2. **判断更新策略**：

   **更新现有文档**（如果满足以下条件）：
   - ✅ 经验主题与现有文档匹配
   - ✅ 经验是对现有内容的补充或改进
   - ✅ 经验属于同一技术领域或设计模式

   **创建新文档**（如果满足以下条件）：
   - ✅ 经验主题是全新的
   - ✅ 经验无法归类到现有文档
   - ✅ 经验足够重要，值得独立成文

3. **更新现有文档**：

   **步骤**：
   - 读取现有经验文档
   - 分析新经验与现有内容的关系
   - **检查敏感信息**：确保新经验不包含敏感信息（参考敏感信息保护规则）
   - 决定插入位置（新增章节、更新现有章节、添加示例等）
   - 更新文档内容，保持文档结构清晰
   - **再次检查敏感信息**：更新后再次检查，确保没有泄露敏感信息
   - 更新文档的 front matter（如需要）

   **更新示例**：

   ```markdown
   ## 新章节或更新现有章节
   
   ### 从 Commit {hash} 学到的经验
   
   **时间**：{date}
   **作者**：{author}
   **变更文件**：{files}
   
   {经验内容}
   
   **代码示例**：
   ```ruby
   {代码示例}
   ```
   
   **要点**：
   - {要点1}
   - {要点2}
   ```

4. **创建新文档**：

   **步骤**：
   - 确定文档文件名（遵循命名规范：`fizzy-{主题}.md`）
   - **检查敏感信息**：确保要记录的经验不包含敏感信息（参考敏感信息保护规则）
   - 创建文档，包含 front matter
   - 编写文档内容（确保不包含敏感信息）
   - **再次检查敏感信息**：创建后再次检查，确保没有泄露敏感信息
   - 更新 `fizzy-overview.md` 添加新文档索引

   **文档模板**：

   ```markdown
   ---
   date: {当前日期}
   problem_type: 学习笔记、最佳实践、{主题}
   status: 已完成
   tags: Fizzy、{相关标签}
   description: {文档描述}
   ---
   
   # {文档标题}
   
   ## 概述
   
   {概述内容}
   
   ## 从 Commit {hash} 学到的经验
   
   **时间**：{date}
   **作者**：{author}
   **变更文件**：{files}
   
   {经验内容}
   
   ## 可以应用到 BuildX 的实践
   
   {应用建议}
   ```

5. **更新总览文档**（如果创建了新文档）：

   - 读取 `docs/experiences/fizzy-overview.md`
   - 在"学习文档索引"部分添加新文档的链接和说明
   - 保持索引的排序和分类

**输出**：
- 更新的经验文档列表
- 新创建的经验文档列表
- 更新后的总览文档（如需要）

### 步骤 9：更新学习日志文件

**目标**：更新学习日志文件，记录最后学习时间和学习到的 commit 信息。

**方法**：

1. **更新最后学习时间**：

```bash
# 获取当前时间
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 更新日志文件中的最后学习时间
sed -i '' "s/^## 最后学习时间$/## 最后学习时间\n\n$CURRENT_TIME/" docs/fizzy-learning-log.md
```

2. **追加学习笔记**：
   - 在日志文件中追加新的学习笔记
   - 按日期分组
   - 按时间倒序排列

**输出**：
- 更新后的日志文件
- 最后学习时间
- 新增的学习笔记数量

### 步骤 10：生成学习总结

**目标**：生成本次学习的总结报告。

**方法**：

1. **统计学习成果**：
   - 学习的 commit 数量
   - 变更的文件数量
   - 学习到的关键要点
   - 值得记录经验的 commit 数量
   - 更新的经验文档数量
   - 新创建的经验文档数量

2. **生成总结报告**：

```markdown
## 📚 学习总结

**学习时间**：{当前时间}
**学习的 Commit 数量**：{数量}
**变更的文件数量**：{数量}
**值得记录经验的 Commit 数量**：{数量}
**更新的经验文档数量**：{数量}
**新创建的经验文档数量**：{数量}

### 关键学习要点

1. {要点1}
2. {要点2}
3. {要点3}

### 经验文档更新

- **更新的文档**：
  - {文档1}：{更新说明}
  - {文档2}：{更新说明}

- **新创建的文档**：
  - {文档1}：{说明}
  - {文档2}：{说明}

### 可以应用到 BuildX 的实践

1. {实践1}
2. {实践2}
```

**输出**：
- 学习总结报告
- 显示给用户

## 📝 学习日志文件格式

学习日志文件位置：`docs/fizzy-learning-log.md`（不对外输出，仅内部使用）

### 文件结构

```markdown
# Fizzy 学习日志

## 最后学习时间

2025-12-08 10:30:00

## 已学习的 Commit

### 2025-12-08

#### Commit: abc1234
- **作者**：DHH
- **时间**：2025-12-08 09:00:00
- **消息**：Improve dialog controller performance
- **变更文件**：
  - app/javascript/controllers/dialog_controller.js
  - app/assets/stylesheets/dialog.css
- **学习要点**：
  - 优化了 dialog 控制器的性能
  - 使用 requestAnimationFrame 优化动画
  - 改进了事件监听器的清理逻辑

#### Commit: def5678
- **作者**：Basecamp Team
- **时间**：2025-12-08 08:00:00
- **消息**：Add turbo frame loading state
- **变更文件**：
  - app/javascript/controllers/turbo_frame_controller.js
- **学习要点**：
  - 添加了 turbo frame 加载状态
  - 使用 CSS 动画显示加载指示器
```

### 日志文件管理

1. **自动创建**：如果日志文件不存在，自动创建
2. **按日期分组**：commit 按日期分组，便于查看
3. **按时间倒序**：最新的 commit 在最前面
4. **避免重复**：检查 commit hash，避免重复记录

## 💡 使用示例

### 示例 1：首次学习

```
用户：/learn-fizzy-commits

AI 执行：
1. 检查或克隆 Fizzy 仓库：✅ 仓库不存在，自动克隆到 tmp/fizzy
2. 读取学习日志：❌ 文件不存在，创建新文件
3. 获取最新代码：✅ 拉取成功
4. 获取新 commit：✅ 获取最近 10 个 commit
5. 检查今天是否已学习：✅ 未学习，继续
6. 分析每个 commit：✅ 分析 10 个 commit
6.5. 智能辨识值得记录经验的 commit：✅ 识别出 3 个值得记录的 commit
7. 生成学习笔记：✅ 生成 10 个学习笔记
7.5. 检查并更新经验文档：
   - ✅ 更新 fizzy-code-style-guide.md（补充新的代码风格实践）
   - ✅ 创建 fizzy-new-feature.md（新功能设计模式）
   - ✅ 更新 fizzy-overview.md（添加新文档索引）
8. 更新日志文件：✅ 更新最后学习时间
9. 生成学习总结：✅ 显示总结报告（包含经验文档更新信息）
```

### 示例 2：每日学习（有新 commit）

```
用户：/learn-fizzy-commits

AI 执行：
1. 检查或克隆 Fizzy 仓库：✅ 仓库已存在 tmp/fizzy
2. 读取学习日志：✅ 最后学习时间：2025-12-07 10:30:00
3. 获取最新代码：✅ 拉取成功
4. 获取新 commit：✅ 获取 3 个新 commit（从 2025-12-07 之后）
5. 检查今天是否已学习：✅ 未学习，继续
6. 分析每个 commit：✅ 分析 3 个 commit
6.5. 智能辨识值得记录经验的 commit：✅ 识别出 2 个值得记录的 commit
   - Commit abc1234：优化 dialog 控制器性能（值得记录）
   - Commit def5678：修复 typo（不值得记录）
   - Commit ghi9012：新的 Turbo Frame 使用模式（值得记录）
7. 生成学习笔记：✅ 生成 3 个学习笔记
7.5. 检查并更新经验文档：
   - ✅ 更新 fizzy-dialog-turbo-frame.md（添加性能优化经验）
   - ✅ 更新 fizzy-hotwire-practices.md（添加新的 Turbo Frame 使用模式）
8. 更新日志文件：✅ 更新最后学习时间
9. 生成学习总结：✅ 显示总结报告（包含经验文档更新信息）
```

### 示例 3：今天已学习过

```
用户：/learn-fizzy-commits

AI 执行：
1. 检查或克隆 Fizzy 仓库：✅ 仓库已存在 tmp/fizzy
2. 读取学习日志：✅ 最后学习时间：2025-12-08 10:30:00
3. 检查今天是否已学习：❌ 今天已学习过
4. 提示用户：✅ "今天已经学习过了（最后学习时间：2025-12-08）"
5. 退出：✅ 不继续执行
```

### 示例 4：经验文档更新示例

```
用户：/learn-fizzy-commits

AI 执行：
...（前面的步骤）...

6.5. 智能辨识值得记录经验的 commit：
   - Commit abc1234：改进控制器参数处理方式
     * 分类：控制器设计
     * 相关文档：fizzy-controller-design.md
     * 判断：值得更新现有文档

7.5. 检查并更新经验文档：
   - 读取 fizzy-controller-design.md
   - 分析新经验与现有内容的关系
   - 决定在"参数处理"章节添加新内容
   - 更新文档：
     ```markdown
     ## 参数处理
     
     ### 从 Commit abc1234 学到的经验
     
     **时间**：2025-12-08
     **作者**：DHH
     **变更文件**：app/controllers/concerns/parameter_processing.rb
     
     新的参数处理方式：使用 `params.require().permit()` 的链式调用...
     
     **代码示例**：
     ```ruby
     # 新的方式
     params.require(:user).permit(:name, :email).merge(account: current_account)
     ```
     ```
   - ✅ 文档更新完成
```

## ⚠️ 重要规则

1. **每日一次**：一天只学习一次，通过日志文件避免重复学习
2. **自动检查**：自动检查今天是否已学习，避免重复
3. **记录历史**：记录所有学习过的 commit，便于后续查看
4. **学习要点**：重点学习代码变更背后的设计思路和最佳实践
5. **生成笔记**：为每个 commit 生成学习笔记，记录关键要点
6. **更新日志**：及时更新日志文件，记录最后学习时间
7. **智能辨识**：智能辨识哪些 commit 值得记录为经验文档
8. **经验管理**：对于值得记录的经验，检查是否需要更新现有文档或创建新文档
9. **敏感信息保护**：**必须**遵守敏感信息保护规则，确保不将敏感信息写入经验文档
10. **文档更新**：更新经验文档时，保持文档结构清晰，遵循现有文档格式
11. **总览更新**：如果创建了新文档，必须更新 `fizzy-overview.md` 添加索引

## 📚 相关资源

- [Fizzy 最佳实践学习总览](../docs/experiences/fizzy-overview.md) ⭐ **必读** - Fizzy 学习文档索引，包含所有经验文档的链接
- [Fizzy 学习日志](../docs/fizzy-learning-log.md) - 记录每日学习的新提交（不对外输出）
- [Fizzy 代码阅读指南](../docs/experiences/fizzy-code-reading-guide.md) - 系统化阅读指南
- [Fizzy 分析脚本](../script/analyze_fizzy.sh) - 项目结构分析脚本
- [Fizzy GitHub 仓库](https://github.com/basecamp/fizzy) - 官方仓库
- **经验文档目录**：`docs/experiences/` - 所有 Fizzy 学习经验文档

## 🔧 技术细节

### 获取新 Commit 的命令

```bash
cd tmp/fizzy

# 获取指定时间之后的 commit
git log --since="2025-12-07 10:30:00" --pretty=format:"%H|%an|%ad|%s" --date=format:"%Y-%m-%d %H:%M:%S"

# 获取最近 N 个 commit
git log -10 --pretty=format:"%H|%an|%ad|%s" --date=format:"%Y-%m-%d %H:%M:%S"

# 获取 commit 的变更文件
git show --name-status abc1234

# 获取 commit 的详细变更
git show abc1234

cd ../..
```

### 日志文件操作

```bash
# 读取最后学习时间
grep -A 1 "## 最后学习时间" docs/fizzy-learning-log.md | tail -1

# 更新最后学习时间（macOS）
sed -i '' "s/^## 最后学习时间$/## 最后学习时间\n\n$CURRENT_TIME/" docs/fizzy-learning-log.md

# 更新最后学习时间（Linux）
sed -i "s/^## 最后学习时间$/## 最后学习时间\n\n$CURRENT_TIME/" docs/fizzy-learning-log.md
```

---

**创建时间**：2025-12-08  
**指令类型**：学习指令  
**适用项目**：所有项目  
**相关文档**：`docs/fizzy-learning-log.md`（不对外输出）

