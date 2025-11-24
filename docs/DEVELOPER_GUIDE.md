# 开发者指南

本文档记录项目的重要技术决策、架构设计和开发规范，供团队成员参考。

## 📚 目录

- [认证系统](#认证系统)
- [身份管理](#身份管理)
- [权限系统](#权限系统) - [查看架构图](../phase-2-authorization/architecture.md) ⭐
- [API 认证策略](#api-认证策略)
- [开发规范](#开发规范)
- [技术栈决策](#技术栈决策)

## 🔐 认证系统

### Rails 8 Authentication Generator

我们使用 Rails 8.0+ 内置的 `authentication` generator 作为认证系统的基础。

**参考文档**：
- [Rails Security Guide - Authentication](https://guides.rubyonrails.org/security.html#authentication)

**使用方法**：
```bash
bin/rails generate authentication
```

**生成的内容**：
- User 模型（包含密码加密、邮箱确认、密码重置等）
- Authentication 控制器
- 相关的视图文件
- 数据库迁移
- 路由配置

**优势**：
- Rails 官方维护，与框架深度集成
- 遵循 Rails 最佳实践和安全标准
- 包含完整的安全功能（密码加密、CSRF 保护等）
- 代码简洁，易于理解和维护

### 认证功能特性

#### 已实现功能
- ✅ 邮箱注册/登录
- ✅ 密码加密（使用 bcrypt）
- ✅ 邮箱确认
- ✅ 密码重置
- ✅ 记住我功能
- ✅ 登录失败次数限制
- ✅ 账户锁定机制

#### 待实现功能
- [ ] 手机号注册/登录
- [ ] 双因素认证（2FA）
- [ ] OAuth 第三方登录
- [ ] 多设备登录管理
- [ ] 会话超时控制

## 👤 身份管理

### Warden 集成

我们使用 **Warden** 作为身份管理中间件，用于统一管理用户身份和认证策略。

**为什么选择 Warden**：
1. **策略模式**：支持多种认证策略（密码、Token、OAuth 等）
2. **可扩展性**：易于添加新的认证方式（API Token、JWT 等）
3. **统一接口**：为 Web 和 API 提供统一的身份管理接口
4. **灵活性**：可以同时支持多种认证方式

**相关文件**：
- `config/initializers/warden.rb` - Warden 配置
- `lib/warden/strategies/` - 认证策略实现
- `app/controllers/concerns/authenticatable.rb` - 认证相关辅助方法

### Warden 策略

#### 1. Password Strategy（密码策略）
用于传统的邮箱/密码登录。

**实现位置**：`lib/warden/strategies/password.rb`

**使用场景**：
- Web 端登录
- 邮箱/密码认证

#### 2. Token Strategy（Token 策略）
用于 API 认证，支持 Bearer Token。

**实现位置**：`lib/warden/strategies/token.rb`

**使用场景**：
- API 请求认证
- 移动应用认证
- 第三方集成

#### 3. OAuth Strategy（OAuth 策略）
用于第三方 OAuth 登录。

**实现位置**：`lib/warden/strategies/oauth.rb`

**使用场景**：
- GitHub 登录
- Google 登录
- 微信登录

### 身份获取方法

在控制器和视图中使用：

```ruby
# 获取当前用户（统一使用 Current.user）
Current.user

# 检查用户是否已登录（统一使用 authenticated?）
authenticated?

# 要求用户登录（未登录会重定向）
require_authentication  # 通过 before_action :require_authentication

# 要求用户未登录（已登录会重定向）
allow_unauthenticated_access  # 通过 allow_unauthenticated_access only: [:new, :create]
```

**统一数据源**：
- 所有身份相关数据都通过 `Current` 模型获取
- `Current.user` - 当前用户（通过 `Current.session.user` 委托）
- `Current.session` - 当前会话记录
- `authenticated?` - 检查是否已认证（检查 `Current.user.present?`）

这些方法在 `ApplicationController` 中通过 Warden 实现，Warden 的回调会自动设置 `Current.session`。

## 🔐 权限系统

### Action Policy

我们使用 [Action Policy](https://github.com/palkan/action_policy) Gem 作为权限策略框架。

**为什么选择 Action Policy**：
1. **成熟稳定**：由知名 Rails 开发者维护，在 Rails 社区广泛使用
2. **高性能**：通过缓存和优化，确保授权检查的高效执行
3. **灵活可测试**：使用 Policy 类定义权限规则，易于测试和维护
4. **Rails 友好**：与 Rails 深度集成，提供控制器和视图辅助方法
5. **可扩展**：支持复杂的权限逻辑，适应各种应用需求

**版本**：`~> 0.7.5`

**参考文档**：
- [Action Policy GitHub](https://github.com/palkan/action_policy)
- [Action Policy 文档](https://actionpolicy.evilmartians.io/)

### 权限系统架构

我们的权限系统采用以下架构：

1. **Action Policy**：使用 Policy 类定义权限规则（代码中定义）
2. **Role 模型**：管理角色（数据库中存储）
3. **角色判断**：在 Policy 类中通过角色判断权限（如：`user.has_role?(:admin)`）
4. **资源级权限**：在 Policy 类中实现细粒度权限控制

### Policy 类定义

为每个需要权限控制的资源创建对应的 Policy 类：

```ruby
# app/policies/user_policy.rb
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

### 在控制器中使用

```ruby
class UsersController < ApplicationController
  include ActionPolicy::Controller

  def update
    @user = User.find(params[:id])
    authorize! @user  # 自动调用 UserPolicy#update?
    
    # 更新逻辑
  end
end
```

### 在视图中使用

```erb
<% if allowed_to?(:update?, @user) %>
  <%= link_to "Edit", edit_user_path(@user) %>
<% end %>
```

### 角色系统

使用 Role 模型管理角色：

```ruby
# User 模型
has_many :user_roles
has_many :roles, through: :user_roles

def has_role?(role_name)
  roles.exists?(name: role_name)
end
```

### 相关文件

- `app/policies/` - Policy 类定义
- `app/models/role.rb` - Role 模型
- `app/models/user.rb` - User 模型（包含角色关联）

### 架构图

详细的权限系统架构图请查看：[权限系统架构图](../phase-2-authorization/architecture.md) ⭐

架构图包含：
- 系统架构概览
- 权限检查流程
- 数据模型关系
- 代码组织结构
- 权限检查示例
- 权限检查决策树

## 🌐 API 认证策略

### 设计目标

1. **统一接口**：Web 和 API 使用相同的身份管理机制
2. **多种认证方式**：支持 Token、JWT、OAuth 等
3. **易于扩展**：添加新的认证方式只需实现新的 Warden 策略

### Token 认证

**实现方式**：
- 使用 Warden Token Strategy
- Token 存储在 `api_tokens` 表中
- 支持 Token 过期和撤销

**使用示例**：
```ruby
# 生成 Token
user.generate_api_token!

# API 请求头
Authorization: Bearer <token>
```

### JWT 认证（未来）

**计划实现**：
- 使用 Warden JWT Strategy
- 支持刷新 Token
- 支持 Token 黑名单

## 📋 开发规范

### 代码组织

#### 模型层
- `app/models/user.rb` - 用户模型
- `app/models/concerns/` - 模型相关的 Concern

#### 控制器层
- `app/controllers/authentication_controller.rb` - 认证控制器（Rails generator 生成）
- `app/controllers/concerns/authenticatable.rb` - 认证相关辅助方法
- `app/controllers/api/` - API 控制器（使用 Token 认证）

#### 视图层
- `app/views/authentication/` - 认证相关视图
- 使用 DaisyUI 组件库

#### 配置层
- `config/initializers/warden.rb` - Warden 配置
- `config/routes.rb` - 路由配置

### 命名规范

- **路由**：使用 RESTful 风格
  - `GET /sign_in` - 登录页面
  - `POST /sign_in` - 处理登录
  - `DELETE /sign_out` - 登出
  - `GET /sign_up` - 注册页面
  - `POST /sign_up` - 处理注册

- **控制器方法**：
  - `require_authentication` - 要求登录（通过 before_action）
  - `allow_unauthenticated_access` - 允许未登录访问（通过类方法）
  - `Current.user` - 当前用户（统一数据源）
  - `authenticated?` - 是否已认证（helper_method）

### 安全规范

1. **密码加密**：始终使用 `has_secure_password`，不要手动处理密码
2. **CSRF 保护**：Rails 默认启用，API 需要特殊处理
3. **密码强度**：至少 8 位，包含字母和数字
4. **登录限制**：5 次失败后锁定账户 30 分钟
5. **HTTPS**：生产环境必须使用 HTTPS

### 测试规范

#### 测试覆盖率要求

项目使用 **SimpleCov** 进行测试覆盖率统计，要求代码测试覆盖率至少达到 **85%**。

**配置位置**：`test/test_helper.rb`

**查看覆盖率报告**：
```bash
# 运行测试后，打开覆盖率报告
open coverage/index.html
```

#### 指定文件覆盖率检查

支持通过环境变量 `COVERAGE_FILES` 指定只检查某些文件的测试覆盖率，这在开发特定功能时非常有用。

**使用方法**：

```bash
# 只检查单个文件
COVERAGE_FILES=app/models/user.rb bin/rails test test/models/user_test.rb

# 检查多个文件（用逗号分隔）
COVERAGE_FILES=app/models/user.rb,app/controllers/sessions_controller.rb bin/rails test

# 检查整个目录（使用部分路径匹配）
COVERAGE_FILES=app/models bin/rails test test/models/
```

**工作原理**：
- 当设置了 `COVERAGE_FILES` 环境变量时，SimpleCov 只会跟踪匹配的文件
- 如果没有设置环境变量，则使用默认行为（跟踪所有文件）
- 支持部分路径匹配，例如 `app/models` 会匹配 `app/models/` 下的所有文件

**使用场景**：
- 开发新功能时，只关注当前文件的覆盖率
- 调试特定文件的测试问题
- 提高测试运行效率（减少覆盖率计算时间）

## 🛠️ 技术栈决策

### 认证系统
- **Rails 8 Authentication Generator** - 基础认证功能
- **Warden** - 身份管理和认证策略
- **bcrypt** - 密码加密

### 权限系统
- **Action Policy** (~> 0.7.5) - 权限策略框架
- **Role 模型** - 角色管理

### 前端
- **DaisyUI** - UI 组件库
- **Tailwind CSS 4** - CSS 框架
- **Stimulus** - JavaScript 框架

### 数据库
- **SQLite3** - 开发/测试环境
- **PostgreSQL/MySQL** - 生产环境（可选）

### 部署
- **Kamal** - 部署工具
- **Docker** - 容器化
- **Let's Encrypt** - SSL 证书

## 📝 开发备忘

### 常用命令

```bash
# 生成认证系统
bin/rails generate authentication

# 运行迁移
bin/rails db:migrate

# 创建新的 Warden 策略
rails generate warden:strategy <strategy_name>

# 运行测试
bin/rails test

# 运行测试并查看覆盖率报告
bin/rails test
open coverage/index.html

# 只检查特定文件的覆盖率
COVERAGE_FILES=app/models/user.rb bin/rails test test/models/user_test.rb

# 检查多个文件的覆盖率
COVERAGE_FILES=app/models/user.rb,app/controllers/sessions_controller.rb bin/rails test
```

### 调试技巧

1. **查看 Warden 策略**：
   ```ruby
   # 在 Rails console 中
   Warden::Strategies.all
   ```

2. **测试认证**：
   ```ruby
   # 在测试中
   sign_in(user)
   sign_out
   ```

3. **查看当前用户**：
   ```ruby
   # 在控制器和视图中（统一使用 Current）
   Current.user
   Current.session
   
   # 在控制器中（直接访问 Warden）
   warden.user  # 返回 Session 对象
   ```

## 🔗 相关资源

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Warden Documentation](https://github.com/wardencommunity/warden)
- [Rails Authentication Generator](https://guides.rubyonrails.org/security.html#authentication)
- [Action Policy Documentation](https://actionpolicy.evilmartians.io/)
- [Action Policy GitHub](https://github.com/palkan/action_policy)
- [DaisyUI Documentation](https://daisyui.com/)

## 📅 更新日志

- **2024-XX-XX**：初始版本，确定使用 Rails 8 Authentication Generator 和 Warden

