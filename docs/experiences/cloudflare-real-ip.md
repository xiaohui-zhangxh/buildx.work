---
date: 2025-11-26
problem_type: 配置问题、Cloudflare、IP 地址
status: 已解决
---

# Cloudflare 真实 IP 地址获取

## 问题描述

当应用部署在 Cloudflare 后面时，所有请求都会经过 Cloudflare 的代理服务器，导致 `request.remote_ip` 返回的是 Cloudflare 的 IP 地址，而不是真实的客户端 IP 地址。

**影响**：
- 登录日志记录的 IP 地址不准确
- 审计日志记录的 IP 地址不准确
- 无法正确识别用户的地理位置
- 安全审计和日志分析困难

## 解决方案

使用 `cloudflare-rails` Gem（推荐方案）。

### 为什么选择 cloudflare-rails？

1. **安全性**：验证请求是否真的来自 Cloudflare IP 范围，防止 IP 欺骗攻击
2. **完整性**：同时修复 `request.ip` 和 `request.remote_ip`
3. **自动化**：自动获取并缓存 Cloudflare IP 列表
4. **成熟稳定**：313+ stars，持续维护，经过充分测试

### 实现步骤

#### 1. 添加 Gem

在 `Gemfile` 中添加（仅 production 环境）：

```ruby
group :production do
  gem "cloudflare-rails"
end
```

运行 `bundle install` 安装 Gem。

#### 2. 配置（可选）

在 `config/environments/production.rb` 中添加配置（可选）：

```ruby
# Cloudflare Rails configuration
# See: https://github.com/modosc/cloudflare-rails
config.cloudflare.expires_in = 12.hours  # default: 12.hours
config.cloudflare.timeout = 5.seconds     # default: 5.seconds
```

#### 3. 前置条件

确保已配置 `cache_store`（项目使用 `solid_cache_store`，已满足要求）：

```ruby
config.cache_store = :solid_cache_store
```

### 工作原理

1. **自动获取 IP 列表**：Gem 会定期从 Cloudflare 获取最新的 IPv4 和 IPv6 IP 地址列表
2. **缓存 IP 列表**：使用 Rails 缓存存储 IP 列表
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

## 安全考虑

### IP 欺骗攻击

如果攻击者知道服务器的真实 IP 地址，他们可能会：
1. 直接访问服务器（绕过 Cloudflare）
2. 伪造 `CF-Connecting-IP` 头
3. 伪装成其他用户的 IP 地址

### cloudflare-rails 的防护

`cloudflare-rails` Gem 通过以下方式防止 IP 欺骗：

1. **验证请求来源**：检查 `REMOTE_ADDR` 是否在 Cloudflare IP 范围内
2. **只信任 Cloudflare**：只有来自 Cloudflare IP 的请求才会信任 `CF-Connecting-IP` 头
3. **自动更新 IP 列表**：定期更新 Cloudflare IP 列表，确保始终使用最新的 IP 范围

## 测试

### 验证配置

在生产环境中，可以通过以下方式验证配置是否生效：

1. **查看日志**：检查登录日志中的 IP 地址是否为真实客户端 IP
2. **查看审计日志**：检查审计日志中的 IP 地址是否为真实客户端 IP
3. **使用 Rails Console**：

```ruby
# 在 Rails console 中
request = ActionDispatch::Request.new(env)
request.remote_ip  # 应该返回真实客户端 IP，而不是 Cloudflare IP
```

## 相关文件

- `Gemfile` - Gem 依赖配置
- `config/environments/production.rb` - 生产环境配置
- `docs/DEVELOPER_GUIDE.md` - 开发者指南（包含 Cloudflare 支持文档）

## 参考资料

- [cloudflare-rails GitHub](https://github.com/modosc/cloudflare-rails)
- [Cloudflare IP 地址列表](https://www.cloudflare.com/ips/)
- [Rails ActionDispatch::RemoteIP 文档](https://api.rubyonrails.org/classes/ActionDispatch/RemoteIP.html)

## 更新日志

- **2025-11-26**：初始版本，记录 Cloudflare 真实 IP 地址获取的解决方案

