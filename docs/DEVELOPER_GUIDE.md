# 开发者指南

本文档记录项目的重要技术决策、架构设计和开发规范，供团队成员参考。

## 📚 目录
`require_authentication` - 要求登录（通过 before_action）
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

项目使用 **SimpleCov** 进行测试覆盖率统计，要求**整体代码测试覆盖率至少达到 85%**。

**重要说明**：
- **85% 是整体项目的覆盖率要求**，不是每个文件都必须达到 100%
- 特定文件的 100% 覆盖率只是理想目标，不是强制要求
- 避免为了追求 100% 覆盖率而过度测试，导致项目开发停滞不前
- 应该关注核心业务逻辑的测试覆盖，而不是追求每个文件的完美覆盖率

**配置位置**：`test/test_helper.rb`（`minimum_coverage 85`）

**查看覆盖率报告**：

- **用户查看**：在浏览器中打开 HTML 报告
  ```bash
  # 运行测试后，打开覆盖率报告
  open coverage/index.html
  ```

- **AI 分析覆盖率数据**：读取 JSON 数据文件（AI 无法读取浏览器内容）
  ```bash
  # SimpleCov 生成的覆盖率数据文件
  coverage/.resultset.json    # 详细的覆盖率数据（每行代码的覆盖情况）
  coverage/.last_run.json      # 最后一次运行的元数据（整体覆盖率）
  ```
  
  **重要**：当需要分析覆盖率数据、找出需要测试的文件时，AI 应该：
  - ✅ 读取 `coverage/.resultset.json` 文件分析详细覆盖率数据
  - ✅ 读取 `coverage/.last_run.json` 文件获取整体覆盖率信息
  - ❌ 不要使用 `open coverage/index.html`（AI 无法读取浏览器内容）

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
- **Cloudflare** - CDN 和代理服务（支持真实 IP 地址获取）

## ☁️ Cloudflare 支持

项目集成了 `cloudflare-rails` Gem，用于在生产环境中正确处理通过 Cloudflare 代理的请求，确保能够获取真实的客户端 IP 地址。

### 为什么需要 Cloudflare 支持？

当应用部署在 Cloudflare 后面时，所有请求都会经过 Cloudflare 的代理服务器。这导致：
- `request.remote_ip` 返回的是 Cloudflare 的 IP，而不是真实客户端 IP
- 登录日志、审计日志等记录的 IP 地址不准确
- 无法正确识别用户的地理位置

### 解决方案

使用 `cloudflare-rails` Gem（版本 7.0.0+，支持 Rails 8.1+）：

1. **自动验证请求来源**：检查请求是否真的来自 Cloudflare IP 范围
2. **防止 IP 欺骗**：如果请求不是来自 Cloudflare，忽略 `CF-Connecting-IP` 头
3. **自动修复 IP 地址**：修复 `request.ip` 和 `request.remote_ip`，使其返回真实客户端 IP

### 配置

**Gemfile**（仅 production 环境）：

```ruby
group :production do
  gem "cloudflare-rails"
end
```

**生产环境配置**（`config/environments/production.rb`）：

```ruby
# Cloudflare Rails configuration
# See: https://github.com/modosc/cloudflare-rails
# The gem automatically fixes request.ip and request.remote_ip when using Cloudflare
# It verifies that requests come from Cloudflare IP ranges and extracts real IP from CF-Connecting-IP header
# Optional: configure cache expiration and timeout
config.cloudflare.expires_in = 12.hours  # default: 12.hours
config.cloudflare.timeout = 5.seconds     # default: 5.seconds
```

### 工作原理

1. **自动获取 Cloudflare IP 列表**：Gem 会定期从 Cloudflare 获取最新的 IPv4 和 IPv6 IP 地址列表
2. **缓存 IP 列表**：使用 Rails 缓存存储 IP 列表（需要配置 `cache_store`）
3. **验证请求来源**：检查 `REMOTE_ADDR` 是否在 Cloudflare IP 范围内
4. **提取真实 IP**：如果验证通过，从 `CF-Connecting-IP` 或 `X-Forwarded-For` 头中提取真实客户端 IP
5. **自动修复**：修复 `Rack::Request::Helpers` 和 `ActionDispatch::RemoteIP`，使 `request.ip` 和 `request.remote_ip` 返回真实 IP

### 使用方式

**无需修改代码**：Gem 会自动工作，所有使用 `request.remote_ip` 的地方都会自动返回真实客户端 IP：

```ruby
# 在控制器中（自动工作）
session_record = user.sign_in!(request.user_agent, request.remote_ip)

# 在模型中（自动工作）
AuditLog.log(
  user: current_user,
  action: :create,
  request: request  # request.remote_ip 会自动返回真实 IP
)
```

### 安全考虑

- **IP 验证**：只有来自 Cloudflare IP 范围的请求才会信任 `CF-Connecting-IP` 头
- **防止欺骗**：如果攻击者知道服务器真实 IP 并直接访问，无法伪造 `CF-Connecting-IP` 头
- **自动更新**：Cloudflare IP 列表会自动更新，确保始终使用最新的 IP 范围

### 前置条件

- **缓存存储**：必须配置 `cache_store`（项目使用 `solid_cache_store`，已满足要求）
- **生产环境**：Gem 仅在 `production` 环境加载（开发/测试环境不需要）

### 相关资源

- [cloudflare-rails GitHub](https://github.com/modosc/cloudflare-rails)
- [Cloudflare IP 地址列表](https://www.cloudflare.com/ips/)

## 📁 项目结构规范

### 第三方库文件存放位置

**重要规则**：所有从外部下载的第三方库文件（JavaScript、CSS 等）必须存放在 `vendor/` 目录下，而不是 `app/assets/` 目录。

> 📖 **详细规范**：请参考 [资源管理规则](../.cursor/rules/assets-management.mdc) ⭐

## 🔌 扩展机制

### 自动加载扩展模块

BuildX.work 提供了自动加载扩展模块的机制，允许子项目通过 Module/Concern 扩展基础设施功能。

#### 工作原理

扩展机制通过 `config/initializers/extensions.rb` 实现：

1. **使用 `config.to_prepare`**：确保开发环境中的代码重载正常工作
2. **自动检测扩展文件**：检查是否存在扩展模块文件
3. **动态加载**：使用 `require_dependency` 加载扩展模块
4. **自动包含**：使用 `class_eval` 和 `include` 将扩展模块包含到基础设施类中

#### 支持的扩展点

- **User 模型**：`app/models/concerns/user_extensions.rb` → `UserExtensions`
- **ApplicationController**：`app/controllers/concerns/application_controller_extensions.rb` → `ApplicationControllerExtensions`
- **ApplicationHelper**：`app/helpers/application_helper_extensions.rb` → `ApplicationHelperExtensions`
- **ApplicationMailer**：`app/mailers/concerns/mailer_extensions.rb` → `MailerExtensions`

#### 扩展示例

```ruby
# app/models/concerns/user_extensions.rb
module UserExtensions
  extend ActiveSupport::Concern

  included do
    has_many :workspaces, dependent: :destroy
  end
end
```

扩展模块会自动加载，无需手动引入。

#### 设计原则

1. **约定优于配置**：使用固定的文件位置和命名规范
2. **自动加载**：子项目只需创建扩展文件，无需额外配置
3. **开发友好**：支持开发环境的热重载
4. **向后兼容**：如果扩展文件不存在，不影响基础设施功能

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

# 用户查看覆盖率报告（在浏览器中打开）
bin/rails test
open coverage/index.html

# AI 分析覆盖率数据（读取 JSON 文件，不要使用 open 命令）
# coverage/.resultset.json - 详细覆盖率数据
# coverage/.last_run.json - 整体覆盖率信息

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

- **2025-11-26**：添加 Cloudflare 支持文档，说明如何使用 `cloudflare-rails` Gem 获取真实客户端 IP
- **2025-11-25**：添加第三方库文件存放规范，规定所有第三方库文件应存放在 `vendor/` 目录
- **2024-XX-XX**：初始版本，确定使用 Rails 8 Authentication Generator 和 Warden

