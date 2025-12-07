---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、通知系统、Notification、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的通知系统设计，包括 Notification 模型、多态关联、已读/未读状态、推送通知和通知聚合等功能
---

# Fizzy 通知系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的通知系统设计。通知系统支持多态关联、已读/未读状态、推送通知和通知聚合等功能。

## 核心设计

### 1. Notification 模型

```ruby
class Notification < ApplicationRecord
  include PushNotifiable

  belongs_to :account, default: -> { user.account }
  belongs_to :user
  belongs_to :creator, class_name: "User"
  belongs_to :source, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :ordered, -> { order(read_at: :desc, created_at: :desc) }

  after_create_commit :broadcast_unread
  after_destroy_commit :broadcast_read
  after_create :bundle

  scope :preloaded, -> { 
    preload(
      :creator, :account, 
      source: [ :board, :creator, { eventable: [ :closure, :board, :assignments ] } ]
    ) 
  }

  delegate :notifiable_target, to: :source
  delegate :card, to: :source

  def self.read_all
    all.each { |notification| notification.read }
  end

  def read
    update!(read_at: Time.current)
    broadcast_read
  end

  def unread
    update!(read_at: nil)
    broadcast_unread
  end

  def read?
    read_at.present?
  end

  private
    def broadcast_unread
      broadcast_prepend_later_to user, :notifications, target: "notifications"
    end

    def broadcast_read
      broadcast_remove_to user, :notifications
    end

    def bundle
      user.bundle(self) if user.settings.bundling_emails?
    end
end
```

### 2. 关键设计点

#### 2.1 多态关联

**Notification 通过多态关联支持多种来源：**

```ruby
belongs_to :source, polymorphic: true
```

**支持的类型**：
- Event（事件）
- Mention（提及）
- 其他可通知的资源

**好处**：
- 一个 Notification 模型可以处理多种类型的通知
- 灵活扩展，不需要为每种类型创建单独的表
- 统一的查询接口

#### 2.2 已读/未读状态

**使用 `read_at` 字段管理已读状态：**

```ruby
scope :unread, -> { where(read_at: nil) }
scope :read, -> { where.not(read_at: nil) }

def read
  update!(read_at: Time.current)
  broadcast_read
end

def unread
  update!(read_at: nil)
  broadcast_unread
end

def read?
  read_at.present?
end
```

**好处**：
- 简单的状态管理
- 支持标记为未读
- 易于查询和统计

#### 2.3 实时广播

**使用 Turbo Streams 实现实时更新：**

```ruby
after_create_commit :broadcast_unread
after_destroy_commit :broadcast_read

private
  def broadcast_unread
    broadcast_prepend_later_to user, :notifications, target: "notifications"
  end

  def broadcast_read
    broadcast_remove_to user, :notifications
  end
end
```

**好处**：
- 实时更新通知列表
- 无需刷新页面
- 提升用户体验

#### 2.4 通知聚合（Bundle）

**支持将多个通知聚合为单个邮件：**

```ruby
after_create :bundle

private
  def bundle
    user.bundle(self) if user.settings.bundling_emails?
  end
end
```

**好处**：
- 减少邮件数量
- 提高用户体验
- 支持用户设置

### 3. Notifiable Concern

**使用 Concern 让模型支持通知：**

```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy
    after_create_commit :notify_recipients_later
  end

  def notify_recipients
    Notifier.for(self)&.notify
  end

  def notifiable_target
    self
  end

  private
    def notify_recipients_later
      NotifyRecipientsJob.perform_later self
    end
end
```

**关键点**：
- 自动创建通知
- 使用后台任务异步处理
- 通过 Notifier 模式分发通知

### 4. Notifier 模式

**使用 Notifier 模式处理不同类型的通知：**

```ruby
class Notifier
  def self.for(source)
    case source
    when Event
      Notifier::CardEventNotifier.new(source)
    when Comment
      Notifier::CommentEventNotifier.new(source)
    when Mention
      Notifier::MentionNotifier.new(source)
    end
  end

  def initialize(source)
    @source = source
  end

  def notify
    # 子类实现
  end
end
```

**好处**：
- 职责分离
- 易于扩展
- 清晰的逻辑组织

### 5. PushNotifiable Concern

**支持推送通知：**

```ruby
module PushNotifiable
  extend ActiveSupport::Concern

  included do
    after_create_commit :push_notification_later
  end

  private
    def push_notification_later
      PushNotificationJob.perform_later(self)
    end
end
```

**好处**：
- 自动推送通知
- 异步处理
- 支持 Web Push

### 6. 使用示例

#### 6.1 在 Event 中使用

```ruby
class Event < ApplicationRecord
  include Notifiable

  def notifiable_target
    eventable
  end
end
```

#### 6.2 在 Mention 中使用

```ruby
class Mention < ApplicationRecord
  include Notifiable

  def notifiable_target
    source
  end
end
```

### 7. 控制器设计

```ruby
class NotificationsController < ApplicationController
  def index
    @notifications = Current.user.notifications.preloaded.ordered
  end

  def read
    @notification = Current.user.notifications.find(params[:id])
    @notification.read
  end

  def read_all
    Current.user.notifications.unread.read_all
    redirect_to notifications_path
  end
end
```

### 8. 视图设计

#### 8.1 订阅通知流

```erb
<%= turbo_stream_from Current.user, :notifications %>
```

#### 8.2 通知列表

```erb
<div id="notifications">
  <%= render @notifications %>
</div>
```

#### 8.3 Turbo Stream 更新

```erb
<!-- 创建通知时自动追加 -->
<!-- 标记已读时自动移除 -->
```

### 9. 应用到 BuildX

#### 9.1 建议采用的实践

1. **多态关联**：使用 `polymorphic: true` 支持多种来源
2. **已读/未读状态**：使用 `read_at` 字段管理状态
3. **实时广播**：使用 Turbo Streams 实现实时更新
4. **通知聚合**：支持将多个通知聚合为单个邮件
5. **Notifier 模式**：使用 Notifier 模式处理不同类型的通知
6. **推送通知**：支持 Web Push 通知

#### 9.2 实现步骤

1. **创建 Notification 模型**
   - 添加多态关联 `source`
   - 添加关联（account, user, creator）
   - 添加 `read_at` 字段

2. **创建 Notifiable Concern**
   - 实现 `notify_recipients` 方法
   - 实现 `notifiable_target` 方法
   - 实现异步通知创建

3. **创建 Notifier 模式**
   - 创建基础 Notifier 类
   - 为每种类型创建具体的 Notifier
   - 实现通知分发逻辑

4. **实现推送通知**
   - 创建 PushNotifiable Concern
   - 实现推送通知任务
   - 配置 Web Push

5. **实现通知聚合**
   - 创建 Bundle 模型
   - 实现聚合逻辑
   - 支持用户设置

6. **实现控制器和视图**
   - 创建 NotificationsController
   - 实现通知列表
   - 实现实时更新

## 参考资料

- [Fizzy Notification 模型](https://github.com/basecamp/fizzy/blob/main/app/models/notification.rb)
- [Fizzy Notifiable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/concerns/notifiable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

