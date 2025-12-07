---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、审核日志、Event、多态关联、Webhook
description: 总结从 Basecamp Fizzy 项目学习到的 Event 审核日志系统设计，包括 Event 模型、Eventable Concern、多态关联、Particulars 等
---

# Fizzy Event 审核日志系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的 Event 审核日志系统设计。Event 系统用于记录所有重要操作，实现完整的审核日志功能。

## 核心设计

### 1. Event 模型

```ruby
class Event < ApplicationRecord
  include Notifiable, Particulars, Promptable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User"
  belongs_to :eventable, polymorphic: true

  has_many :webhook_deliveries, class_name: "Webhook::Delivery", dependent: :delete_all

  scope :chronologically, -> { order created_at: :asc, id: :desc }
  scope :preloaded, -> {
    includes(:creator, :board, {
      eventable: [
        :goldness, :closure, :image_attachment,
        { rich_text_body: :embeds_attachments },
        { rich_text_description: :embeds_attachments },
        { card: [ :goldness, :closure, :image_attachment ] }
      ]
    })
  }

  after_create -> { eventable.event_was_created(self) }
  after_create_commit :dispatch_webhooks

  delegate :card, to: :eventable

  def action
    super.inquiry
  end

  def notifiable_target
    eventable
  end

  def description_for(user)
    Event::Description.new(self, user)
  end

  private
    def dispatch_webhooks
      Event::WebhookDispatchJob.perform_later(self)
    end
end
```

### 2. Eventable Concern

**使用 Concern 让模型支持事件记录：**

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",
        creator: creator,
        board: board,
        eventable: self,
        particulars: particulars
      )
    end
  end

  def event_was_created(event)
  end

  private
    def should_track_event?
      true
    end

    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
```

### 3. 关键设计点

#### 3.1 多态关联（Polymorphic Association）

**Event 通过多态关联记录任何模型的事件：**

```ruby
belongs_to :eventable, polymorphic: true
```

**好处**：
- 一个 Event 模型可以记录多种类型的事件
- 灵活扩展，不需要为每种类型创建单独的表
- 统一的查询接口

#### 3.2 Action 命名

**使用前缀 + 动作的命名方式：**

```ruby
def track_event(action, creator: Current.user, board: self.board, **particulars)
  board.events.create!(
    action: "#{eventable_prefix}_#{action}",
    # ...
  )
end

def eventable_prefix
  self.class.name.demodulize.underscore
end
```

**示例**：
- `card_created`
- `card_assigned`
- `card_closed`
- `comment_created`
- `card_title_changed`

#### 3.3 Particulars（详细信息）

**使用 JSON 字段存储事件详细信息：**

```ruby
# 在 track_event 中
track_event "board_changed", particulars: { 
  old_board: old_board_name, 
  new_board: board.name 
}

track_event "title_changed", particulars: { 
  old_title: title_before_last_save, 
  new_title: title 
}
```

**好处**：
- 灵活存储不同类型事件的详细信息
- 不需要为每种事件类型创建单独的字段
- 易于查询和过滤

#### 3.4 条件记录

**使用 `should_track_event?` 控制是否记录事件：**

```ruby
# 在 Card 中
def should_track_event?
  published?
end

# 在 Comment 中
def should_track_event?
  !creator.system?
end
```

**用途**：
- 只记录已发布的内容
- 忽略系统用户的操作
- 根据业务规则决定是否记录

#### 3.5 事件回调

**使用 `event_was_created` 回调处理事件创建后的逻辑：**

```ruby
# 在 Event 中
after_create -> { eventable.event_was_created(self) }

# 在 Card 中
def event_was_created(event)
  transaction do
    create_system_comment_for(event)
    touch_last_active_at
  end
end

# 在 Comment 中
def event_was_created(event)
  card.touch_last_active_at
end
```

**用途**：
- 创建系统评论
- 更新最后活动时间
- 触发其他业务逻辑

### 4. 使用示例

#### 4.1 Card 事件

```ruby
class Card < ApplicationRecord
  include Eventable

  # 发布时记录事件
  after_create -> { track_event :published }, if: :published?

  # 标题变更
  after_update :track_title_change, if: :saved_change_to_title?

  # 分配用户
  def assign_to(user)
    assignments.create!(assignee: user)
    track_event :assigned, assignee_ids: [user.id]
  end

  # 关闭卡片
  def close_by(user)
    create_closure!(closer: user)
    track_event :closed, creator: user
  end

  private
    def track_title_change
      track_event "title_changed", 
        particulars: { 
          old_title: title_before_last_save, 
          new_title: title 
        }
    end
end
```

#### 4.2 Comment 事件

```ruby
class Comment < ApplicationRecord
  include Eventable

  after_create_commit :track_comment_created

  private
    def track_comment_created
      track_event("created", board: card.board, creator: creator)
    end

    def should_track_event?
      !creator.system?
    end
end
```

### 5. 查询和展示

#### 5.1 时间顺序查询

```ruby
scope :chronologically, -> { order created_at: :asc, id: :desc }
```

#### 5.2 预加载关联

```ruby
scope :preloaded, -> {
  includes(:creator, :board, {
    eventable: [
      :goldness, :closure, :image_attachment,
      { rich_text_body: :embeds_attachments },
      { rich_text_description: :embeds_attachments },
      { card: [ :goldness, :closure, :image_attachment ] }
    ]
  })
}
```

#### 5.3 事件描述

**使用 `Event::Description` 生成用户友好的描述：**

```ruby
def description_for(user)
  Event::Description.new(self, user)
end
```

### 6. Webhook 集成

#### 6.1 自动分发 Webhook

```ruby
after_create_commit :dispatch_webhooks

private
  def dispatch_webhooks
    Event::WebhookDispatchJob.perform_later(self)
  end
```

**好处**：
- 异步处理，不阻塞请求
- 支持重试机制
- 可以批量处理

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：使用 `polymorphic: true` 让 Event 可以记录任何模型
2. **Action 命名**：使用 `模型名_动作` 的命名方式
3. **Particulars**：使用 JSON 字段存储详细信息
4. **条件记录**：使用 `should_track_event?` 控制是否记录
5. **事件回调**：使用 `event_was_created` 处理事件创建后的逻辑
6. **异步处理**：使用后台任务处理 Webhook 分发

#### 7.2 实现步骤

1. **创建 Event 模型**
   - 添加多态关联 `eventable`
   - 添加 `action`、`particulars` 字段
   - 添加关联（account, board, creator）

2. **创建 Eventable Concern**
   - 实现 `track_event` 方法
   - 实现 `should_track_event?` 钩子
   - 实现 `event_was_created` 回调

3. **在模型中集成**
   - 包含 `Eventable` Concern
   - 在关键操作中调用 `track_event`
   - 实现 `should_track_event?` 和 `event_was_created`

4. **实现查询和展示**
   - 创建时间顺序查询
   - 实现预加载关联
   - 创建事件描述生成器

5. **集成 Webhook**
   - 创建 Webhook 分发任务
   - 实现异步处理

## 参考资料

- [Fizzy Event 模型](https://github.com/basecamp/fizzy/blob/main/app/models/event.rb)
- [Fizzy Eventable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/concerns/eventable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

