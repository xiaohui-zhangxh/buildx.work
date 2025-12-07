---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、关注系统、Watch、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的关注系统设计，包括 Watch 模型、Watchable Concern、软关注/取消关注、自动关注创建者等功能
---

# Fizzy 关注系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的关注系统设计。关注系统允许用户关注资源（如卡片），并在资源更新时自动收到通知。

## 核心设计

### 1. Watch 模型

**Fizzy 的实现（仅支持 Card）：**

```ruby
class Watch < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :user
  belongs_to :card, touch: true

  scope :watching, -> { where(watching: true) }
  scope :not_watching, -> { where(watching: false) }
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Watch < ApplicationRecord
  belongs_to :account, default: -> { watchable.account }
  belongs_to :user
  belongs_to :watchable, polymorphic: true, touch: true

  scope :watching, -> { where(watching: true) }
  scope :not_watching, -> { where(watching: false) }
end
```

**关键点**：
- 使用 `watching` 布尔字段管理关注状态
- 支持关注/取消关注（不删除记录）
- 使用 `touch: true` 更新关联资源的时间戳
- **⭐ 使用多态关联**：支持任何模型（Card、Post、Article 等）

**多态关联的优势**：
- ✅ **通用性**：一个关注系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Watch 表结构
- ✅ **代码复用**：同一套关注逻辑可以应用到不同模型

### 2. Watchable Concern

**Fizzy 的实现（Card 专用）：**

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

  def watch_for(user)
    watches.find_by(user: user)
  end

  def watch_by(user)
    watches.where(user: user).first_or_create.update!(watching: true)
  end

  def unwatch_by(user)
    watches.where(user: user).first_or_create.update!(watching: false)
  end

  private
    def subscribe_creator
      # Avoid touching to not interfere with the abandon card detection system
      Card.no_touching do
        watch_by creator
      end
    end
end
```

**改进建议（通用 Watchable Concern）：**

```ruby
module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy
    has_many :watchers, -> { active.merge(Watch.watching) }, through: :watches, source: :user

    after_create :subscribe_creator
  end

  def watched_by?(user)
    watch_for(user)&.watching?
  end

  def watch_for(user)
    watches.find_by(user: user)
  end

  def watch_by(user)
    watches.where(user: user).first_or_create.update!(watching: true)
  end

  def unwatch_by(user)
    watches.where(user: user).first_or_create.update!(watching: false)
  end

  private
    def subscribe_creator
      # 使用通用方法避免干扰其他系统
      self.class.no_touching do
        watch_by creator
      end
    end
end
```

**关键改进**：
- 使用 `as: :watchable` 支持多态关联
- 移除了 `Card::` 命名空间，使其更通用
- 可以在任何模型中包含（Card、Post、Article 等）

### 3. 关键设计点

#### 3.1 软关注/取消关注

**使用 `watching` 字段而不是删除记录：**

```ruby
def watch_by(user)
  watches.where(user: user).first_or_create.update!(watching: true)
end

def unwatch_by(user)
  watches.where(user: user).first_or_create.update!(watching: false)
end
```

**好处**：
- 保留关注历史
- 可以快速重新关注
- 支持统计和分析

#### 3.2 自动关注创建者

**创建资源时自动关注创建者：**

```ruby
after_create :subscribe_creator

private
  def subscribe_creator
    Card.no_touching do
      watch_by creator
    end
  end
end
```

**好处**：
- 创建者自动收到更新通知
- 提高用户参与度
- 简化用户操作

#### 3.3 避免干扰其他系统

**使用 `no_touching` 避免干扰其他系统：**

```ruby
Card.no_touching do
  watch_by creator
end
```

**用途**：
- 避免触发其他回调
- 避免干扰放弃卡片检测系统
- 提高性能

#### 3.4 查询关注者

**使用作用域查询关注者：**

```ruby
has_many :watchers, -> { active.merge(Watch.watching) }, through: :watches, source: :user
```

**关键点**：
- 只返回活跃用户
- 只返回正在关注的用户
- 使用 `through` 关联

### 4. 用户模型集成

**在 User 模型中添加关注方法：**

```ruby
module User::Watcher
  extend ActiveSupport::Concern

  included do
    has_many :watches, dependent: :destroy
    has_many :watched_cards, through: :watches, source: :card
  end

  def watching?(card)
    card.watched_by?(self)
  end
end
```

### 5. 通知集成

**关注者自动收到通知：**

```ruby
class Notifier::CardEventNotifier < Notifier
  private
    def recipients
      case source.action
      when "card_published"
        board.watchers.without(creator, *card.mentionees).including(*card.assignees).uniq
      when "comment_created"
        card.watchers.without(creator, *source.eventable.mentionees)
      else
        board.watchers.without(creator)
      end
    end
end
```

**关键点**：
- 排除创建者
- 排除已提及的用户
- 包含已分配的用户
- 去重

### 6. 使用示例

#### 6.1 在 Card 中使用

```ruby
class Card < ApplicationRecord
  include Watchable

  # 自动关注创建者
  # 支持 watch_by/unwatch_by 方法
  # 支持 watched_by? 查询
end
```

#### 6.2 控制器中使用

```ruby
class Cards::WatchesController < ApplicationController
  include CardScoped

  def create
    @card.watch_by Current.user
    redirect_to @card
  end

  def destroy
    @card.unwatch_by Current.user
    redirect_to @card
  end
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Card、Post、Article 等）
2. **软关注/取消关注**：使用 `watching` 字段而不是删除记录
3. **自动关注创建者**：创建资源时自动关注创建者
4. **避免干扰其他系统**：使用 `no_touching` 避免触发其他回调
5. **查询关注者**：使用作用域查询活跃的关注者
6. **通知集成**：关注者自动收到通知

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Watch 模型
class Watch < ApplicationRecord
  belongs_to :account, default: -> { watchable.account }
  belongs_to :user
  belongs_to :watchable, polymorphic: true, touch: true
end

# 通用 Watchable Concern
module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy
    has_many :watchers, -> { active.merge(Watch.watching) }, through: :watches, source: :user
    after_create :subscribe_creator
  end

  def watch_by(user)
    watches.where(user: user).first_or_create.update!(watching: true)
  end
end

# 在任何模型中使用
class Card < ApplicationRecord
  include Watchable
end

class Post < ApplicationRecord
  include Watchable
end
```

#### 7.2 实现步骤

1. **创建 Watch 模型**
   - **使用多态关联**：`belongs_to :watchable, polymorphic: true`
   - 添加关联（account, user）
   - 添加 `watching` 布尔字段
   - 添加作用域

2. **创建通用 Watchable Concern**
   - 使用 `as: :watchable` 支持多态
   - 实现 `watch_by` 和 `unwatch_by` 方法
   - 实现 `watched_by?` 查询方法
   - 实现自动关注创建者

3. **在模型中集成**
   - 包含 `Watchable` Concern（任何模型都可以）
   - 添加必要的关联
   - 实现关注逻辑

4. **实现控制器**
   - 创建通用的 WatchesController（支持多态）
   - 实现关注/取消关注操作
   - 处理重定向

5. **集成通知系统**
   - 在 Notifier 中使用关注者
   - 排除创建者和已提及的用户
   - 去重处理

## 参考资料

- [Fizzy Watch 模型](https://github.com/basecamp/fizzy/blob/main/app/models/watch.rb)
- [Fizzy Watchable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/card/watchable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

