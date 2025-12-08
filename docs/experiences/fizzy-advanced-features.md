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

**从 Commit 28d82daf 学到的经验**：

**时间**：2024-09-04  
**作者**：Jeffrey Hardy  
**变更文件**：`app/channels/application_cable/connection.rb`

Fizzy 团队改进了 Action Cable 认证，使其更类似于控制器：

```ruby
# ❌ Old
def connect
  self.current_user = find_verified_user
end

private
  def find_verified_user
    if session = find_session_by_cookie
      session.user
    else
      reject_unauthorized_connection
    end
  end

  def find_session_by_cookie
    if token = cookies.signed[:session_token]
      Session.find_signed(token)
    end
  end

# ✅ New
def connect
  set_current_user || reject_unauthorized_connection
end

private
  def set_current_user
    if session = find_session_by_cookie
      self.current_user = session.user
    end
  end

  def find_session_by_cookie
    Session.find_signed(cookies.signed[:session_token])
  end
```

**改进点**：
- 使用 `set_current_user` 方法，命名更清晰
- 直接使用 `Session.find_signed(cookies.signed[:session_token])`，不需要条件判断
- 如果找不到 session，`find_signed` 返回 `nil`，然后 `reject_unauthorized_connection`
- 代码更简洁，逻辑更清晰

### 1.3 缓存安全

**使视图可以安全缓存，避免在视图中使用 Current 对象：**

```erb
<!-- ❌ Old（不能缓存，因为使用了 Current.user） -->
<% tag.div class: [ "comment", { "comment--mine": Current.user == comment.creator } ] do %>
  <!-- ... -->
<% end %>

<!-- ✅ New（可以缓存，使用 data 属性） -->
<div class="comment" data-creator-id="<%= comment.creator_id %>">
  <!-- ... -->
</div>
```

**在 JavaScript 中获取当前用户：**

```javascript
// app/javascript/initializers/current.js
class Current {
  get user() {
    const currentUserId = this.#extractContentFromMetaTag("current-user-id")

    if (currentUserId) {
      return { id: parseInt(currentUserId) }
    }
  }

  #extractContentFromMetaTag(name) {
    return document.head.querySelector(`meta[name="${name}"]`)?.getAttribute("content")
  }
}

window.Current = new Current()
```

**在布局中添加 meta 标签：**

```erb
<!-- app/views/layouts/application.html.erb -->
<% if Current.user %>
  <meta name="current-user-id" content="<%= Current.user.id %>">
<% end %>
```

**使用 Stimulus 控制器添加样式：**

```javascript
// app/javascript/controllers/thread_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "myComment" ]

  connect() {
    this.#myComments.forEach(comment => comment.classList.add(this.myCommentClass))
  }

  get #myComments() {
    return this.element.querySelectorAll(`.comment[data-creator-id='${Current.user.id}']`)
  }
}
```

**关键点**：
- 在视图中不能使用 `Current.user`（因为会被缓存）
- 使用 `data-creator-id` 属性存储创建者 ID
- 在 JavaScript 中使用 `meta` 标签获取当前用户 ID
- 使用 Stimulus 控制器根据 `data-creator-id` 添加样式
- 体现了缓存安全和 JavaScript 初始化的最佳实践

**从 Commit 8233254d 学到的经验**：

**时间**：2024-10-23  
**作者**：Jose Farias  
**变更文件**：
- `app/javascript/initializers/current.js`（新建）
- `app/javascript/controllers/thread_controller.js`（新建）
- `app/views/comments/_comment.html.erb`
- `app/views/layouts/application.html.erb`

Fizzy 团队使评论视图可以安全缓存，通过使用 `data-creator-id` 属性和 JavaScript 初始化器获取当前用户。这体现了：
- 缓存安全的重要性
- 使用 data 属性存储用户相关信息
- 在 JavaScript 中处理用户相关的逻辑

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

## 5. 安全实践

### 5.1 内容清理（Sanitization）

**对用户生成的内容进行清理，防止 XSS 攻击：**

```ruby
# app/views/comments/_comment.html.erb
<div class="comment__body txt-align-start">
  <%= sanitize comment.body_html %>
</div>
```

**在初始化器中配置允许的 HTML 标签：**

```ruby
# config/initializers/sanitization.rb
Rails.application.config.after_initialize do
  Rails::HTML5::SafeListSanitizer.allowed_tags.merge(%w[ table tr td th thead tbody details summary ])
end
```

**关键点**：
- 使用 `sanitize` helper 方法清理用户生成的内容
- 在初始化器中配置允许的 HTML 标签
- 使用 `Rails::HTML5::SafeListSanitizer` 进行清理
- 支持 Markdown 渲染后的 HTML（如表格、details 等）
- 体现了安全实践和内容清理的最佳实践

**从 Commit 2b9c4d9b 学到的经验**：

**时间**：2024-11-29  
**作者**：Jose Farias  
**变更文件**：
- `app/views/comments/_comment.html.erb`
- `config/initializers/sanitization.rb`（新建）

Fizzy 团队对渲染的 Markdown 进行 sanitize，防止 XSS 攻击。这体现了：
- 安全实践的重要性
- 使用 Rails 内置的 sanitize 功能
- 配置允许的 HTML 标签
- 保护用户生成的内容

### 5.2 客户端过滤优化

**将过滤逻辑移到客户端，减少服务端请求：**

```ruby
# ❌ Old（服务端过滤）
class Bubbles::TagsController < ApplicationController
  def index
    @tags = Current.account.tags.search params[:q]
  end
end

class Tag < ApplicationRecord
  scope :search, ->(query) { where "title LIKE ?", "%#{query}%" }
end

# ✅ New（客户端过滤）
# 删除了服务端控制器和搜索 scope
# 使用客户端 JavaScript 进行过滤
```

**关键点**：
- 将过滤逻辑移到客户端，减少服务端请求
- 删除不必要的服务端控制器和路由
- 使用客户端 JavaScript 进行过滤
- 提高了响应速度，减少了服务器负载
- 体现了性能优化和客户端处理的最佳实践

**从 Commit acac683b 学到的经验**：

**时间**：2024-11-25  
**作者**：Jose Farias  
**变更文件**：
- 删除了 `Bubbles::TagsController` 和 `Bubbles::UsersController`
- 移除了模型中的 `search` scope

Fizzy 团队将 combobox 过滤移到客户端，减少了服务端请求。这体现了：
- 性能优化的重要性
- 客户端处理可以减少服务器负载
- 简化服务端代码

### 5.3 缓存友好的时间显示

**使用客户端 JavaScript 格式化时间，使视图可以缓存：**

```ruby
# app/helpers/time_helper.rb
module TimeHelper
  def local_datetime_tag(datetime, style: :time, **attributes)
    tag.time **attributes, datetime: datetime.iso8601, data: { local_time_target: style }
  end
end
```

**使用 Stimulus 控制器在客户端格式化时间：**

```javascript
// app/javascript/controllers/local_time_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time", "date", "datetime", "ago"]

  initialize() {
    this.timeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short" })
    this.dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "long" })
    this.dateTimeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short", dateStyle: "short" })
    this.agoFormatter = new AgoFormatter()
  }

  agoTargetConnected(target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = this.agoFormatter.format(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }
}

class AgoFormatter {
  format(dt) {
    const now = new Date()
    const seconds = (now - dt) / 1000
    const minutes = seconds / 60
    const hours = minutes / 60
    const days = hours / 24
    const weeks = days / 7
    const months = days / (365 / 12)
    const years = days / 365

    if (years >= 1) return this.#pluralize("year", years)
    if (months >= 1) return this.#pluralize("month", months)
    if (weeks >= 1) return this.#pluralize("week", weeks)
    if (days >= 1) return this.#pluralize("day", days)
    if (hours >= 1) return this.#pluralize("hour", hours)
    if (minutes >= 1) return this.#pluralize("minute", minutes)

    return "Less than a minute ago"
  }

  #pluralize(word, quantity) {
    quantity = Math.round(quantity)
    const suffix = (quantity === 1) ? "" : "s"
    return `${quantity} ${word}${suffix} ago`
  }
}
```

**在视图中使用：**

```erb
<!-- app/views/notifications/_notification.html.erb -->
<%= local_datetime_tag notification.created_at, style: :ago, data: { controller: "local-time", local_time_target: "ago" } %>
```

**关键点**：
- 使用 `local_datetime_tag` helper 生成 `<time>` 标签
- 使用 Stimulus 控制器在客户端格式化时间
- 使用 `Intl.DateTimeFormat` 和自定义 `AgoFormatter` 格式化时间
- 时间显示在客户端动态更新，视图可以安全缓存
- 体现了缓存优化和客户端处理的最佳实践

**从 Commit 6f8c9298 学到的经验**：

**时间**：2025-01-16  
**作者**：Kevin McConnell  
**变更文件**：
- `app/helpers/time_helper.rb`（新建）
- `app/javascript/controllers/local_time_controller.js`（新建）

Fizzy 团队使用客户端 JavaScript 格式化时间，使视图可以缓存。这体现了：
- 缓存优化的重要性
- 使用客户端处理动态内容
- 使用 Stimulus 控制器增强交互

### 5.4 缓存失效：包含关联对象

**在缓存键中包含关联对象，确保缓存正确失效：**

```ruby
# ❌ Old（缓存键不包含 Workflow，可能导致缓存失效问题）
def index
  fresh_when etag: [ @considering, @on_deck, @doing, @closed ].collect { it.page.records }
end

# ✅ New（在缓存键中包含 Workflow.all）
def index
  @cache_key = [ @considering, @on_deck, @doing, @closed ].collect { it.page.records }.including([ Workflow.all ])
  fresh_when etag: @cache_key
end

# 在视图中使用
<% cache @cache_key do %>
  <!-- ... -->
<% end %>
```

**关键点**：
- 使用 `including([ Workflow.all ])` 在缓存键中包含关联对象
- 确保当关联对象改变时，缓存会自动失效
- 使用 `ActiveSupport::Cache.expand_cache_key` 扩展缓存键
- 体现了缓存失效和依赖跟踪的最佳实践

**从 Commit 312c5c73 学到的经验**：

**时间**：2025-09-10  
**作者**：Jorge Manrubia  
**变更文件**：
- `app/controllers/cards_controller.rb`
- `app/models/user/day_timeline.rb`
- `app/views/cards/index/_columns.html.erb`

Fizzy 团队在缓存键中包含关联对象，确保缓存正确失效。这体现了：
- 缓存失效的重要性
- 依赖跟踪的最佳实践
- 使用 `including` 方法包含关联对象

### 5.5 缓存键：包含动态属性

**在缓存键中包含动态属性（如列颜色），确保缓存正确失效：**

```ruby
# ❌ Old（缓存键不包含列颜色，可能导致缓存失效问题）
def cacheable_preview_parts_for(card, *options)
  [ card, card.collection, card.collection.entropy_configuration, card.collection.publication, *options ]
end

# ✅ New（在缓存键中包含列颜色）
def cacheable_preview_parts_for(card, *options)
  [ card, card.collection, card.collection.entropy_configuration, card.collection.publication, card.column&.color, *options ]
end

# 在视图中使用
<% cache cacheable_preview_parts_for(card) do %>
  <!-- ... -->
<% end %>
```

**关键点**：
- 在缓存键中包含动态属性（如 `card.column&.color`）
- 确保当动态属性改变时，缓存会自动失效
- 使用安全导航操作符（`&.`）处理可能为 nil 的情况
- 体现了缓存失效和依赖跟踪的最佳实践

**从 Commit fcba8b6a 学到的经验**：

**时间**：2025-10-08  
**作者**：Jason Zimdars  
**变更文件**：
- `app/helpers/cards_helper.rb`
- `app/models/card/cacheable.rb`
- `app/views/cards/_card.json.jbuilder`

Fizzy 团队在缓存键中包含列颜色，确保缓存正确失效。这体现了：
- 缓存失效的重要性
- 在缓存键中包含动态属性的最佳实践
- 使用安全导航操作符处理可能为 nil 的情况

### 5.6 安全实践：Web Push SSRF 防护

**Web Push SSRF 保护和 IP 范围绕过修复：**

```ruby
# app/models/push/subscription.rb
class Push::Subscription < ApplicationRecord
  PERMITTED_ENDPOINT_HOSTS = %w[
    fcm.googleapis.com
    updates.push.services.mozilla.com
    web.push.apple.com
    notify.windows.com
  ].freeze

  validates :endpoint, presence: true
  validate :validate_endpoint_url

  def notification(**params)
    WebPush::Notification.new(
      **params,
      badge: user.notifications.unread.count,
      endpoint: endpoint,
      endpoint_ip: resolved_endpoint_ip,
      p256dh_key: p256dh_key,
      auth_key: auth_key
    )
  end

  def resolved_endpoint_ip
    return @resolved_endpoint_ip if defined?(@resolved_endpoint_ip)
    @resolved_endpoint_ip = SsrfProtection.resolve_public_ip(endpoint_uri&.host)
  end

  private
    def validate_endpoint_url
      if endpoint_uri.nil?
        errors.add(:endpoint, "is not a valid URL")
      elsif endpoint_uri.scheme != "https"
        errors.add(:endpoint, "must use HTTPS")
      elsif !permitted_endpoint_host?
        errors.add(:endpoint, "is not a permitted push service")
      elsif resolved_endpoint_ip.nil?
        errors.add(:endpoint, "resolves to a private or invalid IP address")
      end
    end

    def permitted_endpoint_host?
      host = endpoint_uri&.host&.downcase
      PERMITTED_ENDPOINT_HOSTS.any? { |permitted| host&.end_with?(permitted) }
    end
end

# app/models/ssrf_protection.rb
module SsrfProtection
  DISALLOWED_IP_RANGES = [
    IPAddr.new("0.0.0.0/8"),     # "This" network (RFC1700)
    IPAddr.new("100.64.0.0/10"), # Carrier-grade NAT (RFC6598)
    IPAddr.new("198.18.0.0/15")  # Benchmark testing (RFC2544)
  ].freeze
end
```

**关键点**：
- 解析端点 IP 一次并固定用于连接
- 验证端点解析为公共 IP
- 白名单允许的推送服务主机
- 添加缺失的 IP 范围到 SsrfProtection
- 体现了安全实践和 SSRF 防护的最佳实践

**从 Commit 496851b2 学到的经验**：

**时间**：2025-12-03  
**作者**：Jeremy Daer  
**变更文件**：
- `app/models/push/subscription.rb`
- `app/models/ssrf_protection.rb`

Fizzy 团队实现了 Web Push SSRF 保护和 IP 范围绕过修复。这体现了：
- SSRF 防护的重要性
- 端点验证的最佳实践
- IP 范围检查的完整性

### 5.7 安全实践：防垃圾邮件

**只向已验证用户发送通知邮件：**

```ruby
# app/models/user/settings.rb
class User::Settings < ApplicationRecord
  def bundling_emails?
    !bundle_email_never? && !user.system? && user.active? && user.verified?
  end
end
```

**关键点**：
- 在 `bundling_emails?` 中添加 `user.verified?` 检查
- 防止垃圾邮件向量：恶意用户可以为已知邮箱地址创建用户并触发不需要的通知
- 体现了安全实践和防垃圾邮件的最佳实践

**从 Commit 1ad52d25 学到的经验**：

**时间**：2025-12-05  
**作者**：Mike Dalessio  
**变更文件**：`app/models/user/settings.rb`

Fizzy 团队只向已验证用户发送通知邮件，防止垃圾邮件。这体现了：
- 防垃圾邮件的重要性
- 用户验证的最佳实践
- 安全实践的应用

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

