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

