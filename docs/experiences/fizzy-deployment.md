---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、部署配置
status: 已完成
tags: Fizzy、部署、Kamal、配置、SQLite、MySQL
description: 总结从 Basecamp Fizzy 项目学习到的部署和配置方式，包括 Kamal 部署配置、环境变量、数据库设置等
---

# Fizzy 部署和配置

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的部署和配置方式。Fizzy 使用 Kamal 进行部署，支持 SQLite 和 MySQL。

## 1. 应用配置

### 1.1 Application 配置

```ruby
module Fizzy
  class Application < Rails::Application
    config.load_defaults 8.1

    # 包含 lib 目录到自动加载路径
    config.autoload_lib ignore: %w[ assets tasks rails_ext ]

    # 启用调试模式用于 Rails 事件日志
    config.after_initialize do
      Rails.event.debug_mode = true
    end

    # 为新表使用 UUID 主键
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.mission_control.jobs.http_basic_auth_enabled = false
  end
end
```

**关键点**：
- 使用 UUID 作为主键（所有新表）
- 启用事件日志调试模式
- 自定义自动加载路径
- 配置 Mission Control Jobs

### 1.2 Application Controller

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include BlockSearchEngineIndexing
  include CurrentRequest, CurrentTimezone, SetPlatform
  include RequestForgeryProtection
  include TurboFlash, ViewTransitions
  include RoutingHeaders

  etag { "v1" }
  stale_when_importmap_changes
  allow_browser versions: :modern
end
```

**关键点**：
- 使用 Concerns 组织共享逻辑
- 启用 ETag 缓存
- 支持现代浏览器
- 阻止搜索引擎索引

## 2. Kamal 部署

### 2.1 部署配置

**config/deploy.yml 配置：**

```yaml
# About your deployment
servers:
  web:
    host: your-server.com

ssh:
  user: root

proxy:
  ssl: true
  host: your-server.com

env:
  clear:
    MAILER_FROM_ADDRESS: noreply@your-server.com
```

**关键配置**：
- `servers/web`：部署服务器地址
- `ssh/user`：SSH 用户
- `proxy/ssl`：是否启用 SSL
- `proxy/host`：代理主机
- `env/clear`：环境变量

### 2.2 环境变量管理

**使用 `.kamal/secrets` 管理密钥：**

```ini
SECRET_KEY_BASE=...
VAPID_PUBLIC_KEY=...
VAPID_PRIVATE_KEY=...
SMTP_USERNAME=...
SMTP_PASSWORD=...
```

**重要**：
- 不要将 `.kamal/secrets` 提交到 git
- 添加到 `.gitignore`
- 使用密码管理器（如 1Password）存储密钥

### 2.3 部署命令

**首次部署：**

```bash
bin/kamal setup
```

**后续部署：**

```bash
bin/kamal deploy
```

## 3. 数据库配置

### 3.1 多数据库支持

**支持 SQLite 和 MySQL：**

```bash
# 默认使用 SQLite
bin/setup

# 使用 MySQL
DATABASE_ADAPTER=mysql bin/setup --reset
DATABASE_ADAPTER=mysql bin/ci
```

**配置方式**：

```ruby
# lib/fizzy.rb
def db_adapter
  @db_adapter ||= DbAdapter.new ENV.fetch("DATABASE_ADAPTER", saas? ? "mysql" : "sqlite")
end
```

### 3.2 UUID 主键

**所有新表使用 UUID 主键：**

```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

**好处**：
- 隐藏内部 ID
- 提高安全性
- 支持分布式系统

### 3.3 数据库适配器

**DbAdapter 类：**

```ruby
class DbAdapter
  def initialize(name)
    @name = name.to_s
  end

  def to_s
    @name
  end

  def sqlite?
    @name == "sqlite"
  end
end
```

## 4. 邮件配置

### 4.1 生产环境配置

**config/environments/production.rb：**

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.example.com",
  port: 587,
  domain: "your-domain.com",
  user_name: ENV["SMTP_USERNAME"],
  password: ENV["SMTP_PASSWORD"],
  authentication: :plain,
  enable_starttls_auto: true
}
```

**关键点**：
- 使用环境变量存储凭证
- 支持 STARTTLS
- 配置发件人地址

### 4.2 邮件预览

**开发环境邮件预览：**

访问 `http://fizzy.localhost:3006/rails/mailers` 查看邮件预览。

**启用/禁用 letter_opener：**

```bash
bin/rails dev:email
```

## 5. 环境变量

### 5.1 必需的环境变量

- `SECRET_KEY_BASE`：Rails 密钥
- `VAPID_PUBLIC_KEY`：Web Push 公钥
- `VAPID_PRIVATE_KEY`：Web Push 私钥
- `SMTP_USERNAME`：SMTP 用户名
- `SMTP_PASSWORD`：SMTP 密码
- `MAILER_FROM_ADDRESS`：发件人地址

### 5.2 可选的环境变量

- `DATABASE_ADAPTER`：数据库适配器（sqlite/mysql）
- `CSP_REPORT_URI`：CSP 报告 URI
- `CSP_REPORT_ONLY`：是否只报告不强制执行
- `DISABLE_CSP`：禁用 CSP

## 6. 应用到 BuildX

### 6.1 建议采用的实践

1. **UUID 主键**：考虑为新表使用 UUID 主键
2. **自动加载**：配置 `autoload_lib` 包含自定义库
3. **事件日志**：启用事件日志调试模式
4. **Kamal 部署**：使用 Kamal 简化部署
5. **环境变量管理**：使用 `.kamal/secrets` 管理密钥
6. **多数据库支持**：支持 SQLite 和 MySQL

### 6.2 实现步骤

1. **配置应用**
   - 设置 UUID 主键
   - 配置自动加载路径
   - 启用事件日志

2. **配置 Kamal**
   - 创建 `config/deploy.yml`
   - 配置服务器和代理
   - 设置环境变量

3. **管理密钥**
   - 创建 `.kamal/secrets`
   - 添加到 `.gitignore`
   - 配置所有必需的密钥

4. **配置邮件**
   - 设置 SMTP 配置
   - 配置发件人地址
   - 测试邮件发送

## 参考资料

- [Kamal 文档](https://kamal-deploy.org/)
- [Fizzy deploy.yml](https://github.com/basecamp/fizzy/blob/main/config/deploy.yml)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

