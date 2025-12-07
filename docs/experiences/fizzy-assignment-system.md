---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、分配系统、Assignment、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的分配系统设计，包括 Assignment 模型、Assignable Concern、记录分配者和被分配者、自动关注和事件记录等功能
---

# Fizzy 分配系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的分配系统设计。分配系统允许将任务分配给用户，支持责任追踪和工作量统计。

## 核心设计

### 1. Assignment 模型

**Fizzy 的实现（仅支持 Card）：**

```ruby
class Assignment < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :assignee, class_name: "User"
  belongs_to :assigner, class_name: "User"
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Assignment < ApplicationRecord
  belongs_to :account, default: -> { assignable.account }
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :assignee, class_name: "User"
  belongs_to :assigner, class_name: "User"
end
```

**关键点**：
- 记录分配者（assigner）和被分配者（assignee）
- 使用 `touch: true` 更新资源时间戳
- 支持责任追踪
- **⭐ 使用多态关联**：支持任何模型（Card、Task、Issue 等）

**多态关联的优势**：
- ✅ **通用性**：一个分配系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Assignment 表结构
- ✅ **代码复用**：同一套分配逻辑可以应用到不同模型

### 2. Assignable Concern

**Fizzy 的实现（Card 专用）：**

```ruby
module Card::Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, dependent: :destroy
    has_many :assignees, through: :assignments, source: :assignee
  end

  def assigned_to?(user)
    assignees.include? user
  end

  def assign_to(user, assigner: Current.user)
    assignments.create!(assignee: user, assigner: assigner)
    watch_by user
    track_event :assigned, assignee_ids: [ user.id ]
  rescue ActiveRecord::RecordNotUnique
    # Already assigned
  end

  def unassign_from(user)
    destructions = assignments.where(assignee: user).destroy_all
    track_event :unassigned, assignee_ids: [ user.id ] if destructions.any?
  end

  def toggle_assignment(user)
    if assigned_to?(user)
      unassign_from(user)
    else
      assign_to(user)
    end
  end
end
```

**改进建议（通用 Assignable Concern）：**

```ruby
module Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, as: :assignable, dependent: :destroy
    has_many :assignees, through: :assignments, source: :assignee
  end

  def assigned_to?(user)
    assignees.include? user
  end

  def assign_to(user, assigner: Current.user)
    assignments.create!(assignee: user, assigner: assigner)
    watch_by user if respond_to?(:watch_by)
    track_event :assigned, assignee_ids: [ user.id ] if respond_to?(:track_event)
  rescue ActiveRecord::RecordNotUnique
    # Already assigned
  end

  def unassign_from(user)
    destructions = assignments.where(assignee: user).destroy_all
    track_event :unassigned, assignee_ids: [ user.id ] if destructions.any? && respond_to?(:track_event)
  end

  def toggle_assignment(user)
    if assigned_to?(user)
      unassign_from(user)
    else
      assign_to(user)
    end
  end
end
```

**关键改进**：
- 使用 `as: :assignable` 支持多态关联
- 移除了 `Card::` 命名空间，使其更通用
- 使用 `respond_to?` 检查可选方法（watch_by、track_event）
- 可以在任何模型中包含（Card、Task、Issue 等）

### 3. 关键设计点

#### 3.1 记录分配者和被分配者

**同时记录分配者和被分配者：**

```ruby
belongs_to :assignee, class_name: "User"
belongs_to :assigner, class_name: "User"
```

**好处**：
- 支持责任追踪
- 支持审计日志
- 支持工作量统计

#### 3.2 自动关注

**分配时自动关注：**

```ruby
def assign_to(user, assigner: Current.user)
  assignments.create!(assignee: user, assigner: assigner)
  watch_by user
  track_event :assigned, assignee_ids: [ user.id ]
end
```

**好处**：
- 被分配者自动收到更新通知
- 提高用户参与度
- 简化用户操作

#### 3.3 事件记录

**分配时记录事件：**

```ruby
track_event :assigned, assignee_ids: [ user.id ]
```

**好处**：
- 支持审核日志
- 支持通知系统
- 支持统计分析

#### 3.4 处理重复分配

**使用 `rescue` 处理重复分配：**

```ruby
rescue ActiveRecord::RecordNotUnique
  # Already assigned
end
```

**好处**：
- 避免错误
- 幂等操作
- 提高用户体验

#### 3.5 切换分配

**支持切换分配状态：**

```ruby
def toggle_assignment(user)
  if assigned_to?(user)
    unassign_from(user)
  else
    assign_to(user)
  end
end
```

**好处**：
- 简化用户操作
- 支持快速切换
- 提高用户体验

### 4. 用户模型集成

**在 User 模型中添加分配关联：**

```ruby
module User::Assignee
  extend ActiveSupport::Concern

  included do
    has_many :assignments, foreign_key: :assignee_id, dependent: :destroy
    has_many :assigned_cards, through: :assignments, source: :card
  end
end
```

### 5. 使用示例

#### 5.1 分配任务

```ruby
card.assign_to(user)
```

#### 5.2 取消分配

```ruby
card.unassign_from(user)
```

#### 5.3 切换分配

```ruby
card.toggle_assignment(user)
```

#### 5.4 查询分配的任务

```ruby
assigned_cards = user.assigned_cards
```

#### 5.5 检查是否已分配

```ruby
card.assigned_to?(user)
```

### 6. 控制器设计

```ruby
class Cards::AssignmentsController < ApplicationController
  include CardScoped

  def create
    @card.assign_to(User.find(params[:assignee_id]))
    redirect_to @card
  end

  def destroy
    @card.unassign_from(User.find(params[:assignee_id]))
    redirect_to @card
  end
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Card、Task、Issue 等）
2. **记录分配者和被分配者**：同时记录分配者和被分配者
3. **自动关注**：分配时自动关注
4. **事件记录**：分配时记录事件
5. **处理重复分配**：使用 `rescue` 处理重复分配
6. **切换分配**：支持切换分配状态

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Assignment 模型
class Assignment < ApplicationRecord
  belongs_to :account, default: -> { assignable.account }
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :assignee, class_name: "User"
  belongs_to :assigner, class_name: "User"
end

# 通用 Assignable Concern
module Assignable
  extend ActiveSupport::Concern

  included do
    has_many :assignments, as: :assignable, dependent: :destroy
    has_many :assignees, through: :assignments, source: :assignee
  end

  def assign_to(user, assigner: Current.user)
    assignments.create!(assignee: user, assigner: assigner)
  end
end

# 在任何模型中使用
class Card < ApplicationRecord
  include Assignable
end

class Task < ApplicationRecord
  include Assignable
end
```

#### 7.2 实现步骤

1. **创建 Assignment 模型**
   - **使用多态关联**：`belongs_to :assignable, polymorphic: true`
   - 添加关联（account, assignee, assigner）
   - 添加唯一索引（assignable_type, assignable_id, assignee_id）

2. **创建通用 Assignable Concern**
   - 使用 `as: :assignable` 支持多态
   - 实现 `assign_to` 和 `unassign_from` 方法
   - 实现 `assigned_to?` 查询方法
   - 实现 `toggle_assignment` 方法

3. **在模型中集成**
   - 包含 `Assignable` Concern（任何模型都可以）
   - 添加必要的关联
   - 集成 Watchable 和 Eventable

4. **实现控制器**
   - 创建通用的 AssignmentsController（支持多态）
   - 实现分配/取消分配操作
   - 处理权限检查

5. **实现视图**
   - 创建分配界面
   - 显示分配者列表
   - 实现实时更新

## 参考资料

- [Fizzy Assignment 模型](https://github.com/basecamp/fizzy/blob/main/app/models/assignment.rb)
- [Fizzy Assignable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/card/assignable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

