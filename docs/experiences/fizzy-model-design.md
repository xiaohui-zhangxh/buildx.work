---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、模型设计
status: 已完成
tags: Fizzy、模型设计、Model Design、Concerns、Scopes
description: 总结从 Basecamp Fizzy 项目学习到的模型设计模式，包括使用 Concerns 组织功能、作用域设计、业务逻辑封装等
---

# Fizzy 模型设计模式

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的模型设计模式。Fizzy 的模型设计体现了 Basecamp 对代码组织和可维护性的重视。

## 核心设计原则

### 1. 使用 Concerns 组织功能

**模型通过 Concerns 模块化功能：**

```ruby
class Card < ApplicationRecord
  include Assignable, Attachments, Broadcastable, Closeable, Colored, Entropic, Eventable,
    Exportable, Golden, Mentions, Multistep, Pinnable, Postponable, Promptable,
    Readable, Searchable, Stallable, Statuses, Taggable, Triageable, Watchable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

**好处**：
- 功能模块化，易于维护
- 代码复用，避免重复
- 清晰的职责划分
- 易于测试

**关键点**：
- 每个 Concern 负责一个功能领域
- 使用有意义的命名（如 `Assignable`, `Closeable`）
- 保持 Concerns 的独立性

### 2. 动态默认值

**使用 `default: -> { }` 提供动态默认值：**

```ruby
belongs_to :account, default: -> { board.account }
belongs_to :creator, class_name: "User", default: -> { Current.user }
```

**好处**：
- 自动设置关联关系
- 减少重复代码
- 确保数据一致性

**注意**：
- 使用 lambda 确保每次调用时重新计算
- 确保依赖的对象存在（如 `Current.user`）

**从 Commit 40dcf988 学到的经验**：

**时间**：2024-08-19  
**作者**：Jason Zimdars  
**变更文件**：`app/models/boost.rb`

```ruby
class Boost < ApplicationRecord
  belongs_to :splat
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

Fizzy 团队在 Boost 模型中使用 `default: -> { Current.user }` 设置默认创建者。这体现了：
- 使用 lambda 提供动态默认值
- 在关联中使用 `default` 自动设置创建者
- 简化了控制器代码，不需要显式传递 `creator`

### 2.3 从 enum 到普通属性的重构

**当不需要 enum 的额外功能时，使用普通属性加默认值：**

```ruby
# ❌ Old（使用 enum）
class Bubble < ApplicationRecord
  enum :color, %w[
    #BF1B1B #ED3F1C #ED8008 #7C956B
    #698F9C #3B4B59 #5D618F #3B3633 #67695E
  ].index_by(&:itself), suffix: true, default: "#698F9C"
end

# ✅ New（使用普通属性加默认值）
module Bubble::Colored
  extend ActiveSupport::Concern

  COLORS = %w[ #BF1B1B #ED3F1C #ED8008 #7C956B #698F9C #3B4B59 #5D618F #3B3633 #67695E ]

  included do
    attribute :color, default: "#698F9C"
  end
end

class Bubble < ApplicationRecord
  include Colored
end
```

**好处**：
- 更灵活，可以存储任意颜色值
- 不需要 enum 的 `suffix` 等方法
- 使用 Concern 组织相关逻辑
- 颜色列表提取到常量，易于维护

**从 Commit 1d8d10ce 学到的经验**：

**时间**：2024-09-18  
**作者**：Jeffrey Hardy  
**变更文件**：
- `app/models/bubble.rb`
- `app/models/bubble/colored.rb`（新建）

Fizzy 团队将 `Bubble#color` 从 enum 改为普通属性加默认值。这体现了：
- 当不需要 enum 的额外功能时，使用普通属性更灵活
- 使用 Concern 组织相关逻辑
- 将常量提取到模块中，易于维护

### 4. 多态关联和事件系统

#### 4.1 使用 delegated_type 实现多态关联

**使用 Rails 的 `delegated_type` 实现多态关联：**

```ruby
# app/models/thread_entry.rb
class ThreadEntry < ApplicationRecord
  belongs_to :bubble

  delegated_type :threadable, types: %w[ Comment Rollup ]

  scope :chronologically, -> { order created_at: :asc, id: :desc }
end

# app/models/concerns/threadable.rb
module Threadable
  extend ActiveSupport::Concern

  included do
    has_one :thread_entry, as: :threadable, dependent: :destroy

    after_create { create_thread_entry! bubble: bubble }
    after_update { bubble.touch }
    after_touch { bubble.touch }
  end
end

# app/models/comment.rb
class Comment < ApplicationRecord
  include Searchable, Threadable

  belongs_to :bubble, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end

# app/models/rollup.rb
class Rollup < ApplicationRecord
  include Threadable

  belongs_to :bubble

  has_many :events, -> { chronologically }
end
```

**关键点**：
- 使用 `delegated_type` 实现多态关联
- 使用 Concern `Threadable` 组织共享逻辑
- 使用 `after_create` 自动创建 `thread_entry`
- 使用 `touch: true` 确保关联对象更新

### 5. 多对多关系设计

#### 5.1 使用 has_and_belongs_to_many 实现多对多关系

**使用 `has_and_belongs_to_many` 实现 filters 和 filterables 的多对多关系：**

```ruby
# app/models/concerns/filterable.rb
module Filterable
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :filters

    after_update { filters.touch_all }
    before_destroy :remove_from_filters
  end

  private
    def remove_from_filters
      filters.each do |filter|
        filter.resource_removed kind: self.class.name.downcase, id: id
      end
    end
end

# app/models/filter.rb
class Filter < ApplicationRecord
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :buckets
  has_and_belongs_to_many :assignees, class_name: "User", join_table: "assignees_filters", association_foreign_key: "assignee_id"
end

# app/models/bucket.rb
class Bucket < ApplicationRecord
  include Filterable
  # ...
end
```

**关键点**：
- 使用 `has_and_belongs_to_many` 实现多对多关系
- 使用 `after_update { filters.touch_all }` 确保关联对象更新
- 使用 `before_destroy` 清理关联
- 使用 `join_table` 和 `association_foreign_key` 自定义关联表

**从 Commit 3d9d1694 学到的经验**：

**时间**：2024-11-05  
**作者**：Jose Farias  
**变更文件**：
- `app/models/concerns/filterable.rb`（新建）
- `app/models/filter.rb`
- `db/migrate/20241105224305_create_filter_join_tables.rb`（新建）

Fizzy 团队使用 `has_and_belongs_to_many` 实现 filters 和 filterables 的多对多关系。这体现了：
- 使用多对多关系连接 filters 和 filterables（buckets, tags, assignees）
- 使用 Concern 组织共享逻辑
- 使用回调确保数据一致性

### 6. 关注点分离：Fields 和 Params

#### 6.1 分离业务逻辑和序列化逻辑

**将 fields（业务逻辑）和 params（序列化/查询字符串）分离：**

```ruby
# app/models/filter/fields.rb
module Filter::Fields
  extend ActiveSupport::Concern

  INDEXES = %w[ most_active most_discussed most_boosted newest oldest popped ]

  class_methods do
    def default_fields
      { "indexed_by" => "most_active" }
    end
  end

  def assignments=(value)
    fields["assignments"] = value
  end

  def assignments
    fields["assignments"].to_s.inquiry
  end

  def indexed_by=(value)
    fields["indexed_by"] = value
  end

  def indexed_by
    (fields["indexed_by"] || default_fields["indexed_by"]).inquiry
  end
end

# app/models/filter/params.rb
module Filter::Params
  extend ActiveSupport::Concern

  included do
    before_save { self.params_digest = hashed_params }
  end

  def as_params
    params = {}.tap do |h|
      h["tag_ids"]      = tags.ids
      h["bucket_ids"]   = buckets.ids
      h["assignee_ids"] = assignees.ids
      h["indexed_by"]   = indexed_by
      h["assignments"]  = assignments
    end

    params.compact_blank.reject { |k, v| default_fields[k] == v }
  end
end
```

**关键点**：
- `fields` 用于业务逻辑（访问器、验证等）
- `params` 用于序列化和查询字符串（用于唯一性约束和 URL 参数）
- 使用 `derive_params` 从 fields 生成 params
- 体现了关注点分离和代码组织的最佳实践

**从 Commit 77a9b267 学到的经验**：

**时间**：2024-11-06  
**作者**：Jose Farias  
**变更文件**：
- `app/models/filter/fields.rb`（新建）
- `app/models/filter/params.rb`

Fizzy 团队将 fields（业务逻辑）和 params（序列化/查询字符串）分离。这体现了：
- 关注点分离的重要性
- 使用不同的存储机制处理不同的需求
- 代码组织的最佳实践

### 7. 性能优化：Counter Cache

#### 7.1 使用 Counter Cache 优化查询

**使用 Rails 的 counter cache 功能优化查询：**

```ruby
# ❌ Bad（N+1 查询）
def rescore
  update! activity_score: boost_count + messages.comments.size
end

# ✅ Good（使用 counter cache）
def rescore
  update! activity_score: boost_count + comments_count
end
```

**数据库迁移：**

```ruby
class AddCommentsCountToBubbles < ActiveRecord::Migration[8.0]
  def change
    add_column :bubbles, :comments_count, :integer, default: 0, null: false
  end
end
```

**模型关联：**

```ruby
class Bubble < ApplicationRecord
  has_many :comments, through: :messages
end

class Message < ApplicationRecord
  belongs_to :bubble, counter_cache: :comments_count
end
```

**关键点**：
- 使用 `counter_cache` 选项自动维护计数
- 避免在计算时执行额外的查询
- 提高性能，特别是在频繁计算的场景中

**从 Commit 2a9be42c 学到的经验**：

**时间**：2024-11-19  
**作者**：Jose Farias  
**变更文件**：`app/models/bubble.rb`

Fizzy 团队使用 counter cache 优化了 activity score 的计算。这体现了：
- 性能优化的重要性
- 使用 Rails 内置功能（counter cache）优化查询
- 避免在计算时执行额外的查询

### 8. 状态管理：使用 Enum 和 Concern

#### 8.1 使用 Enum 管理状态

**使用 enum 和 Concern 管理状态：**

```ruby
# app/models/bubble/draftable.rb
module Bubble::Draftable
  extend ActiveSupport::Concern

  included do
    enum :status, %w[ drafted published ].index_by(&:itself)

    scope :published_or_drafted_by, ->(user) { where(status: :published).or(where(creator: user)) }
  end
end

# app/models/bubble.rb
class Bubble < ApplicationRecord
  include Draftable
  # ...
end

# app/controllers/bubbles_controller.rb
def index
  @bubbles = @filter.bubbles.published_or_drafted_by(Current.user)
end
```

**关键点**：
- 使用 `enum :status, %w[ drafted published ].index_by(&:itself)` 定义状态
- 使用 Concern 组织状态管理逻辑
- 使用 scope 过滤可见的记录
- 在视图中使用状态类名（如 `drafted?`）添加样式

**从 Commit cd1e6378 学到的经验**：

**时间**：2025-01-07  
**作者**：Kevin McConnell  
**变更文件**：
- `app/models/bubble/draftable.rb`（新建）
- `app/controllers/bubbles/publishes_controller.rb`（新建）
- `db/migrate/20250107165422_add_status_to_bubbles.rb`（新建）

Fizzy 团队使用 enum 和 Concern 管理状态。这体现了：
- 状态管理的最佳实践
- 使用 Concern 组织状态逻辑
- 使用 scope 过滤可见记录
- 在视图中使用状态类名添加样式

**从 Commit cd1e6378 学到的经验**：

**时间**：2025-01-07  
**作者**：Kevin McConnell  
**变更文件**：
- `app/models/bubble/draftable.rb`（新建）
- `app/controllers/bubbles/publishes_controller.rb`（新建）
- `db/migrate/20250107165422_add_status_to_bubbles.rb`（新建）

Fizzy 团队使用 enum 和 Concern 管理状态。这体现了：
- 状态管理的最佳实践
- 使用 Concern 组织状态逻辑
- 使用 scope 过滤可见记录
- 在视图中使用状态类名添加样式

### 9. 发布/私有状态设计

#### 9.1 使用独立模型跟踪发布状态

**使用独立的 Publication 模型跟踪发布状态，而不是简单的布尔字段：**

```ruby
# app/models/collection/publication.rb
class Collection::Publication < ApplicationRecord
  belongs_to :collection

  has_secure_token :key
end

# app/models/collection/publishable.rb
module Collection::Publishable
  extend ActiveSupport::Concern

  included do
    has_one :publication, class_name: "Collection::Publication", dependent: :destroy
    scope :published, -> { joins(:publication) }
  end

  def published?
    publication.present?
  end

  def publish
    create_publication! unless published?
  end

  def unpublish
    publication&.destroy
  end
end

# app/models/collection.rb
class Collection < ApplicationRecord
  include Publishable
  # ...
end
```

**数据库迁移：**

```ruby
class CreateCollectionPublications < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_publications do |t|
      t.references :collection, null: false, foreign_key: true, index: true
      t.string :key, index: { unique: true }

      t.timestamps
    end
  end
end
```

**关键点**：
- 使用独立的 `Publication` 模型跟踪发布状态
- 使用 `has_one :publication` 关联，而不是布尔字段
- 使用 `has_secure_token :key` 生成安全的 token（用于公共访问）
- 使用 `scope :published` 过滤已发布的集合
- 使用 `publish` 和 `unpublish` 方法管理发布状态
- 体现了发布/私有状态设计的最佳实践

**从 Commit 38e35826 学到的经验**：

**时间**：2025-06-09  
**作者**：Jorge Manrubia  
**变更文件**：
- `app/models/collection/publication.rb`（新建）
- `app/models/collection/publishable.rb`（新建）
- `db/migrate/20250609102553_create_collection_publications.rb`（新建）

Fizzy 团队使用独立的 Publication 模型跟踪发布状态。这体现了：
- 发布/私有状态设计的最佳实践
- 使用独立模型而不是布尔字段
- 使用 Concern 组织发布逻辑
- 使用安全 token 进行公共访问

**从 Commit 2a9be42c 学到的经验**：

**时间**：2024-11-19  
**作者**：Jose Farias  
**变更文件**：`app/models/bubble.rb`

Fizzy 团队使用 counter cache 优化了 activity score 的计算。这体现了：
- 性能优化的重要性
- 使用 Rails 内置功能（counter cache）优化查询
- 避免在计算时执行额外的查询

**从 Commit 35a31e32 学到的经验**：

**时间**：2024-10-23  
**作者**：Jose Farias  
**变更文件**：
- `app/models/concerns/threadable.rb`（新建）
- `app/models/thread_entry.rb`（新建）
- `app/models/rollup.rb`（新建）

Fizzy 团队使用 `delegated_type` 实现 threadables 的多态关联。这体现了：
- 使用 Rails 的 `delegated_type` 实现多态关联
- 使用 Concern 组织共享逻辑
- 自动创建关联记录

### 2.4 提取业务逻辑到 Concern

**将复杂的业务逻辑提取到 Concern：**

```ruby
# app/models/bucket/accessible.rb
module Bucket::Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, dependent: :destroy
    has_many :users, through: :accesses

    after_create -> { grant_access(creator) }
  end

  def update_access(users)
    transaction do
      grant_access(users)
      accesses.where.not(user: Array(users)).delete_all
    end
  end

  def grant_access(users)
    Array(users).each do |user|
      accesses.create_or_find_by!(user: user)
    end
  end
end

# app/models/bucket.rb
class Bucket < ApplicationRecord
  include Accessible
  # ...
end
```

**好处**：
- 业务逻辑模块化
- 易于测试和维护
- 可以在多个模型间复用

**从 Commit b2d94859 学到的经验**：

**时间**：2024-09-18  
**作者**：Jeffrey Hardy  
**变更文件**：
- `app/models/bucket/accessible.rb`（新建）
- `app/models/bucket.rb`

Fizzy 团队将访问控制逻辑提取到 `Bucket::Accessible` Concern。这体现了：
- 使用 Concern 组织复杂的业务逻辑
- 提供清晰的 API（`update_access`, `grant_access`）
- 使用事务确保数据一致性

### 3. 作用域（Scopes）设计

#### 3.1 基础作用域

**使用作用域封装查询逻辑：**

```ruby
scope :reverse_chronologically, -> { order created_at: :desc, id: :desc }
scope :chronologically,         -> { order created_at: :asc,  id: :asc  }
scope :latest,                  -> { order last_active_at: :desc, id: :desc }
```

**好处**：
- 语义清晰
- 易于复用
- 集中管理查询逻辑

#### 3.2 预加载作用域

**使用 `preload` 避免 N+1 查询：**

```ruby
scope :with_users, -> { 
  preload(
    creator: [ :avatar_attachment, :account ], 
    assignees: [ :avatar_attachment, :account ]
  ) 
}

scope :preloaded, -> { 
  with_users.preload(
    :column, :tags, :steps, :closure, :goldness, :activity_spike, 
    :image_attachment, 
    board: [ :entropy, :columns ], 
    not_now: [ :user ]
  ).with_rich_text_description_and_embeds 
}
```

**关键点**：
- 使用 `preload` 而不是 `includes`（避免 LEFT OUTER JOIN）
- 链式组合多个预加载
- 预加载嵌套关联

#### 3.3 参数化作用域

**使用参数化作用域处理复杂查询：**

```ruby
scope :indexed_by, ->(index) do
  case index
  when "stalled" then stalled
  when "postponing_soon" then postponing_soon
  when "closed" then closed
  when "not_now" then postponed.latest
  when "golden" then golden
  when "draft" then drafted
  else all
  end
end

scope :sorted_by, ->(sort) do
  case sort
  when "newest" then reverse_chronologically
  when "oldest" then chronologically
  when "latest" then latest
  else latest
  end
end
```

**好处**：
- 统一查询接口
- 易于扩展
- 清晰的业务逻辑

### 4. 业务逻辑封装

#### 4.1 在模型中封装业务逻辑

**将业务逻辑封装在模型中，而不是控制器中：**

```ruby
def move_to(new_board)
  transaction do
    card.update!(board: new_board)
    card.events.update_all(board_id: new_board.id)
  end
end

def filled?
  title.present? || description.present?
end
```

**好处**：
- 业务逻辑集中管理
- 易于测试
- 易于复用

#### 4.2 使用事务保证一致性

**使用 `transaction` 保证操作的原子性：**

```ruby
def move_to(new_board)
  transaction do
    card.update!(board: new_board)
    card.events.update_all(board_id: new_board.id)
  end
end
```

**关键点**：
- 多个相关操作使用事务
- 确保数据一致性
- 处理回滚场景

### 5. 模型关系设计

#### 5.1 清晰的关联关系

**使用清晰的关联关系：**

```ruby
class Card < ApplicationRecord
  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  
  has_many :comments, dependent: :destroy
  has_one_attached :image, dependent: :purge_later
  has_rich_text :description
end
```

**关键点**：
- 使用 `dependent: :destroy` 或 `dependent: :delete_all` 管理级联删除
- 使用 `class_name` 指定关联类名
- 使用 `inverse_of` 优化关联

#### 5.2 多态关联

**使用多态关联支持灵活的关系：**

```ruby
class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true
end

class Comment < ApplicationRecord
  has_many :events, as: :eventable, dependent: :destroy
end
```

**好处**：
- 一个模型可以关联多种类型
- 减少表结构复杂度
- 提高灵活性

### 6. 回调使用

#### 6.1 条件回调

**使用条件回调控制执行时机：**

```ruby
before_save :set_default_title, if: :published?
before_create :assign_number
after_save   -> { board.touch }, if: :published?
after_touch  -> { board.touch }, if: :published?
after_update :handle_board_change, if: :saved_change_to_board_id?
```

**关键点**：
- 使用条件控制回调执行
- 使用 lambda 简化条件
- 避免不必要的回调执行

#### 6.2 回调顺序

**注意回调的执行顺序：**

```ruby
before_save :set_default_title, if: :published?
before_create :assign_number
after_save   -> { board.touch }, if: :published?
```

**顺序**：
1. `before_*` 回调
2. 保存操作
3. `after_*` 回调
4. `after_commit` 回调

### 7. 查询优化

#### 7.1 避免 N+1 查询

**使用 `preload` 或 `includes` 避免 N+1：**

```ruby
# ❌ Bad (N+1 查询)
cards.each { |card| card.creator.name }

# ✅ Good (预加载)
cards.preload(:creator).each { |card| card.creator.name }
```

#### 7.2 使用 `joins` 进行过滤

**使用 `joins` 进行关联过滤：**

```ruby
scope :by_system, -> { joins(:creator).where(creator: { role: "system" }) }
scope :by_user, -> { joins(:creator).where.not(creator: { role: "system" }) }
```

#### 7.3 使用 `select` 限制字段

**使用 `select` 只查询需要的字段：**

```ruby
scope :with_titles_only, -> { select(:id, :title, :created_at) }
```

### 8. 应用到 BuildX

#### 8.1 建议采用的实践

1. **使用 Concerns**：通过 Concerns 模块化功能
2. **动态默认值**：使用 `default: -> { }` 提供动态默认值
3. **作用域链**：使用链式作用域封装查询
4. **预加载**：使用 `preload` 避免 N+1 查询
5. **业务逻辑封装**：在模型中封装业务逻辑
6. **事务使用**：使用 `transaction` 保证一致性
7. **条件回调**：使用条件控制回调执行

#### 8.2 实现步骤

1. **识别功能模块**
   - 分析模型的功能
   - 识别可以模块化的功能
   - 创建对应的 Concerns

2. **创建 Concerns**
   - 为每个功能创建 Concern
   - 实现必要的方法
   - 添加必要的关联和回调

3. **优化查询**
   - 识别 N+1 查询
   - 创建预加载作用域
   - 优化复杂查询

4. **封装业务逻辑**
   - 将业务逻辑移到模型
   - 使用事务保证一致性
   - 添加必要的验证

## 参考资料

- [Fizzy Card 模型](https://github.com/basecamp/fizzy/blob/main/app/models/card.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

