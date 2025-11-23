# 开发者指南

本文档记录项目的重要技术决策、架构设计和开发规范，供团队成员参考。

## 📚 目录

- [认证系统](#认证系统)
- [身份管理](#身份管理)
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

在控制器中使用：

```ruby
# 获取当前用户
current_user

# 检查用户是否已登录
user_signed_in?

# 要求用户登录（未登录会重定向）
authenticate_user!

# 要求用户未登录（已登录会重定向）
require_no_authentication
```

这些方法在 `ApplicationController` 中通过 Warden 实现。

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
  - `authenticate_user!` - 要求登录
  - `require_no_authentication` - 要求未登录
  - `current_user` - 当前用户
  - `user_signed_in?` - 是否已登录

### 安全规范

1. **密码加密**：始终使用 `has_secure_password`，不要手动处理密码
2. **CSRF 保护**：Rails 默认启用，API 需要特殊处理
3. **密码强度**：至少 8 位，包含字母和数字
4. **登录限制**：5 次失败后锁定账户 30 分钟
5. **HTTPS**：生产环境必须使用 HTTPS

## 🛠️ 技术栈决策

### 认证系统
- **Rails 8 Authentication Generator** - 基础认证功能
- **Warden** - 身份管理和认证策略
- **bcrypt** - 密码加密

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
   # 在控制器中
   current_user
   warden.user
   ```

## 🔗 相关资源

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Warden Documentation](https://github.com/wardencommunity/warden)
- [Rails Authentication Generator](https://guides.rubyonrails.org/security.html#authentication)
- [DaisyUI Documentation](https://daisyui.com/)

## 📅 更新日志

- **2024-XX-XX**：初始版本，确定使用 Rails 8 Authentication Generator 和 Warden

