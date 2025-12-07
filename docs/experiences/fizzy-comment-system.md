---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、评论系统、Comment、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的评论系统设计，包括 Comment 模型、Commentable Concern、富文本支持、自动关注、系统评论、反应功能等
---

# Fizzy 评论系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的评论系统设计。评论系统支持富文本、附件、提及、反应等功能。

## 核心设计

### 1. Comment 模型

**Fizzy 的实现（仅支持 Card）：**

```ruby
class Comment < ApplicationRecord
  include Attachments, Eventable, Mentions, Promptable, Searchable

  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  has_many :reactions, -> { order(:created_at) }, dependent: :delete_all

  has_rich_text :body

  scope :chronologically, -> { order created_at: :asc, id: :desc }
  scope :preloaded, -> { with_rich_text_body.includes(reactions: :reacter) }
  scope :by_system, -> { joins(:creator).where(creator: { role: "system" }) }
  scope :by_user, -> { joins(:creator).where.not(creator: { role: "system" }) }

  after_create_commit :watch_card_by_creator

  delegate :board, :watch_by, to: :card

  def to_partial_path
    "cards/#{super}"
  end

  private
    def watch_card_by_creator
      card.watch_by creator
    end
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Comment < ApplicationRecord
  include Attachments, Eventable, Mentions, Promptable, Searchable

  belongs_to :account, default: -> { commentable.account }
  belongs_to :commentable, polymorphic: true, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  has_many :reactions, -> { order(:created_at) }, dependent: :delete_all

  has_rich_text :body

  scope :chronologically, -> { order created_at: :asc, id: :desc }
  scope :preloaded, -> { with_rich_text_body.includes(reactions: :reacter) }
  scope :by_system, -> { joins(:creator).where(creator: { role: "system" }) }
  scope :by_user, -> { joins(:creator).where.not(creator: { role: "system" }) }

  after_create_commit :watch_commentable_by_creator

  def to_partial_path
    "#{commentable_type.underscore.pluralize}/#{super}"
  end

  private
    def watch_commentable_by_creator
      commentable.watch_by(creator) if commentable.respond_to?(:watch_by)
    end
end
```

**关键点**：
- 使用 `has_rich_text :body` 支持富文本
- 支持附件、提及、反应等功能
- 自动关注创建者
- 区分系统评论和用户评论
- **⭐ 使用多态关联**：支持任何模型（Card、Post、Article、Document 等）

**多态关联的优势**：
- ✅ **通用性**：一个评论系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Comment 表结构
- ✅ **代码复用**：同一套评论逻辑可以应用到不同模型
- ✅ **灵活性**：不同模型可以共享评论功能，也可以独立使用

### 2. 关键设计点

#### 2.1 富文本支持

**使用 Action Text 支持富文本：**

```ruby
has_rich_text :body
```

**好处**：
- 支持格式化文本
- 支持附件嵌入
- 支持提及（Mentions）

#### 2.2 自动关注

**评论创建者自动关注父资源：**

**Fizzy 的实现（Card 专用）：**

```ruby
after_create_commit :watch_card_by_creator

private
  def watch_card_by_creator
    card.watch_by creator
  end
end
```

**改进建议（通用设计）：**

```ruby
after_create_commit :watch_commentable_by_creator

private
  def watch_commentable_by_creator
    commentable.watch_by(creator) if commentable.respond_to?(:watch_by)
  end
end
```

**好处**：
- 评论者会自动收到后续更新通知
- 提高用户参与度
- 简化关注流程
- **使用 `respond_to?` 检查**：确保父资源支持关注功能

#### 2.3 系统评论

**区分系统评论和用户评论：**

```ruby
scope :by_system, -> { joins(:creator).where(creator: { role: "system" }) }
scope :by_user, -> { joins(:creator).where.not(creator: { role: "system" }) }
```

**用途**：
- 系统自动生成的评论（如状态变更）
- 审核日志记录
- 自动化通知

#### 2.4 反应（Reactions）

**支持对评论的反应：**

```ruby
has_many :reactions, -> { order(:created_at) }, dependent: :delete_all
```

**好处**：
- 快速反馈
- 减少不必要的评论
- 提高用户参与度

#### 2.5 时间顺序

**按时间顺序显示评论：**

```ruby
scope :chronologically, -> { order created_at: :asc, id: :desc }
```

### 3. Commentable Concern

**改进建议（通用 Commentable Concern）：**

```ruby
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
    has_many :commenters, -> { distinct }, through: :comments, source: :creator
  end

  def comment_count
    comments.count
  end

  def has_comments?
    comments.exists?
  end
end
```

**关键改进**：
- 使用 `as: :commentable` 支持多态关联
- 可以在任何模型中包含（Card、Post、Article 等）
- 提供便捷的查询方法

### 4. 控制器设计

**Fizzy 的实现（Card 专用）：**

```ruby
class Cards::CommentsController < ApplicationController
  include CardScoped

  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_creatorship, only: %i[ edit update destroy ]

  def create
    @comment = @card.comments.create!(comment_params)
  end

  def show
  end

  def edit
  end

  def update
    @comment.update! comment_params
  end

  def destroy
    @comment.destroy
  end

  private
    def set_comment
      @comment = @card.comments.find(params[:id])
    end

    def ensure_creatorship
      head :forbidden if Current.user != @comment.creator
    end

    def comment_params
      params.expect(comment: :body)
    end
end
```

**改进建议（通用 CommentsController）：**

```ruby
class CommentsController < ApplicationController
  before_action :set_commentable
  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_creatorship, only: %i[ edit update destroy ]

  def create
    @comment = @commentable.comments.create!(comment_params)
  end

  def show
  end

  def edit
  end

  def update
    @comment.update! comment_params
  end

  def destroy
    @comment.destroy
  end

  private
    def set_commentable
      @commentable = params[:commentable_type].constantize.find(params[:commentable_id])
    end

    def set_comment
      @comment = @commentable.comments.find(params[:id])
    end

    def ensure_creatorship
      head :forbidden if Current.user != @comment.creator
    end

    def comment_params
      params.expect(comment: :body)
    end
end
```

**路由配置：**

```ruby
# 支持多态路由
resources :cards do
  resources :comments
end

resources :posts do
  resources :comments
end

# 或使用通用路由
resources :comments, only: [:create, :show, :edit, :update, :destroy]
```

### 5. 视图设计

#### 5.1 Turbo Stream 响应

**创建评论后使用 Turbo Stream 更新：**

```erb
<!-- create.turbo_stream.erb -->
<%= turbo_stream.before [ @card, :new_comment ], partial: "cards/comments/comment", locals: { comment: @comment } %>

<%= turbo_stream.update [ @card, :new_comment ], partial: "cards/comments/new", locals: { card: @card } %>
```

**删除评论：**

```erb
<!-- destroy.turbo_stream.erb -->
<%= turbo_stream.remove [ @comment, :container ] %>
```

#### 5.2 Turbo Frame

**使用 Turbo Frame 实现局部更新：**

```erb
<!-- _comment.html.erb -->
<% cache comment do %>
  <%= turbo_frame_tag comment, :container do %>
    <div id="<%= dom_id(comment) %>" class="comment">
      <!-- 评论内容 -->
    </div>
  <% end %>
<% end %>
```

### 6. 应用到 BuildX

#### 6.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Card、Post、Article、Document 等）
2. **富文本支持**：使用 Action Text 支持富文本评论
3. **自动关注**：评论创建者自动关注父资源
4. **系统评论**：区分系统评论和用户评论
5. **反应功能**：支持对评论的反应
6. **Turbo Stream**：使用 Turbo Stream 实现实时更新
7. **Turbo Frame**：使用 Turbo Frame 实现局部更新

#### 6.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Comment 模型
class Comment < ApplicationRecord
  include Attachments, Eventable, Mentions, Promptable, Searchable

  belongs_to :account, default: -> { commentable.account }
  belongs_to :commentable, polymorphic: true, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  has_many :reactions, -> { order(:created_at) }, dependent: :delete_all

  has_rich_text :body

  after_create_commit :watch_commentable_by_creator

  def to_partial_path
    "#{commentable_type.underscore.pluralize}/#{super}"
  end

  private
    def watch_commentable_by_creator
      commentable.watch_by(creator) if commentable.respond_to?(:watch_by)
    end
end

# 通用 Commentable Concern
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
    has_many :commenters, -> { distinct }, through: :comments, source: :creator
  end
end

# 在任何模型中使用
class Card < ApplicationRecord
  include Commentable
end

class Post < ApplicationRecord
  include Commentable
end

class Article < ApplicationRecord
  include Commentable
end
```

**优势**：
- ✅ 一个评论系统适用于所有模型
- ✅ 未来扩展新模型时无需修改数据库结构
- ✅ 代码复用，减少重复
- ✅ 支持跨模型的评论查询和统计

#### 6.3 实现步骤

1. **创建 Comment 模型**
   - **使用多态关联**：`belongs_to :commentable, polymorphic: true`
   - 添加 `has_rich_text :body`
   - 添加关联（account, creator）
   - 添加反应关联

2. **创建通用 Commentable Concern**
   - 使用 `as: :commentable` 支持多态
   - 实现评论关联和查询方法

3. **在模型中集成**
   - 包含 `Commentable` Concern（任何模型都可以）
   - 添加必要的关联
   - 实现评论逻辑

4. **实现自动关注**
   - 在 `after_create_commit` 中调用关注方法
   - 使用 `respond_to?` 检查父资源是否支持关注

5. **实现控制器**
   - 创建通用的 CommentsController（支持多态）
   - 实现 CRUD 操作
   - 使用 Turbo Stream 响应

6. **实现视图**
   - 创建评论表单
   - 创建评论列表
   - 实现 Turbo Stream 模板
   - 使用动态路径生成（`to_partial_path`）

## 参考资料

- [Fizzy Comment 模型](https://github.com/basecamp/fizzy/blob/main/app/models/comment.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

