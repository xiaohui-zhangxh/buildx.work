# 权限系统架构图

本文档通过架构图展示权限系统的整体设计和权限检查流程。

## 📊 系统架构概览

```mermaid
graph TB
    subgraph "用户层"
        User[User 模型<br/>用户信息]
    end
    
    subgraph "角色层"
        Role[Role 模型<br/>角色定义]
        UserRole[UserRole<br/>用户角色关联]
    end
    
    subgraph "权限策略层"
        ApplicationPolicy[ApplicationPolicy<br/>基础策略类]
        UserPolicy[UserPolicy<br/>用户权限策略]
        RolePolicy[RolePolicy<br/>角色权限策略]
        AdminPolicy[AdminPolicy<br/>管理后台权限策略]
    end
    
    subgraph "控制器层"
        Controller[Controller<br/>控制器]
        ActionPolicyController[ActionPolicy::Controller<br/>权限检查模块]
    end
    
    subgraph "视图层"
        View[View<br/>视图模板]
        ActionPolicyView[ActionPolicy::View<br/>视图权限辅助]
    end
    
    User -->|has_many| UserRole
    Role -->|has_many| UserRole
    UserRole -->|belongs_to| User
    UserRole -->|belongs_to| Role
    
    UserPolicy -->|继承| ApplicationPolicy
    RolePolicy -->|继承| ApplicationPolicy
    AdminPolicy -->|继承| ApplicationPolicy
    
    Controller -->|include| ActionPolicyController
    Controller -->|authorize!| UserPolicy
    Controller -->|authorize!| RolePolicy
    Controller -->|authorize!| AdminPolicy
    
    View -->|allowed_to?| UserPolicy
    View -->|allowed_to?| RolePolicy
    View -->|allowed_to?| AdminPolicy
    
    UserPolicy -->|检查| User
    UserPolicy -->|检查| Role
    RolePolicy -->|检查| User
    RolePolicy -->|检查| Role
    AdminPolicy -->|检查| User
    AdminPolicy -->|检查| Role
```

## 🔄 权限检查流程

```mermaid
sequenceDiagram
    participant User as 用户
    participant Controller as 控制器
    participant ActionPolicy as Action Policy
    participant Policy as Policy 类
    participant Role as Role 模型
    participant DB as 数据库

    User->>Controller: 发起请求
    Controller->>ActionPolicy: authorize! resource
    ActionPolicy->>Policy: 查找对应的 Policy 类
    Policy->>User: 获取当前用户 (Current.user)
    Policy->>Role: user.has_role?(:admin)
    Role->>DB: 查询用户角色
    DB-->>Role: 返回角色信息
    Role-->>Policy: 返回 true/false
    Policy->>Policy: 执行权限规则逻辑
    alt 权限通过
        Policy-->>ActionPolicy: 允许访问
        ActionPolicy-->>Controller: 继续执行
        Controller-->>User: 返回响应
    else 权限不足
        Policy-->>ActionPolicy: 抛出 Unauthorized 异常
        ActionPolicy-->>Controller: 捕获异常
        Controller-->>User: 返回 403 错误
    end
```

## 🏗️ 数据模型关系

```mermaid
erDiagram
    User ||--o{ UserRole : "has_many"
    Role ||--o{ UserRole : "has_many"
    UserRole }o--|| User : "belongs_to"
    UserRole }o--|| Role : "belongs_to"
    
    User {
        integer id
        string email
        string name
        datetime created_at
        datetime updated_at
    }
    
    Role {
        integer id
        string name
        text description
        datetime created_at
        datetime updated_at
    }
    
    UserRole {
        integer id
        integer user_id
        integer role_id
        datetime created_at
        datetime updated_at
    }
```

## 📁 代码组织结构

```
app/
├── models/
│   ├── user.rb              # User 模型（包含角色关联）
│   └── role.rb              # Role 模型
│
├── policies/
│   ├── application_policy.rb    # 基础 Policy 类
│   ├── user_policy.rb           # 用户权限策略
│   ├── role_policy.rb           # 角色权限策略
│   └── admin_policy.rb          # 管理后台权限策略
│
└── controllers/
    ├── application_controller.rb    # 包含 ActionPolicy::Controller
    ├── users_controller.rb           # 使用 authorize! 方法
    └── admin/
        ├── users_controller.rb       # 管理后台用户管理
        └── roles_controller.rb       # 管理后台角色管理

test/
├── policies/
│   ├── user_policy_test.rb      # Policy 类测试
│   └── role_policy_test.rb
└── models/
    ├── user_test.rb             # User 模型测试
    └── role_test.rb             # Role 模型测试
```

## 🔐 权限检查示例

### 1. 控制器中的权限检查

```ruby
class UsersController < ApplicationController
  include ActionPolicy::Controller

  def update
    @user = User.find(params[:id])
    authorize! @user  # 自动调用 UserPolicy#update?
    
    if @user.update(user_params)
      redirect_to @user
    else
      render :edit
    end
  end
end
```

### 2. Policy 类中的权限规则

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

### 3. 视图中的权限检查

```erb
<% if allowed_to?(:update?, @user) %>
  <%= link_to "Edit", edit_user_path(@user) %>
<% end %>

<% if allowed_to?(:destroy?, @user) %>
  <%= button_to "Delete", @user, method: :delete %>
<% end %>
```

## 🎯 权限检查决策树

```mermaid
graph TD
    Start[用户发起请求] --> CheckAuth{用户已登录?}
    CheckAuth -->|否| Redirect[重定向到登录页]
    CheckAuth -->|是| GetUser[获取当前用户]
    GetUser --> FindPolicy[查找对应的 Policy 类]
    FindPolicy --> CheckRole{检查用户角色}
    CheckRole -->|有 admin 角色| AllowAdmin[允许管理员操作]
    CheckRole -->|无 admin 角色| CheckResource{检查资源所有权}
    CheckResource -->|是资源所有者| AllowOwner[允许所有者操作]
    CheckResource -->|不是所有者| Deny[拒绝访问 403]
    AllowAdmin --> Success[操作成功]
    AllowOwner --> Success
    Deny --> Error[返回错误信息]
```

## 📋 角色与权限映射

| 角色 | 用户列表 | 查看用户 | 编辑用户 | 删除用户 | 管理角色 |
|------|---------|---------|---------|---------|---------|
| admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| user | ❌ | ✅ (自己) | ✅ (自己) | ❌ | ❌ |

## 🔗 相关文档

- [开发计划](./plan.md) - 详细的开发任务清单
- [开发笔记](./notes.md) - 技术决策和问题记录
- [阶段概览](./README.md) - 阶段目标和功能列表
- [开发者指南](../DEVELOPER_GUIDE.md) - 权限系统详细说明

