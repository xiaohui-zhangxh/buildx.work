---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、高级特性
status: 已完成
tags: Fizzy、高级特性、Action Cable、CSP、Rails 扩展
description: 总结从 Basecamp Fizzy 项目学习到的高级特性，包括 Action Cable、自定义库、Rails 扩展、内容安全策略等
---

# Fizzy 高级特性

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的高级特性，包括 Action Cable、Rails 扩展、内容安全策略等。

## 1. Action Cable

### 1.1 连接管理

**Action Cable 连接配置：**

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if session = find_session_by_cookie
          account = Account.find_by(external_account_id: request.env["fizzy.external_account_id"])
          Current.account = account
          self.current_user = session.identity.users.find_by!(account: account) if account
        end
      end

      def find_session_by_cookie
        Session.find_signed(cookies.signed[:session_token])
      end
  end
end
```

**关键点**：
- 使用 `identified_by` 标识连接
- 通过 Cookie 查找会话
- 设置 Current 对象
- 支持多租户

### 1.2 远程连接管理

**在用户模型中管理远程连接：**

```ruby
class User < ApplicationRecord
  def deactivate
    transaction do
      accesses.destroy_all
      update! active: false, identity: nil
      close_remote_connections
    end
  end

  private
    def close_remote_connections
      ActionCable.server.remote_connections.where(current_user: self).disconnect(reconnect: false)
    end
end
```

**好处**：
- 用户停用时自动断开连接
- 防止未授权访问
- 清理资源

## 2. Rails 扩展（rails_ext）

### 2.1 Action Text 扩展

**扩展 Action Text 以支持自定义变体：**

```ruby
module ActionText
  module Extensions
    module RichText
      extend ActiveSupport::Concern

      included do
        # 覆盖默认的 :embeds 关联
        has_many_attached :embeds do |attachable|
          ::Attachments::VARIANTS.each do |variant_name, variant_options|
            attachable.variant variant_name, variant_options.merge(preprocessed: true)
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_text_rich_text) do
  include ActionText::Extensions::RichText
end
```

**关键点**：
- 使用 `ActiveSupport.on_load` 扩展 Rails 组件
- 使用 Concerns 组织扩展
- 覆盖默认行为

### 2.2 自定义库组织

**Fizzy 模块：**

```ruby
module Fizzy
  class << self
    def saas?
      return @saas if defined?(@saas)
      @saas = !!(((ENV["SAAS"] || File.exist?(File.expand_path("../tmp/saas.txt", __dir__))) && ENV["SAAS"] != "false"))
    end

    def db_adapter
      @db_adapter ||= DbAdapter.new ENV.fetch("DATABASE_ADAPTER", saas? ? "mysql" : "sqlite")
    end

    def configure_bundle
      if saas?
        ENV["BUNDLE_GEMFILE"] = "Gemfile.saas"
      end
    end
  end

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
end
```

**关键点**：
- 使用模块组织应用级配置
- 使用单例方法提供全局访问
- 延迟初始化（`||=`）

## 3. 内容安全策略（CSP）

### 3.1 CSP 配置

```ruby
Rails.application.configure do
  # 使用环境变量配置，回退到 config.x 值
  report_uri = ENV.fetch("CSP_REPORT_URI") { config.x.content_security_policy.report_uri }
  report_only = ENV.key?("CSP_REPORT_ONLY") ? ENV["CSP_REPORT_ONLY"] == "true" : config.x.content_security_policy.report_only

  # 为 importmap 和内联脚本生成 nonces
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src ]

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self, "https://challenges.cloudflare.com"
    policy.connect_src :self, "https://storage.basecamp.com"
    policy.frame_src :self, "https://challenges.cloudflare.com"

    # 允许用户工具：内联样式、data:/https: 源、blob: workers
    policy.style_src :self, :unsafe_inline
    policy.img_src :self, "blob:", "data:", "https:"
    policy.font_src :self, "data:", "https:"
    policy.media_src :self, "blob:", "data:", "https:"
    policy.worker_src :self, "blob:"

    policy.object_src :none
    policy.base_uri :none
    policy.form_action :self
    policy.frame_ancestors :self

    # 指定违规报告 URI（如 Sentry CSP 端点）
    policy.report_uri report_uri if report_uri
  end

  # 报告违规而不强制执行策略
  config.content_security_policy_report_only = report_only
end unless ENV["DISABLE_CSP"]
```

**关键点**：
- 使用环境变量配置
- 支持报告模式（`report_only`）
- 使用 nonces 增强安全性
- 允许用户工具（无障碍扩展、隐私工具等）

## 4. 初始化器

### 4.1 数据库角色日志

**记录数据库角色切换：**

```ruby
# config/initializers/database_role_logging.rb
Rails.application.configure do
  config.active_record.database_role_logging = true
end
```

### 4.2 多数据库支持

**配置多数据库：**

```ruby
# config/initializers/multi_db.rb
Rails.application.configure do
  config.active_record.configure_replica_connections
end
```

### 4.3 自动调优

**启用自动调优：**

```ruby
# config/initializers/autotuner.rb
Rails.application.configure do
  config.autotuner.enable = true
end
```

## 5. 应用到 BuildX

### 5.1 建议采用的实践

1. **Action Cable**：使用 `identified_by` 标识连接
2. **Rails 扩展**：使用 `ActiveSupport.on_load` 扩展 Rails 组件
3. **内容安全策略**：配置 CSP 增强安全性
4. **自定义库**：使用模块组织应用级配置
5. **远程连接管理**：在用户模型中管理远程连接

### 5.2 实现步骤

1. **配置 Action Cable**
   - 实现连接管理
   - 设置 Current 对象
   - 实现远程连接管理

2. **扩展 Rails 组件**
   - 识别需要扩展的组件
   - 使用 `ActiveSupport.on_load` 扩展
   - 使用 Concerns 组织扩展

3. **配置 CSP**
   - 设置 CSP 策略
   - 配置 nonces
   - 设置报告 URI

4. **组织自定义库**
   - 创建应用级模块
   - 实现配置方法
   - 使用延迟初始化

## 参考资料

- [Fizzy ApplicationCable](https://github.com/basecamp/fizzy/blob/main/app/channels/application_cable/connection.rb)
- [Fizzy lib/fizzy.rb](https://github.com/basecamp/fizzy/blob/main/lib/fizzy.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

