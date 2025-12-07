---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、访问控制、Access、权限管理、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的访问控制系统设计，包括 Access 模型、Accessible Concern、访问级别（Involvement）、访问历史记录等功能
---

# Fizzy 访问控制系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的访问控制系统设计。访问控制系统管理用户对资源的访问权限，支持访问级别和访问历史记录。

## 核心设计

### 1. Access 模型

**Fizzy 的实现（仅支持 Board）：**

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

  private
    def recently_accessed?
      accessed_at&.> 5.minutes.ago
    end

    def clean_inaccessible_data_later
      Board::CleanInaccessibleDataJob.perform_later(user, board)
    end
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Access < ApplicationRecord
  belongs_to :account, default: -> { accessible.account }
  belongs_to :accessible, polymorphic: true, touch: true
  belongs_to :user, touch: true

  enum :involvement, %i[ access_only watching ].index_by(&:itself), default: :access_only

  scope :ordered_by_recently_accessed, -> { order(accessed_at: :desc) }

  after_destroy_commit :clean_inaccessible_data_later

  def accessed
    touch :accessed_at unless recently_accessed?
  end

  private
    def recently_accessed?
      accessed_at&.> 5.minutes.ago
    end

    def clean_inaccessible_data_later
      # 根据 accessible 类型调用不同的清理任务
      case accessible_type
      when "Board"
        Board::CleanInaccessibleDataJob.perform_later(user, accessible)
      when "Project"
        Project::CleanInaccessibleDataJob.perform_later(user, accessible)
      end
    end
end
```

**关键点**：
- 使用 `involvement` 枚举定义访问级别
- 记录访问时间，避免频繁更新
- 支持最近访问排序
- 删除访问时清理数据
- **⭐ 使用多态关联**：支持任何模型（Board、Project、Workspace 等）

**多态关联的优势**：
- ✅ **通用性**：一个访问控制系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Access 表结构
- ✅ **代码复用**：同一套访问控制逻辑可以应用到不同模型
- ✅ **灵活性**：支持跨模型的访问查询和统计

### 2. 关键设计点

#### 2.1 访问级别（Involvement）

**使用枚举定义访问级别：**

```ruby
enum :involvement, %i[ access_only watching ].index_by(&:itself), default: :access_only
```

**访问级别**：
- `access_only`：仅访问（默认）
- `watching`：关注（自动接收通知）

**好处**：
- 清晰的权限级别
- 易于查询和过滤
- 支持扩展

#### 2.2 访问时间记录

**记录访问时间：**

```ruby
def accessed
  touch :accessed_at unless recently_accessed?
end

private
  def recently_accessed?
    accessed_at&.> 5.minutes.ago
  end
end
```

**好处**：
- 支持访问历史
- 避免频繁更新
- 支持最近访问排序

#### 2.3 最近访问排序

**支持按最近访问排序：**

```ruby
scope :ordered_by_recently_accessed, -> { order(accessed_at: :desc) }
```

**用途**：
- 显示最近访问的看板
- 提高用户体验
- 支持快速访问

#### 2.4 清理不可访问的数据

**删除访问时清理数据：**

```ruby
after_destroy_commit :clean_inaccessible_data_later

private
  def clean_inaccessible_data_later
    Board::CleanInaccessibleDataJob.perform_later(user, board)
  end
end
```

**好处**：
- 自动清理数据
- 保持数据一致性
- 异步处理

### 3. Accessible Concern

**Fizzy 的实现（Board 专用）：**

```ruby
module Board::Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, dependent: :destroy
    has_many :users_with_access, through: :accesses, source: :user
  end

  def accessible_to?(user)
    accesses.exists?(user: user)
  end

  def grant_access_to(user, involvement: :access_only)
    accesses.find_or_create_by!(user: user) do |access|
      access.involvement = involvement
    end
  end

  def revoke_access_from(user)
    accesses.find_by(user: user)&.destroy
  end
end
```

**改进建议（通用 Accessible Concern）：**

```ruby
module Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, as: :accessible, dependent: :destroy
    has_many :users_with_access, through: :accesses, source: :user
    has_many :access_only_users, -> { merge(Access.access_only) }, 
      through: :accesses, source: :user
  end

  def accessible_to?(user)
    accesses.exists?(user: user)
  end

  def grant_access_to(user, involvement: :access_only)
    accesses.find_or_create_by!(user: user) do |access|
      access.involvement = involvement
    end
  end

  def revoke_access_from(user)
    accesses.find_by(user: user)&.destroy
  end

  def access_for(user)
    accesses.find_by(user: user)
  end

  def accessed_by(user)
    access_for(user)&.accessed
  end
end
```

**关键改进**：
- 使用 `as: :accessible` 支持多态关联
- 移除了 `Board::` 命名空间，使其更通用
- 可以在任何模型中包含（Board、Project、Workspace 等）

### 4. 用户模型集成

**在 User 模型中添加访问关联：**

```ruby
module User::Accessor
  extend ActiveSupport::Concern

  included do
    has_many :accesses, dependent: :destroy
    has_many :accessible_boards, through: :accesses, source: :board
  end

  def accessible_cards
    Card.where(board: accessible_boards)
  end
end
```

### 5. 使用示例

#### 5.1 授予访问权限

```ruby
board.grant_access_to(user, involvement: :watching)
```

#### 5.2 撤销访问权限

```ruby
board.revoke_access_from(user)
```

#### 5.3 检查访问权限

```ruby
board.accessible_to?(user)
```

#### 5.4 记录访问

```ruby
access.accessed
```

#### 5.5 查询可访问的资源

```ruby
accessible_cards = user.accessible_cards
accessible_boards = user.accessible_boards.ordered_by_recently_accessed
```

### 6. 控制器设计

```ruby
class Boards::AccessesController < ApplicationController
  include BoardScoped

  def create
    @board.grant_access_to(User.find(params[:user_id]))
    redirect_to @board
  end

  def destroy
    @board.revoke_access_from(User.find(params[:user_id]))
    redirect_to @board
  end
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Board、Project、Workspace 等）
2. **访问级别**：使用枚举定义访问级别
3. **访问时间记录**：记录访问时间，避免频繁更新
4. **最近访问排序**：支持按最近访问排序
5. **清理不可访问的数据**：删除访问时清理数据
6. **Accessible Concern**：使用通用 Concern 组织访问控制逻辑

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Access 模型
class Access < ApplicationRecord
  belongs_to :account, default: -> { accessible.account }
  belongs_to :accessible, polymorphic: true, touch: true
  belongs_to :user, touch: true

  enum :involvement, %i[ access_only watching ], default: :access_only

  scope :ordered_by_recently_accessed, -> { order(accessed_at: :desc) }

  after_destroy_commit :clean_inaccessible_data_later

  def accessed
    touch :accessed_at unless recently_accessed?
  end

  private
    def clean_inaccessible_data_later
      # 根据 accessible 类型调用不同的清理任务
      case accessible_type
      when "Board"
        Board::CleanInaccessibleDataJob.perform_later(user, accessible)
      when "Project"
        Project::CleanInaccessibleDataJob.perform_later(user, accessible)
      end
    end
end

# 通用 Accessible Concern
module Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, as: :accessible, dependent: :destroy
    has_many :users_with_access, through: :accesses, source: :user
    has_many :access_only_users, -> { merge(Access.access_only) }, 
      through: :accesses, source: :user
  end

  def grant_access_to(user, involvement: :access_only)
    accesses.find_or_create_by!(user: user) do |access|
      access.involvement = involvement
    end
  end
end

# 在任何模型中使用
class Board < ApplicationRecord
  include Accessible
end

class Project < ApplicationRecord
  include Accessible
end

class Workspace < ApplicationRecord
  include Accessible
end
```

**优势**：
- ✅ 一个访问控制系统适用于所有模型
- ✅ 未来扩展新模型时无需修改数据库结构
- ✅ 代码复用，减少重复
- ✅ 支持跨模型的访问查询和统计

#### 7.3 实现步骤

1. **创建 Access 模型**
   - **使用多态关联**：`belongs_to :accessible, polymorphic: true`
   - 添加关联（account, user）
   - 添加 `involvement` 枚举
   - 添加 `accessed_at` 字段

2. **创建通用 Accessible Concern**
   - 使用 `as: :accessible` 支持多态
   - 实现 `grant_access_to` 和 `revoke_access_from` 方法
   - 实现 `accessible_to?` 查询方法
   - 实现访问记录方法

3. **在模型中集成**
   - 包含 `Accessible` Concern（任何模型都可以）
   - 添加必要的关联
   - 实现访问逻辑

4. **实现控制器**
   - 创建通用的 AccessesController（支持多态）
   - 实现授予/撤销访问权限操作
   - 处理权限检查

5. **实现清理任务**
   - 为每种模型类型创建清理任务
   - 实现异步处理
   - 测试清理逻辑

## 参考资料

- [Fizzy Access 模型](https://github.com/basecamp/fizzy/blob/main/app/models/access.rb)
- [Fizzy Accessible Concern](https://github.com/basecamp/fizzy/blob/main/app/models/board/accessible.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

