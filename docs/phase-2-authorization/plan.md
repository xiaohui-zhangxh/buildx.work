# 第二阶段开发计划

## 📋 阶段概览

本阶段将实现权限系统和**管理后台**，为系统提供完整的用户、角色、权限管理能力。

## 🎯 主要目标

### 1. 权限系统
- 角色管理系统（RBAC）
- 权限控制系统
- 资源级权限

### 2. 管理后台 ⭐
- 用户管理界面
- 角色和权限管理界面
- 系统配置管理
- 操作日志查看
- 数据统计和监控

## 📝 注意事项

- 需要基于第一阶段的认证系统
- 需要考虑与多租户系统的兼容性
- 权限系统需要灵活且易于扩展
- **管理后台需要完整的权限控制**：只有管理员才能访问

## 🗂️ 详细规划

### 第一部分：权限系统基础

#### 1. 安装和配置 Action Policy ⭐
使用 [Action Policy](https://github.com/palkan/action_policy) Gem 作为权限策略框架：

- [ ] 在 `Gemfile` 中添加 Action Policy
  ```ruby
  gem "action_policy", "~> 0.7.5"  # 使用最新稳定版本
  ```
- [ ] 运行 `bundle install`
- [ ] 运行生成器安装 Action Policy
  ```bash
  bin/rails generate action_policy:install
  ```
- [ ] 配置 `ApplicationPolicy`（生成器会自动创建）
  - 设置默认的 `user` 方法（从 `Current.user` 获取）
  - 配置权限检查失败时的处理

#### 2. 角色模型设计
- [ ] 创建 `Role` 模型
  - `name` (string, unique) - 角色名称（如：`admin`, `user`, `manager`）
  - `description` (text) - 角色描述
  - `timestamps`
- [ ] 创建 `user_roles` 关联表（多对多）
  - `user_id` (references)
  - `role_id` (references)
  - `timestamps`
- [ ] 在 `User` 模型中添加角色关联
  ```ruby
  has_many :user_roles
  has_many :roles, through: :user_roles
  
  def has_role?(role_name)
    roles.exists?(name: role_name)
  end
  ```

#### 3. 创建 Policy 类
使用 Action Policy 的 Policy 类来定义权限规则：

- [ ] 创建 `ApplicationPolicy`（生成器会自动创建）
  ```ruby
  class ApplicationPolicy < ActionPolicy::Base
    # 默认用户从 Current.user 获取
    def user
      context[:user] || Current.user
    end
    
    # 默认拒绝所有操作（最小权限原则）
    default_rule :manage? => false
  end
  ```

- [ ] 创建资源相关的 Policy 类
  - `UserPolicy` - 用户资源权限
  - `RolePolicy` - 角色资源权限
  - `AdminPolicy` - 管理后台权限
  - 其他资源的 Policy 类

- [ ] 在 Policy 类中使用角色判断
  ```ruby
  class UserPolicy < ApplicationPolicy
    def index?
      user.has_role?(:admin)
    end
    
    def show?
      user.has_role?(:admin) || user == record
    end
    
    def update?
      user.has_role?(:admin) || user == record
    end
    
    def destroy?
      user.has_role?(:admin)
    end
  end
  ```

#### 4. 权限系统设计
结合 Action Policy 和角色系统：

- [ ] 在 `User` 模型中添加权限检查辅助方法
  ```ruby
  def can?(action, record = nil)
    ActionPolicy.lookup(record).new(record, user: self).public_send("#{action}?")
  rescue ActionPolicy::Unauthorized
    false
  end
  ```

- [ ] 实现资源级权限控制
  - 在 Policy 类中实现细粒度权限检查
  - 支持基于资源属性的权限判断（如：只能编辑自己的资源）

#### 5. 控制器权限控制
使用 Action Policy 提供的控制器方法：

- [ ] 在 `ApplicationController` 中引入 Action Policy
  ```ruby
  include ActionPolicy::Controller
  ```

- [ ] 在控制器中使用 `authorize!` 方法
  ```ruby
  class UsersController < ApplicationController
    def update
      @user = User.find(params[:id])
      authorize! @user  # 自动调用 UserPolicy#update?
      
      # 更新逻辑
    end
  end
  ```

- [ ] 在视图中使用 `allowed_to?` 方法
  ```erb
  <% if allowed_to?(:update?, @user) %>
    <%= link_to "Edit", edit_user_path(@user) %>
  <% end %>
  ```

- [ ] 实现权限不足时的错误处理
  - 配置 `ActionPolicy::Unauthorized` 异常处理
  - 返回友好的错误提示（403 页面或 JSON 错误）

### 第二部分：管理后台 ⭐

#### 1. 管理后台路由和命名空间
- [ ] 创建 `Admin` 命名空间
- [ ] 配置管理后台路由
  ```ruby
  namespace :admin do
    root 'dashboard#index'
    resources :users
    resources :roles
    resources :policies, only: [:index, :show]  # Policy 类说明（只读）
    resources :system_configs
    resources :audit_logs
  end
  ```

#### 2. 管理后台布局
- [ ] 创建 `app/views/layouts/admin.html.erb`
- [ ] 使用 DaisyUI 设计侧边栏导航
- [ ] 实现响应式设计（移动端适配）
- [ ] 添加用户信息显示和退出登录

#### 3. 用户管理界面
- [ ] `Admin::UsersController`
  - `index` - 用户列表（支持搜索、筛选、分页）
  - `show` - 用户详情
  - `edit` - 编辑用户
  - `update` - 更新用户
  - `destroy` - 删除用户（软删除）
  - `activate` - 激活用户
  - `deactivate` - 禁用用户
- [ ] 用户列表视图
  - 表格展示用户信息
  - 搜索功能（邮箱、姓名）
  - 筛选功能（状态、角色）
  - 分页功能
  - 批量操作（批量激活/禁用）
- [ ] 用户详情视图
  - 基本信息展示
  - 角色列表
  - 操作历史
- [ ] 用户编辑视图
  - 表单编辑
  - 角色分配
  - 状态管理

#### 4. 角色管理界面
- [ ] `Admin::RolesController`
  - `index` - 角色列表
  - `show` - 角色详情
  - `new` - 创建角色
  - `create` - 保存角色
  - `edit` - 编辑角色
  - `update` - 更新角色
  - `destroy` - 删除角色
- [ ] 角色列表视图
  - 表格展示角色信息
  - 角色描述
  - 关联用户数量
- [ ] 角色表单视图
  - 角色基本信息（名称、描述）
  - 角色权限说明（显示该角色在 Policy 类中的权限）

#### 5. 权限管理界面（Policy 类说明）
- [ ] `Admin::PoliciesController`（只读，展示 Policy 类信息）
  - `index` - Policy 类列表
  - `show` - Policy 类详情（显示所有规则）
- [ ] Policy 列表视图
  - 按资源分组（UserPolicy、RolePolicy 等）
  - 显示每个 Policy 类的规则列表
  - 权限说明和用途
- [ ] Policy 详情视图
  - 显示 Policy 类的所有规则
  - 规则说明（哪些角色可以执行哪些操作）
  - 代码示例

#### 6. 系统配置管理
- [ ] 创建 `SystemConfig` 模型
  - `key` (string, unique) - 配置键
  - `value` (text) - 配置值
  - `description` (text) - 配置说明
  - `category` (string) - 配置分类
- [ ] `Admin::SystemConfigsController`
  - `index` - 配置列表（按分类分组）
  - `edit` - 编辑配置
  - `update` - 更新配置
- [ ] 配置管理视图
  - 分类展示
  - 表单编辑
  - 配置说明

#### 7. 操作日志（审计日志）
- [ ] 创建 `AuditLog` 模型
  - `user_id` (references) - 操作用户
  - `action` (string) - 操作类型
  - `resource_type` (string) - 资源类型
  - `resource_id` (integer) - 资源ID
  - `changes` (json) - 变更内容
  - `ip_address` (string) - IP地址
  - `user_agent` (text) - 用户代理
  - `timestamps`
- [ ] `Admin::AuditLogsController`
  - `index` - 日志列表（支持搜索、筛选、分页）
  - `show` - 日志详情
- [ ] 日志列表视图
  - 表格展示
  - 搜索功能（用户、操作、资源）
  - 筛选功能（时间范围、操作类型）
  - 分页功能
- [ ] 日志详情视图
  - 完整操作信息
  - 变更对比（before/after）

#### 8. 管理后台仪表盘
- [ ] `Admin::DashboardController`
  - `index` - 仪表盘首页
- [ ] 仪表盘视图
  - 统计卡片（用户总数、角色数、今日操作数等）
  - 图表展示（用户增长趋势、操作统计等）
  - 最近操作列表
  - 系统状态监控

### 第三部分：权限集成

#### 1. 权限检查集成
- [ ] 在管理后台控制器中添加权限检查
- [ ] 实现权限不足时的错误处理
- [ ] 添加权限检查的测试

#### 2. 视图权限控制
- [ ] 实现视图级别的权限检查
- [ ] 根据权限显示/隐藏功能按钮
- [ ] 实现权限不足时的友好提示

### 第四部分：测试

#### 1. 模型测试
- [ ] Role 模型测试
  - 角色名称唯一性验证
  - 角色描述验证
- [ ] UserRole 关联测试
  - 用户角色关联
  - 用户多角色支持
- [ ] User 模型权限检查测试
  - `has_role?` 方法测试
  - `can?` 方法测试（结合 Action Policy）

#### 2. Policy 类测试
- [ ] ApplicationPolicy 测试
  - 默认规则测试
- [ ] UserPolicy 测试
  - `index?` 规则测试
  - `show?` 规则测试
  - `update?` 规则测试
  - `destroy?` 规则测试
  - 不同角色的权限测试
- [ ] RolePolicy 测试
- [ ] AdminPolicy 测试
- [ ] 其他资源 Policy 测试

#### 3. 控制器测试
- [ ] Admin::UsersController 测试
  - 权限检查测试（使用 Action Policy）
  - 不同角色的访问权限测试
- [ ] Admin::RolesController 测试
  - 权限检查测试
- [ ] Admin::PoliciesController 测试
  - 只读访问测试
- [ ] Admin::SystemConfigsController 测试
- [ ] Admin::AuditLogsController 测试
- [ ] Admin::DashboardController 测试
- [ ] Action Policy 集成测试
  - `authorize!` 方法测试
  - `allowed_to?` 方法测试
  - 权限不足时的异常处理测试

#### 4. 系统测试
- [ ] 管理后台访问流程测试
- [ ] 用户管理流程测试（不同角色的权限测试）
- [ ] 角色管理流程测试
- [ ] Action Policy 权限控制测试
  - 不同角色访问不同资源的测试
  - 权限不足时的错误提示测试

### 第五部分：文档更新

- [ ] 更新 `engines/buildx_core/README.md`，标记已完成的功能
- [ ] 更新 DEVELOPER_GUIDE.md，添加权限系统和管理后台的说明
- **注意**：根目录 `README.md` 只做简单介绍和链接，详细文档在 `engines/buildx_core/README.md`
- [ ] 更新 FEATURES.md，标记完成的功能
- [ ] 添加管理后台使用文档

## 🎨 UI/UX 设计要点

### 管理后台设计原则
1. **清晰的信息架构**：侧边栏导航，面包屑导航
2. **高效的操作流程**：批量操作、快速筛选、快捷键支持
3. **友好的错误提示**：权限不足、操作失败等场景
4. **响应式设计**：支持桌面端和移动端访问
5. **数据可视化**：使用图表展示统计数据

### DaisyUI 组件使用
- **侧边栏**：使用 `drawer` 或 `menu` 组件
- **表格**：使用 `table` 组件
- **表单**：使用 `form` 和 `input` 组件
- **按钮**：使用 `btn` 组件
- **卡片**：使用 `card` 组件展示统计信息
- **模态框**：使用 `modal` 组件进行确认操作

## 📅 开发顺序建议

1. **第一步**：安装和配置 Action Policy
   - 添加 Gem 依赖
   - 运行生成器安装
   - 配置 ApplicationPolicy

2. **第二步**：实现角色系统基础
   - 创建 Role 模型和关联
   - 在 User 模型中添加角色方法
   - 创建基础 Policy 类（UserPolicy、RolePolicy 等）

3. **第三步**：实现权限检查
   - 在控制器中集成 Action Policy
   - 实现权限检查逻辑
   - 添加权限不足时的错误处理

4. **第四步**：创建管理后台基础架构
   - 创建 Admin 命名空间和路由
   - 创建管理后台布局
   - 集成权限检查

5. **第五步**：实现用户管理界面
   - 用户列表、详情、编辑
   - 角色分配功能
   - 权限检查

6. **第六步**：实现角色管理界面
   - 角色列表、创建、编辑
   - 权限说明展示

7. **第七步**：实现系统配置和日志管理
   - 系统配置管理
   - 操作日志查看

8. **第八步**：实现仪表盘
   - 数据统计
   - 图表展示

9. **第九步**：完善测试和文档
   - Policy 类测试
   - 控制器测试
   - 系统测试
   - 更新文档

## 🔗 相关文档

- [开发者指南](../DEVELOPER_GUIDE.md)
- [第一阶段文档](../phase-1-authentication/README.md)
- [功能清单](../FEATURES.md)

