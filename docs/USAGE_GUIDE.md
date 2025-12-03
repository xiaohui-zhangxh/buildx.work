# BuildX.work 使用指南

> 详细说明如何使用 BuildX.work 作为基础设施模板创建和开发业务项目

## 📚 目录

1. [快速开始](#快速开始)
2. [创建新项目](#创建新项目)
3. [扩展基础设施功能](#扩展基础设施功能)
4. [更新基础设施](#更新基础设施)
5. [最佳实践](#最佳实践)
6. [常见问题](#常见问题)

---

## 快速开始

### 前置要求

- Ruby 3.3.5
- Bundler
- Node.js（用于 Tailwind CSS）
- SQLite3（开发/测试）
- Git

### 工作流程概览

```
1. Fork/Clone BuildX.work → 创建新项目
2. 通过 Module/Concern 扩展功能 → 添加业务逻辑
3. 定期 git merge 更新 → 同步基础设施更新
```

---

## 创建新项目

> 💡 **提示**：在创建新项目之前，建议先阅读 [新项目创建指南](PROJECT_CREATION_GUIDE.md)，了解完整的项目创建流程，包括项目规划、命名、技术选型等关键步骤。

### 方法一：Fork 方式（推荐）

如果你使用 GitHub/GitLab 等 Git 托管服务：

```bash
# 1. Fork buildx.work 仓库到你的账户
# 在 GitHub/GitLab 上点击 Fork 按钮

# 2. 克隆你的 Fork
git clone https://github.com/your-username/buildx.work.git my-new-project
cd my-new-project

# 3. 添加上游仓库（用于后续更新）
git remote add upstream https://github.com/xiaohui-zhangxh/buildx.work.git

# 4. 安装依赖
bundle install
npm install

# 5. 设置数据库
bin/rails db:setup

# 6. 启动开发服务器
bin/dev
```

### 方法二：Clone 方式（本地开发）

如果你在本地开发：

```bash
# 1. 克隆基础设施项目
git clone /path/to/buildx.work my-new-project
cd my-new-project

# 2. 初始化 Git 仓库（如果需要独立仓库）
rm -rf .git
git init
git add .
git commit -m "Initial commit from buildx.work"

# 3. 添加上游仓库（用于后续更新）
git remote add upstream /path/to/buildx.work

# 4. 安装依赖
bundle install
npm install

# 5. 设置数据库
bin/rails db:setup

# 6. 启动开发服务器
bin/dev
```

### 项目结构说明

创建新项目后，你会得到以下结构：

```
my-new-project/
├── app/
│   ├── models/
│   │   ├── user.rb              # 基础设施：用户模型
│   │   ├── concerns/            # 基础设施：Concern 模块
│   │   └── ...                  # 在这里添加你的业务模型
│   ├── controllers/
│   │   ├── application_controller.rb  # 基础设施：基础控制器
│   │   └── ...                  # 在这里添加你的业务控制器
│   └── ...
├── config/
│   └── initializers/
│       └── extensions.rb        # 扩展加载机制（自动创建）
└── ...
```

---

## 扩展基础设施功能

### 核心原则

**✅ 应该做的：**
- 通过 Module/Concern 扩展功能
- 在 `app/models/concerns/` 或 `app/controllers/concerns/` 中创建扩展模块
- 使用 `include` 引入扩展模块

**❌ 不应该做的：**
- 直接修改基础设施代码（如 `app/models/user.rb`）
- 在基础设施文件中添加业务逻辑
- 删除或重命名基础设施文件

### 扩展 User 模型

#### 1. 创建扩展模块

```ruby
# app/models/concerns/user_extensions.rb
module UserExtensions
  extend ActiveSupport::Concern

  included do
    # 添加业务特定的关联
    has_many :workspaces, dependent: :destroy
    has_many :ai_chats, dependent: :destroy
    
    # 添加业务特定的验证
    validates :business_field, presence: true
  end

  # 添加业务特定的方法
  def workspace_count
    workspaces.count
  end
end
```

#### 2. 自动加载扩展

扩展模块会自动加载（通过 `config/initializers/extensions.rb`），无需手动引入。

### 扩展 Controller

#### 1. 创建 Controller 扩展

```ruby
# app/controllers/concerns/application_controller_extensions.rb
module ApplicationControllerExtensions
  extend ActiveSupport::Concern

  included do
    # 添加业务特定的 before_action
    before_action :set_business_context
    
    # 添加业务特定的 helper_method
    helper_method :current_workspace
  end

  private

    def set_business_context
      # 业务逻辑
    end

    def current_workspace
      # 业务逻辑
    end
end
```

#### 2. 自动加载扩展

Controller 扩展也会自动加载。

### 扩展其他组件

#### 扩展 View Helper

```ruby
# app/helpers/application_helper_extensions.rb
module ApplicationHelperExtensions
  def business_specific_helper
    # 业务逻辑
  end
end
```

#### 扩展 Mailer

```ruby
# app/mailers/concerns/mailer_extensions.rb
module MailerExtensions
  extend ActiveSupport::Concern

  included do
    # 添加业务特定的邮件配置
    default from: 'business@example.com'
  end
end
```

### 扩展示例

查看 [子项目模板](../buildx.run/template-project/) 了解完整的扩展示例。

---

## 更新基础设施

> 💡 **重要**：详细的同步更新指南请参考 [同步更新指南](SYNC_UPDATES.md)，包括：
> - 如何检查基础平台更新
> - 如何同步更新到业务项目
> - 如何处理合并冲突
> - 如何验证更新结果
> - 最佳实践和常见问题

### 快速开始

当基础设施项目（buildx.work）有更新时，你需要同步到子项目：

```bash
# 1. 获取上游更新
git fetch upstream

# 2. 合并上游更新
git merge upstream/main

# 3. 解决冲突（如果有）
# 4. 测试应用
bin/rails test

# 5. 推送更新
git push
```

**详细流程和最佳实践**：请参考 [同步更新指南](SYNC_UPDATES.md)

---

## 最佳实践

### 1. 代码组织

```
app/
├── models/
│   ├── concerns/
│   │   ├── user_extensions.rb        # User 模型扩展
│   │   └── ...                       # 其他扩展
│   ├── business_model.rb            # 业务模型
│   └── ...
├── controllers/
│   ├── concerns/
│   │   └── application_controller_extensions.rb
│   ├── business_controller.rb       # 业务控制器
│   └── ...
└── ...
```

### 2. 命名规范

- **扩展模块**：使用 `*Extensions` 后缀（如 `UserExtensions`）
- **业务模型**：使用业务领域命名（如 `Workspace`、`Chat`）
- **业务控制器**：使用 RESTful 命名（如 `WorkspacesController`）

### 3. 功能提取

如果发现业务功能可以被多个项目复用：

1. **评估通用性**：是否真的通用？是否适合所有项目？
2. **提取到基础设施**：如果通用，提交 PR 到 buildx.work
3. **更新文档**：记录新功能的使用方法

### 4. 测试策略

- **基础设施功能**：由 buildx.work 维护测试
- **业务功能**：在你的项目中编写测试
- **集成测试**：测试基础设施和业务功能的集成

### 5. 版本管理

- **基础设施更新**：通过 `git merge` 同步
- **业务功能**：独立提交和版本管理
- **重大更新**：在合并前创建备份分支

---

## 常见问题

### Q1: 如何知道基础设施有更新？

**A**: 详细说明请参考 [同步更新指南](SYNC_UPDATES.md)。简要方法：

```bash
git fetch upstream
git log HEAD..upstream/main  # 查看新提交
```

或者关注 buildx.work 的 Release 和更新通知。

**完整指南**：请参考 [同步更新指南](SYNC_UPDATES.md) 了解如何检查更新、同步更新、处理冲突等。

### Q2: 合并冲突太多怎么办？

**A**: 
1. **使用扩展模块**：尽量通过 Module 扩展，而不是直接修改基础设施代码
2. **分批合并**：不要积累太多更新，定期合并
3. **创建备份**：合并前创建备份分支

### Q3: 可以修改基础设施代码吗？

**A**: 
- **开发环境**：可以临时修改用于测试
- **生产环境**：不推荐，修改会在下次更新时丢失
- **建议**：通过扩展模块或提交 PR 到基础设施项目

### Q4: 如何回退基础设施更新？

**A**: 

```bash
# 查看合并历史
git log --oneline --merges

# 回退到合并前
git revert -m 1 <merge-commit-hash>
```

### Q5: 扩展模块没有生效？

**A**: 检查以下几点：

1. **文件位置**：确保在 `app/models/concerns/` 或 `app/controllers/concerns/`
2. **命名规范**：确保模块名正确（如 `UserExtensions`）
3. **自动加载**：检查 `config/initializers/extensions.rb` 是否存在
4. **重启服务器**：开发环境需要重启才能加载新代码

### Q6: 如何贡献功能到基础设施？

**A**: 根据贡献内容，参考不同的文档：

**贡献修复（Bug Fix）**：
- 详细说明请参考 [贡献指南](CONTRIBUTING.md)
- 简要流程：
  1. 识别基础设施代码：确保修复属于基础设施，而非业务特定
  2. 创建修复分支：在 buildx.work 中创建修复分支
  3. 应用修复：使用 Git 补丁或手动复制修复
  4. 测试验证：运行测试确保修复正确
  5. 提交修复：提交清晰的提交信息
  6. 同步到子项目：修复合并后，同步到其他子项目

**贡献新功能（Feature）**：
- 详细说明请参考 [功能贡献指南](FEATURE_CONTRIBUTION.md) ⭐
- 简要流程：
  1. 识别可贡献代码：确保功能具有通用价值
  2. 提取和通用化：从业务代码中提取，移除业务特定逻辑
  3. 创建功能分支：在 buildx.work 中创建功能分支
  4. 测试验证：运行测试确保功能正确
  5. 提交功能：提交清晰的提交信息和使用说明
  6. 同步到子项目：功能合并后，同步到其他子项目

---

## 相关资源

- [新项目创建指南](PROJECT_CREATION_GUIDE.md) ⭐ - 完整的项目创建流程和检查清单
- [同步更新指南](SYNC_UPDATES.md) ⭐ - 如何同步基础平台更新到业务项目
- [开发者指南](DEVELOPER_GUIDE.md) - 技术决策和架构设计
- [贡献指南](CONTRIBUTING.md) - 如何将修复贡献回基础设施
- [功能贡献指南](FEATURE_CONTRIBUTION.md) ⭐ - 如何贡献新功能和通用代码
- [子项目模板](../../../buildx.run/template-project/) - 完整的项目模板和扩展示例
- [开发计划](DEVELOPMENT_PLAN.md) - 基础设施开发路线图

---

**最后更新**：2025-01-XX  
**维护者**：BuildX.work 团队

