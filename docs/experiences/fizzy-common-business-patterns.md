---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、业务模式、设计模式、通用设计
description: 总结从 Basecamp Fizzy 项目学习到的通用业务设计模式，包括通知、关注、标签、反应、访问控制、过滤、置顶、分配、搜索等系统
---

# Fizzy 通用业务设计模式总结

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的通用业务设计模式。这些模式可以应用到各种 SaaS 项目中。

## 已创建的专题文档

以下模式已有详细的专题文档：

1. **SaaS 多租户 Account 设计** - [fizzy-saas-account-design.md](fizzy-saas-account-design.md)
2. **Event 审核日志系统** - [fizzy-event-audit-log.md](fizzy-event-audit-log.md)
3. **评论系统设计** - [fizzy-comment-system.md](fizzy-comment-system.md)
4. **提及（Mention）系统设计** - [fizzy-mention-system.md](fizzy-mention-system.md)

## 其他通用业务模式

### 1. 通知系统（Notification）

**核心设计**：
- 多态关联（`belongs_to :source, polymorphic: true`）
- 支持已读/未读状态
- 支持推送通知
- 支持通知聚合（Bundle）

**关键模型**：

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

  def read
    update!(read_at: Time.current)
    broadcast_read
  end
end
```

**Notifiable Concern**：

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
end
```

**应用场景**：
- 用户操作通知（如评论、提及、分配等）
- 系统通知
- 邮件通知聚合

### 2. 关注系统（Watch）

**核心设计**：
- 用户关注资源（如卡片）
- 支持关注/取消关注
- 自动关注创建者

**关键模型**：

```ruby
class Watch < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :user
  belongs_to :card, touch: true

  scope :watching, -> { where(watching: true) }
  scope :not_watching, -> { where(watching: false) }
end
```

**Watchable Concern**：

```ruby
module Card::Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, dependent: :destroy
    has_many :watchers, -> { active.merge(Watch.watching) }, through: :watches, source: :user
    after_create :subscribe_creator
  end

  def watched_by?(user)
    watch_for(user)&.watching?
  end

  def watch_by(user)
    watches.where(user: user).first_or_create.update!(watching: true)
  end

  def unwatch_by(user)
    watches.where(user: user).first_or_create.update!(watching: false)
  end
end
```

**应用场景**：
- 用户关注卡片/任务
- 自动关注创建者
- 通知关注者

### 3. 标签系统（Tag/Tagging）

**核心设计**：
- 多对多关系
- 支持标签过滤
- 支持切换标签

**关键模型**：

```ruby
class Tag < ApplicationRecord
  include Attachable, Filterable

  belongs_to :account, default: -> { Current.account }
  has_many :taggings, dependent: :destroy
  has_many :cards, through: :taggings

  validates :title, format: { without: /\A#/ }
  normalizes :title, with: -> { it.downcase }

  scope :alphabetically, -> { order("lower(title)") }
  scope :unused, -> { left_outer_joins(:taggings).where(taggings: { id: nil }) }

  def hashtag
    "#" + title
  end
end

class Tagging < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :tag
  belongs_to :card, touch: true
end
```

**Taggable Concern**：

```ruby
module Card::Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, dependent: :destroy
    has_many :tags, through: :taggings
    scope :tagged_with, ->(tags) { joins(:taggings).where(taggings: { tag: tags }) }
  end

  def toggle_tag_with(title)
    tag = account.tags.find_or_create_by!(title: title)
    transaction do
      if tagged_with?(tag)
        taggings.destroy_by tag: tag
      else
        taggings.create tag: tag
      end
    end
  end

  def tagged_with?(tag)
    tags.include? tag
  end
end
```

**应用场景**：
- 卡片/任务标签
- 标签过滤
- 标签统计

### 4. 反应系统（Reaction）

**核心设计**：
- 用户对评论的反应
- 支持多种表情
- 记录反应者

**关键模型**：

```ruby
class Reaction < ApplicationRecord
  belongs_to :account, default: -> { comment.account }
  belongs_to :comment, touch: true
  belongs_to :reacter, class_name: "User", default: -> { Current.user }

  scope :ordered, -> { order(:created_at) }

  after_create :register_card_activity
end
```

**应用场景**：
- 评论反应
- 快速反馈
- 减少不必要的评论

### 5. 访问控制（Access）

**核心设计**：
- 用户对资源的访问权限
- 支持访问级别（access_only/watching）
- 记录访问时间

**关键模型**：

```ruby
class Access < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :board, touch: true
  belongs_to :user, touch: true

  enum :involvement, %i[ access_only watching ].index_by(&:itself), default: :access_only

  scope :ordered_by_recently_accessed, -> { order(accessed_at: :desc) }

  after_destroy_commit :clean_inaccessible_data_later

  def accessed
    touch :accessed_at unless recently_accessed?
  end
end
```

**应用场景**：
- 资源访问权限
- 访问历史记录
- 权限级别管理

### 6. 过滤系统（Filter）

**核心设计**：
- 高级过滤功能
- 支持多种过滤条件
- 支持缓存

**关键模型**：

```ruby
class Filter < ApplicationRecord
  include Fields, Params, Resources, Summarized

  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { creator.account }

  def cards
    @cards ||= begin
      result = creator.accessible_cards.preloaded.published
      result = result.indexed_by(indexed_by)
      result = result.sorted_by(sorted_by)
      result = result.where(id: card_ids) if card_ids.present?
      result = result.where.missing(:not_now) unless include_not_now_cards?
      result = result.open unless include_closed_cards?
      result = result.unassigned if assignment_status.unassigned?
      result = result.assigned_to(assignees.ids) if assignees.present?
      result = result.where(creator_id: creators.ids) if creators.present?
      result = result.where(board: boards.ids) if boards.present?
      result = result.tagged_with(tags.ids) if tags.present?
      result.distinct
    end
  end
end
```

**应用场景**：
- 高级搜索
- 自定义视图
- 过滤条件保存

### 7. 置顶系统（Pin）

**核心设计**：
- 用户置顶资源
- 支持排序

**关键模型**：

```ruby
class Pin < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :card
  belongs_to :user

  scope :ordered, -> { order(created_at: :desc) }
end
```

**应用场景**：
- 用户置顶卡片/任务
- 个人收藏
- 快速访问

### 8. 分配系统（Assignment）

**核心设计**：
- 任务分配
- 记录分配者和被分配者

**关键模型**：

```ruby
class Assignment < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :assignee, class_name: "User"
  belongs_to :assigner, class_name: "User"
end
```

**应用场景**：
- 任务分配
- 责任追踪
- 工作量统计

### 9. 搜索系统（Search）

**核心设计**：
- 全文搜索
- 支持自动索引
- 支持多数据库适配器

**Searchable Concern**：

```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit :create_in_search_index
    after_update_commit :update_in_search_index
    after_destroy_commit :remove_from_search_index
  end

  def reindex
    update_in_search_index
  end

  private
    def create_in_search_index
      search_record_class.create!(search_record_attributes)
    end

    def update_in_search_index
      search_record_class.upsert!(search_record_attributes)
    end

    def remove_from_search_index
      search_record_class.find_by(searchable_type: self.class.name, searchable_id: id)&.destroy
    end
end
```

**应用场景**：
- 全文搜索
- 内容索引
- 搜索高亮

## 应用到 BuildX

### 建议实现的顺序

1. **基础系统**（已实现或计划中）：
   - Account 多租户
   - Event 审核日志
   - Comment 评论
   - Mention 提及

2. **核心功能**：
   - Notification 通知系统
   - Watch 关注系统
   - Tag/Tagging 标签系统

3. **增强功能**：
   - Reaction 反应系统
   - Pin 置顶系统
   - Assignment 分配系统

4. **高级功能**：
   - Filter 过滤系统
   - Search 搜索系统
   - Access 访问控制

### 实现建议

1. **Notification 系统**：
   - 实现多态关联
   - 支持已读/未读
   - 支持推送通知
   - 支持通知聚合

2. **Watch 系统**：
   - 实现关注/取消关注
   - 自动关注创建者
   - 通知关注者

3. **Tag 系统**：
   - 实现多对多关系
   - 支持标签过滤
   - 支持切换标签

4. **Reaction 系统**：
   - 实现反应功能
   - 支持多种表情
   - 记录反应者

5. **Filter 系统**：
   - 实现高级过滤
   - 支持条件保存
   - 支持缓存

6. **Search 系统**：
   - 实现全文搜索
   - 支持自动索引
   - 支持搜索高亮

## 参考资料

- [Fizzy Notification 模型](https://github.com/basecamp/fizzy/blob/main/app/models/notification.rb)
- [Fizzy Watch 模型](https://github.com/basecamp/fizzy/blob/main/app/models/watch.rb)
- [Fizzy Tag 模型](https://github.com/basecamp/fizzy/blob/main/app/models/tag.rb)
- [Fizzy Filter 模型](https://github.com/basecamp/fizzy/blob/main/app/models/filter.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

