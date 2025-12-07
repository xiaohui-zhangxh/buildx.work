---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、设计模式
status: 已完成
tags: Fizzy、多态关联、设计模式、Polymorphic、通用设计
description: 总结从 Basecamp Fizzy 项目学习到的多态关联通用设计模式，包括为什么使用多态关联、适用场景、实现指南和注意事项等
---

# Fizzy 多态关联通用设计模式

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的多态关联通用设计模式。使用多态关联可以让业务系统更通用，适用于多种模型，提高代码复用性和可扩展性。

## 核心原则

### 为什么使用多态关联？

**传统设计（单一模型）：**

```ruby
# 只能用于 Card
class Tagging < ApplicationRecord
  belongs_to :card
end

class Watch < ApplicationRecord
  belongs_to :card
end

class Pin < ApplicationRecord
  belongs_to :card
end
```

**问题**：
- ❌ 每个模型都需要单独的表
- ❌ 代码重复
- ❌ 扩展新模型需要修改数据库结构
- ❌ 无法跨模型共享功能

**多态关联设计（通用模型）：**

```ruby
# 可用于任何模型
class Tagging < ApplicationRecord
  belongs_to :taggable, polymorphic: true
end

class Watch < ApplicationRecord
  belongs_to :watchable, polymorphic: true
end

class Pin < ApplicationRecord
  belongs_to :pinnable, polymorphic: true
end
```

**优势**：
- ✅ 一个表支持多种模型
- ✅ 代码复用
- ✅ 扩展新模型无需修改数据库
- ✅ 跨模型共享功能

## 适用场景

以下系统建议使用多态关联：

### 1. 标签系统（Tagging）

**适用模型**：Card、Post、Article、Document 等

```ruby
class Tagging < ApplicationRecord
  belongs_to :taggable, polymorphic: true
end

module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end
end
```

### 2. 关注系统（Watch）

**适用模型**：Card、Post、Article、Project 等

```ruby
class Watch < ApplicationRecord
  belongs_to :watchable, polymorphic: true
end

module Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watchable, dependent: :destroy
    has_many :watchers, through: :watches, source: :user
  end
end
```

### 3. 置顶系统（Pin）

**适用模型**：Card、Post、Article、Document 等

```ruby
class Pin < ApplicationRecord
  belongs_to :pinnable, polymorphic: true
end

module Pinnable
  extend ActiveSupport::Concern

  included do
    has_many :pins, as: :pinnable, dependent: :destroy
  end
end
```

### 4. 分配系统（Assignment）

**适用模型**：Card、Task、Issue、Ticket 等

```ruby
class Assignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true
end

module Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, as: :assignable, dependent: :destroy
    has_many :assignees, through: :assignments, source: :assignee
  end
end
```

### 5. 反应系统（Reaction）

**适用模型**：Comment、Post、Article 等

```ruby
class Reaction < ApplicationRecord
  belongs_to :reactable, polymorphic: true
end

module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, dependent: :destroy
  end
end
```

### 6. 访问控制系统（Access）

**适用模型**：Board、Project、Workspace 等

```ruby
class Access < ApplicationRecord
  belongs_to :accessible, polymorphic: true
end

module Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, as: :accessible, dependent: :destroy
    has_many :users_with_access, through: :accesses, source: :user
  end
end
```

### 7. 评论系统（Comment）

**适用模型**：Card、Post、Article、Document 等

```ruby
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
    has_many :commenters, -> { distinct }, through: :comments, source: :creator
  end
end
```

## Fizzy 中已使用多态关联的系统

以下系统在 Fizzy 中已经使用了多态关联，可以作为参考：

### 1. Event 系统

```ruby
class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true
end
```

**适用模型**：Card、Comment 等

### 2. Mention 系统

```ruby
class Mention < ApplicationRecord
  belongs_to :source, polymorphic: true
end
```

**适用模型**：Comment、Card 等

### 3. Notification 系统

```ruby
class Notification < ApplicationRecord
  belongs_to :source, polymorphic: true
end
```

**适用模型**：Event、Mention 等

### 4. Search 系统

```ruby
class Search::Record < ApplicationRecord
  belongs_to :searchable, polymorphic: true
end
```

**适用模型**：Card、Comment 等

## 实现指南

### 1. 模型设计

**步骤 1：创建多态关联模型**

```ruby
class Tagging < ApplicationRecord
  belongs_to :account, default: -> { taggable.account }
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, touch: true
end
```

**关键点**：
- 使用 `polymorphic: true`
- 使用有意义的名称（如 `taggable`、`watchable`）
- 使用 `touch: true` 更新关联资源

**步骤 2：创建通用 Concern**

```ruby
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
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
end
```

**关键点**：
- 使用 `as: :taggable` 指定多态关联名称
- 实现通用的业务方法
- 保持 Concern 的独立性

### 2. 数据库迁移

```ruby
class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: true, type: :uuid
      t.references :taggable, null: false, polymorphic: true, type: :uuid

      t.timestamps
    end

    add_index :taggings, [:taggable_type, :taggable_id]
    add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true
  end
end
```

**关键点**：
- 使用 `polymorphic: true` 创建多态关联
- 添加 `taggable_type` 和 `taggable_id` 字段
- 添加适当的索引

### 3. 在模型中使用

```ruby
class Card < ApplicationRecord
  include Taggable
end

class Post < ApplicationRecord
  include Taggable
end

class Article < ApplicationRecord
  include Taggable
end
```

### 4. 查询和统计

**查询特定类型的标签：**

```ruby
# 查询所有 Card 的标签
Tag.joins(:taggings).where(taggings: { taggable_type: "Card" })

# 查询特定模型的标签使用情况
tag.taggings.where(taggable_type: "Card").count
```

**跨模型查询：**

```ruby
# 查询用户在所有模型中的标签
user.cards.joins(:tags).where(tags: { title: "ruby" })
user.posts.joins(:tags).where(tags: { title: "ruby" })
```

## 注意事项

### 1. Account 关联

**使用动态获取 account：**

```ruby
belongs_to :account, default: -> { taggable.account }
```

**确保所有模型都有 account 方法：**

```ruby
class Card < ApplicationRecord
  belongs_to :account
end

class Post < ApplicationRecord
  belongs_to :account
end
```

### 2. 查询性能

**使用适当的索引：**

```ruby
add_index :taggings, [:taggable_type, :taggable_id]
add_index :taggings, [:tag_id, :taggable_type, :taggable_id], unique: true
```

**预加载关联：**

```ruby
taggings.preload(:tag, :taggable)
```

### 3. 类型安全

**使用作用域限制类型：**

```ruby
scope :for_cards, -> { where(taggable_type: "Card") }
scope :for_posts, -> { where(taggable_type: "Post") }
```

## 应用到 BuildX

### 建议

1. **优先使用多态关联**：对于可能应用于多种模型的系统，优先考虑多态关联
2. **通用 Concern**：创建通用的 Concern，而不是模型特定的 Concern
3. **命名规范**：使用有意义的名称（如 `taggable`、`watchable`）
4. **索引优化**：为多态关联添加适当的索引
5. **文档说明**：在文档中说明支持哪些模型类型

### 适用系统

以下系统建议使用多态关联：

- ✅ **标签系统**（Tagging）- 适用于 Card、Post、Article 等
- ✅ **关注系统**（Watch）- 适用于 Card、Post、Project 等
- ✅ **置顶系统**（Pin）- 适用于 Card、Post、Document 等
- ✅ **分配系统**（Assignment）- 适用于 Card、Task、Issue 等
- ✅ **反应系统**（Reaction）- 适用于 Comment、Post 等
- ✅ **访问控制系统**（Access）- 适用于 Board、Project、Workspace 等
- ✅ **评论系统**（Comment）- 适用于 Card、Post、Article、Document 等

### 已使用多态关联的系统（参考）

- ✅ **Event 系统** - 已使用多态关联
- ✅ **Mention 系统** - 已使用多态关联
- ✅ **Notification 系统** - 已使用多态关联
- ✅ **Search 系统** - 已使用多态关联

## 参考资料

- [Rails 多态关联指南](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations)
- [Fizzy Event 模型](https://github.com/basecamp/fizzy/blob/main/app/models/event.rb)
- [Fizzy Mention 模型](https://github.com/basecamp/fizzy/blob/main/app/models/mention.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

