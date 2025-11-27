# 重构指南

> 说明如何将现有项目重构为使用 BuildX.work 基础设施

## 📋 重构步骤

### 步骤 1：分析项目

1. **识别重复代码**：找出与基础设施重复的代码
   - 用户认证相关（User、Session、Authentication）
   - 密码重置相关（PasswordsController、PasswordsMailer）
   - 用户管理相关（UsersController）

2. **识别业务功能**：找出业务特定的功能
   - 业务模型（如 Workspace、Project）
   - 业务控制器（如 WorkspacesController）
   - 业务特定的 Webhook、API 等

3. **创建分析文档**：记录分析结果
   - 哪些代码需要删除
   - 哪些代码需要保留
   - 哪些功能需要扩展

### 步骤 2：备份代码

```bash
cd your-project
git checkout -b refactoring-backup
git add .
git commit -m "Backup before refactoring"
```

### 步骤 3：删除重复代码

删除以下类型的重复文件：

- **模型**：`app/models/user.rb`、`app/models/session.rb`、`app/models/current.rb`
- **控制器**：`app/controllers/sessions_controller.rb`、`app/controllers/users_controller.rb`、`app/controllers/passwords_controller.rb`
- **Concerns**：`app/controllers/concerns/authentication.rb`（如果基础设施已有）
- **Mailers**：`app/mailers/passwords_mailer.rb`（如果基础设施已有）
- **视图**：`app/views/sessions/`、`app/views/users/`、`app/views/passwords/`（如果基础设施已有）
- **测试**：`test/models/user_test.rb`、`test/controllers/users_controller_test.rb`（如果基础设施已有）

### 步骤 4：更新代码

1. **更新 ApplicationController**
   - 添加基础设施功能（ActionPolicy、错误处理等）
   - 移除安装检查（如果是业务项目）

2. **更新路由**
   - 添加基础设施路由（confirmations 等）
   - 保留业务路由

3. **更新 Fixtures**
   - 添加基础设施所需的字段（如 `confirmed_at`）

### 步骤 5：数据库迁移

创建迁移文件添加基础设施所需的字段和表：

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_infrastructure_fields_to_users.rb
class AddInfrastructureFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string unless column_exists?(:users, :name)
    add_column :users, :failed_login_attempts, :integer, default: 0 unless column_exists?(:users, :failed_login_attempts)
    # ... 其他字段
  end
end
```

### 步骤 6：创建扩展模块（如需要）

如果需要扩展基础设施功能：

```ruby
# app/models/concerns/user_extensions.rb
module UserExtensions
  extend ActiveSupport::Concern

  included do
    has_many :workspaces, dependent: :destroy
  end
end
```

### 步骤 7：测试

```bash
bin/rails db:migrate
bin/rails test
bin/dev
```

## ⚠️ 常见问题

### Q1: 如何处理数据库迁移冲突？

**A**: 
- 使用 `unless column_exists?` 和 `unless table_exists?` 检查
- 创建新的迁移文件，而不是修改现有迁移
- 测试迁移的向上和向下兼容性

### Q2: 视图文件如何处理？

**A**: 
- 如果基础设施已有视图，删除业务项目的视图
- 如果业务需要自定义视图，可以覆盖基础设施的视图
- 优先使用基础设施的视图（通常使用 DaisyUI，更完善）

### Q3: 如何扩展基础设施功能？

**A**: 
- 使用扩展模块（如 `UserExtensions`）
- 不要直接修改基础设施代码
- 扩展模块会自动加载

### Q4: 如何处理业务特定的认证逻辑？

**A**: 
- 在扩展模块中添加业务逻辑
- 使用 `ApplicationControllerExtensions` 添加业务特定的 before_action
- 使用 ActionPolicy 进行权限控制

## 📚 参考

- [使用指南](USAGE_GUIDE.md)
- [开发者指南](DEVELOPER_GUIDE.md)
- [子项目模板](../../../buildx.run/template-project/)

