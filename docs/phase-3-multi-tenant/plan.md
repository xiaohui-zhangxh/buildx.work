# 第三阶段开发计划

## 📋 阶段概览

本阶段将实现多租户支持，为系统提供完整的 SaaS 租户账号管理能力。参考 Basecamp Fizzy 项目的设计模式，实现 Account 模型、数据隔离、组织架构等功能。

## 🎯 主要目标

### 1. Account 模型（SaaS 租户账号）⭐
- 外部 ID（External ID）支持
- Slug 编码/解码
- JoinCode 加入码机制
- Current 对象管理
- 系统用户创建

### 2. 数据隔离 ⭐
- 所有模型关联到 Account
- 查询时自动过滤 Account
- 数据访问权限控制

### 3. URL 路由设计 ⭐
- 使用 script_name 作为 Account 标识
- 多租户 URL 结构（`/account-slug/resource`）
- 邮件 URL 生成支持

### 4. 组织架构（可选）
- 企业组织树形结构
- 部门管理
- 员工管理
- 组织架构可视化

## 📝 注意事项

- 需要基于第一、二阶段的认证和权限系统
- 数据隔离是关键，需要仔细设计
- 参考 Fizzy 项目的 Account 设计模式
- 需要考虑与现有权限系统的兼容性
- 组织架构可以后续扩展，不是核心功能

## 🗂️ 详细规划

### 第一部分：Account 模型基础

#### 1. 创建 Account 模型

- [ ] 创建 `Account` 模型和迁移
  - `name` (string) - 租户名称
  - `external_account_id` (string, unique, indexed) - 外部 ID（不使用数据库主键）
  - `description` (text, optional) - 租户描述
  - `timestamps`
- [ ] 创建 `ExternalIdSequence` 模型（用于生成外部 ID）
  - 使用序列号生成唯一的外部 ID
  - 参考 Fizzy 的 `ExternalIdSequence` 实现
- [ ] 实现 `AccountSlug` 编码/解码工具类
  - `AccountSlug.encode(external_account_id)` - 编码为 Slug
  - `AccountSlug.decode(slug)` - 解码为 external_account_id
  - 使用 Base64 URL 安全编码（或类似方案）

#### 2. Account 模型方法

- [ ] 实现 `slug` 方法
  ```ruby
  def slug
    "/#{AccountSlug.encode(external_account_id)}"
  end
  ```
- [ ] 实现 `create_with_owner` 工厂方法
  ```ruby
  class << self
    def create_with_owner(account:, owner:)
      create!(**account).tap do |account|
        account.users.create!(role: :system, name: "System")
        account.users.create!(**owner.reverse_merge(role: "owner", verified_at: Time.current))
      end
    end
  end
  ```
- [ ] 实现 `system_user` 方法
  ```ruby
  def system_user
    users.find_by!(role: :system)
  end
  ```
- [ ] 添加 `before_create` 回调：自动分配 `external_account_id`
- [ ] 添加验证：`name` 必须存在

#### 3. 更新 User 模型

- [ ] 添加 `belongs_to :account` 关联
- [ ] 更新用户创建逻辑：新用户必须关联到 Account
- [ ] 更新用户注册流程：支持创建新 Account 或加入现有 Account
- [ ] 添加 `role` 字段支持（owner、admin、member 等，与现有 Role 系统集成）

### 第二部分：Join Code 机制

#### 1. 创建 JoinCode 模型

- [ ] 创建 `JoinCode` 模型和迁移
  - `account_id` (references) - 关联的 Account
  - `code` (string, unique, indexed) - 加入码（如 "ABC123"）
  - `expires_at` (datetime, optional) - 过期时间
  - `max_uses` (integer, optional) - 最大使用次数
  - `uses_count` (integer, default: 0) - 已使用次数
  - `timestamps`
- [ ] 添加 `belongs_to :account` 关联
- [ ] 添加 `has_one :join_code` 到 Account 模型

#### 2. Join Code 生成和管理

- [ ] 实现 `after_create` 回调：自动创建 JoinCode
- [ ] 实现 `generate_code` 方法：生成唯一的加入码
  - 使用随机字符串（如 6-8 位字母数字组合）
  - 确保唯一性
- [ ] 实现 `valid?` 方法：检查加入码是否有效
  - 检查是否过期
  - 检查是否超过最大使用次数
- [ ] 实现 `use!` 方法：使用加入码（增加使用次数）

#### 3. 加入流程

- [ ] 创建 `JoinController`（或添加到 `AccountsController`）
  - `show` - 显示加入页面（通过 `/join/ABC123` 访问）
  - `create` - 处理加入请求（创建用户并关联到 Account）
- [ ] 创建加入视图
  - 显示 Account 信息
  - 显示加入表单（用户信息、密码等）
- [ ] 实现加入逻辑
  - 验证 JoinCode 有效性
  - 创建用户并关联到 Account
  - 使用 JoinCode（增加使用次数）
  - 自动登录用户

### 第三部分：Current 对象管理

#### 1. 扩展 Current 模型

- [ ] 添加 `account` 属性到 `Current` 模型
  ```ruby
  class Current < ActiveSupport::CurrentAttributes
    attribute :user
    attribute :session
    attribute :account  # 新增
  end
  ```

#### 2. 在控制器中设置 Current.account

- [ ] 创建 `SetCurrentAccount` concern
  - 从 URL 的 `script_name` 中提取 Account Slug
  - 解码 Slug 获取 `external_account_id`
  - 查找 Account 并设置 `Current.account`
- [ ] 在 `ApplicationController` 中包含 `SetCurrentAccount`
- [ ] 实现 Account 查找逻辑
  - 如果找不到 Account，返回 404 或重定向到创建 Account 页面
  - 如果用户没有权限访问该 Account，返回 403

#### 3. 在 Action Cable 中设置 Current.account

- [ ] 更新 `ApplicationCable::Connection`
  - 从请求中提取 Account 信息
  - 设置 `Current.account`
- [ ] 确保 WebSocket 连接时 Account 上下文正确

### 第四部分：数据隔离

#### 1. 更新所有模型关联到 Account

- [ ] 更新 `User` 模型：`belongs_to :account`
- [ ] 更新 `Role` 模型：`belongs_to :account`（可选，或使用全局角色）
- [ ] 更新 `AuditLog` 模型：`belongs_to :account`
- [ ] 更新 `SystemConfig` 模型：`belongs_to :account`（可选，或使用全局配置）
- [ ] 为所有模型添加 `default: -> { Current.account }` 或 `default: -> { parent.account }`

#### 2. 实现查询过滤

- [ ] 在模型中添加 `scope :for_account, ->(account) { where(account: account) }`
- [ ] 在控制器中使用 `Current.account` 过滤查询
  ```ruby
  def set_user
    @user = Current.account.users.find(params[:id])
  end
  ```
- [ ] 确保所有查询都自动过滤 Account

#### 3. 权限系统集成

- [ ] 更新 Policy 类：考虑 Account 上下文
  - `UserPolicy`：用户只能访问同一 Account 的资源
  - `AccountPolicy`：Account 管理权限
- [ ] 更新权限检查逻辑：确保跨 Account 访问被拒绝

### 第五部分：URL 路由设计

#### 1. 路由配置

- [ ] 配置路由支持 `script_name`
  - 使用 Rails 的 `script_name` 功能
  - 在中间件中提取 Account Slug
- [ ] 实现路由解析器
  - 从 URL 中提取 Account Slug
  - 设置 `script_name` 到请求环境

#### 2. URL 生成

- [ ] 更新 `ApplicationMailer` 的 `default_url_options`
  ```ruby
  def default_url_options
    if Current.account
      super.merge(script_name: Current.account.slug)
    else
      super
    end
  end
  ```
- [ ] 确保所有 URL 辅助方法自动包含 Account Slug

#### 3. 多租户 URL 结构

- [ ] URL 结构：`/account-slug/resource`
  - `/account-slug/users`
  - `/account-slug/roles`
  - `/account-slug/admin`
- [ ] 实现 Account 切换功能（如果用户属于多个 Account）

### 第六部分：Account 管理界面

#### 1. Account 创建

- [ ] 创建 `AccountsController`
  - `new` - 显示创建 Account 表单
  - `create` - 创建 Account 和 Owner
- [ ] 创建 Account 创建视图
  - Account 信息表单
  - Owner 用户信息表单
- [ ] 实现创建逻辑
  - 使用 `Account.create_with_owner` 工厂方法
  - 自动创建系统用户
  - 自动创建 JoinCode

#### 2. Account 管理（可选）

- [ ] 在管理后台添加 Account 管理
  - Account 列表
  - Account 详情
  - Account 编辑
- [ ] 实现 Account 切换功能
  - 如果用户属于多个 Account，显示切换菜单
  - 切换 Account 时更新 `Current.account`

### 第七部分：测试

#### 1. 模型测试

- [ ] Account 模型测试
  - 外部 ID 自动分配
  - Slug 生成
  - `create_with_owner` 工厂方法
  - 系统用户创建
- [ ] JoinCode 模型测试
  - 代码生成
  - 有效性检查
  - 使用计数
- [ ] ExternalIdSequence 测试
  - 序列号生成
  - 唯一性保证

#### 2. 控制器测试

- [ ] AccountsController 测试
  - Account 创建
  - Owner 创建
- [ ] JoinController 测试
  - 加入码验证
  - 用户加入流程
- [ ] 数据隔离测试
  - 确保用户只能访问自己 Account 的数据
  - 跨 Account 访问被拒绝

#### 3. 集成测试

- [ ] 多租户 URL 路由测试
- [ ] Current.account 设置测试
- [ ] 邮件 URL 生成测试
- [ ] 权限系统集成测试

### 第八部分：文档更新

- [ ] 更新 `engines/buildx_core/README.md`，标记已完成的功能
- [ ] 更新 `docs/DEVELOPER_GUIDE.md`，添加多租户系统的说明
- [ ] 更新 `docs/FEATURES.md`，标记完成的功能
- [ ] 创建多租户系统使用文档

## 🎨 UI/UX 设计要点

### Account 创建页面
1. **清晰的表单结构**：Account 信息和 Owner 信息分开
2. **友好的错误提示**：验证失败时显示具体错误
3. **成功反馈**：创建成功后自动登录并跳转到 Account 首页

### 加入页面
1. **Account 信息展示**：显示要加入的 Account 名称和描述
2. **简化的注册流程**：只需填写必要信息
3. **加入码验证**：实时验证加入码有效性

### Account 切换（如果支持）
1. **清晰的切换菜单**：显示用户所属的所有 Account
2. **当前 Account 标识**：明确显示当前使用的 Account
3. **快速切换**：一键切换 Account

## 📅 开发顺序建议

1. **第一步**：创建 Account 模型基础
   - 创建 Account 模型和迁移
   - 实现外部 ID 和 Slug
   - 实现 `create_with_owner` 工厂方法

2. **第二步**：实现 Join Code 机制
   - 创建 JoinCode 模型
   - 实现加入流程
   - 创建加入页面

3. **第三步**：扩展 Current 对象
   - 添加 `account` 属性
   - 实现 `SetCurrentAccount` concern
   - 在控制器和 Action Cable 中设置

4. **第四步**：实现数据隔离
   - 更新所有模型关联到 Account
   - 实现查询过滤
   - 更新权限系统

5. **第五步**：实现 URL 路由
   - 配置路由支持 `script_name`
   - 更新 URL 生成
   - 实现多租户 URL 结构

6. **第六步**：创建 Account 管理界面
   - Account 创建页面
   - Account 管理（可选）

7. **第七步**：完善测试和文档
   - 模型测试
   - 控制器测试
   - 集成测试
   - 更新文档

## 🔗 相关文档

- [开发者指南](../DEVELOPER_GUIDE.md)
- [第二阶段文档](../phase-2-authorization/README.md)
- [功能清单](../FEATURES.md)
- [Fizzy SaaS 多租户 Account 设计](../experiences/fizzy-saas-account-design.md) ⭐
- [Fizzy 最佳实践学习总览](../experiences/fizzy-overview.md)

## 📚 参考实现

### Fizzy 项目参考

- **Account 模型**：参考 `app/models/account.rb`
- **ExternalIdSequence**：参考 `app/models/external_id_sequence.rb`
- **AccountSlug**：参考 `app/models/account_slug.rb`
- **JoinCode**：参考 `app/models/join_code.rb`
- **Current 对象**：参考 `app/models/current.rb`
- **路由设计**：参考 `config/routes.rb` 和 `ApplicationMailer`

### 关键设计模式

1. **外部 ID**：使用 `external_account_id` 而不是数据库主键
2. **Slug 编码**：使用 Base64 URL 安全编码（或类似方案）
3. **系统用户**：每个 Account 创建一个系统用户
4. **工厂方法**：使用 `create_with_owner` 创建 Account
5. **数据隔离**：所有模型关联到 Account，查询时自动过滤
6. **Current 对象**：使用 `Current.account` 管理当前租户
7. **URL 路由**：使用 `script_name` 作为 Account 标识

## ⚠️ 注意事项

1. **向后兼容**：需要考虑现有用户和数据的迁移
2. **性能优化**：Account 过滤可能影响查询性能，需要添加索引
3. **安全性**：确保数据隔离的完整性，防止跨 Account 访问
4. **测试覆盖**：多租户功能需要充分的测试覆盖
5. **文档完善**：多租户系统比较复杂，需要详细的文档说明
