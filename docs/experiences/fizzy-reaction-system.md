---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、反应系统、Reaction、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的反应系统设计，包括 Reaction 模型、Reactable Concern、表情内容支持、活动时间更新等功能
---

# Fizzy 反应系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的反应系统设计。反应系统允许用户对评论进行快速反馈，支持多种表情。

## 核心设计

### 1. Reaction 模型

**Fizzy 的实现（仅支持 Comment）：**

```ruby
class Reaction < ApplicationRecord
  belongs_to :account, default: -> { comment.account }
  belongs_to :comment, touch: true
  belongs_to :reacter, class_name: "User", default: -> { Current.user }

  scope :ordered, -> { order(:created_at) }

  after_create :register_card_activity

  delegate :all_emoji?, to: :content
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Reaction < ApplicationRecord
  belongs_to :account, default: -> { reactable.account }
  belongs_to :reactable, polymorphic: true, touch: true
  belongs_to :reacter, class_name: "User", default: -> { Current.user }

  scope :ordered, -> { order(:created_at) }

  after_create :register_activity

  delegate :all_emoji?, to: :content

  private
    def register_activity
      # 根据 reactable 类型调用不同的方法
      reactable.touch_last_active_at if reactable.respond_to?(:touch_last_active_at)
    end
end
```

**关键点**：
- 反应属于可反应资源（Comment、Post、Article 等）
- 使用 `reacter` 记录反应者
- 使用 `touch: true` 更新资源时间戳
- 支持表情内容（`content` 字段）
- **⭐ 使用多态关联**：支持任何模型

**多态关联的优势**：
- ✅ **通用性**：一个反应系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Reaction 表结构
- ✅ **代码复用**：同一套反应逻辑可以应用到不同模型

### 2. 关键设计点

#### 2.1 反应者记录

**使用 `reacter` 记录反应者：**

```ruby
belongs_to :reacter, class_name: "User", default: -> { Current.user }
```

**好处**：
- 清晰的命名（`reacter` 而不是 `user`）
- 自动设置当前用户
- 支持查询和统计

#### 2.2 更新关联资源

**反应创建时更新卡片活动时间：**

```ruby
after_create :register_card_activity

private
  def register_card_activity
    comment.card.touch_last_active_at
  end
end
```

**好处**：
- 保持活动时间准确
- 支持按活动时间排序
- 提高用户体验

#### 2.3 表情内容

**支持表情内容：**

```ruby
delegate :all_emoji?, to: :content
```

**用途**：
- 存储表情符号
- 验证是否为纯表情
- 支持多种表情

#### 2.4 排序

**按创建时间排序：**

```ruby
scope :ordered, -> { order(:created_at) }
```

**好处**：
- 保持反应顺序
- 支持时间线显示
- 易于查询

### 3. Reactable Concern

**Fizzy 的实现（Comment 专用）：**

```ruby
class Comment < ApplicationRecord
  has_many :reactions, -> { order(:created_at) }, dependent: :delete_all

  scope :preloaded, -> { 
    with_rich_text_body.includes(reactions: :reacter) 
  }
end
```

**改进建议（通用 Reactable Concern）：**

```ruby
module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, -> { order(:created_at) }, dependent: :delete_all
  end

  scope :preloaded, -> { 
    includes(reactions: :reacter) 
  }
end
```

**关键点**：
- 使用 `as: :reactable` 支持多态关联
- 使用 `delete_all` 快速删除
- 预加载反应和反应者
- 支持排序
- 可以在任何模型中包含（Comment、Post、Article 等）

### 4. 使用示例

#### 4.1 创建反应

```ruby
# 在 Comment 中使用
reaction = comment.reactions.create!(
  reacter: Current.user,
  content: "👍"
)

# 在 Post 中使用（使用多态关联后）
reaction = post.reactions.create!(
  reacter: Current.user,
  content: "👍"
)
```

#### 4.2 查询反应

```ruby
# 查询评论的所有反应
reactions = comment.reactions.ordered

# 查询用户的反应（跨模型）
user_reactions = user.reactions

# 查询评论的反应数量
reaction_count = comment.reactions.count
```

#### 4.3 删除反应

```ruby
reaction = comment.reactions.find_by(reacter: Current.user)
reaction.destroy
```

### 5. 控制器设计

```ruby
class Cards::Comments::ReactionsController < ApplicationController
  include CardScoped

  before_action :set_comment
  before_action :set_reaction, only: %i[ destroy ]

  def create
    @reaction = @comment.reactions.create!(reaction_params)
  end

  def destroy
    @reaction.destroy
  end

  private
    def set_comment
      @comment = @card.comments.find(params[:comment_id])
    end

    def set_reaction
      @reaction = @comment.reactions.find_by!(reacter: Current.user)
    end

    def reaction_params
      params.expect(reaction: :content)
    end
end
```

### 6. 视图设计

#### 6.1 反应列表

```erb
<div class="reactions">
  <% comment.reactions.group_by(&:content).each do |content, reactions| %>
    <span class="reaction">
      <%= content %>
      <span class="count"><%= reactions.count %></span>
    </span>
  <% end %>
</div>
```

#### 6.2 添加反应

```erb
<%= form_with model: [@card, @comment, Reaction.new], 
    data: { turbo_frame: "reactions_#{@comment.id}" } do |f| %>
  <%= f.text_field :content, placeholder: "Add reaction" %>
  <%= f.submit "React" %>
<% end %>
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Comment、Post、Article 等）
2. **反应者记录**：使用 `reacter` 记录反应者
3. **更新关联资源**：反应创建时更新关联资源
4. **表情内容**：支持表情符号
5. **排序**：按创建时间排序
6. **预加载**：预加载反应和反应者

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Reaction 模型
class Reaction < ApplicationRecord
  belongs_to :account, default: -> { reactable.account }
  belongs_to :reactable, polymorphic: true, touch: true
  belongs_to :reacter, class_name: "User", default: -> { Current.user }
end

# 通用 Reactable Concern
module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, dependent: :destroy
  end
end

# 在任何模型中使用
class Comment < ApplicationRecord
  include Reactable
end

class Post < ApplicationRecord
  include Reactable
end
```

#### 7.2 实现步骤

1. **创建 Reaction 模型**
   - **使用多态关联**：`belongs_to :reactable, polymorphic: true`
   - 添加关联（account, reacter）
   - 添加 `content` 字段
   - 添加回调

2. **创建通用 Reactable Concern**
   - 使用 `as: :reactable` 支持多态
   - 实现反应关联和预加载作用域
   - 实现反应统计

3. **在模型中集成**
   - 包含 `Reactable` Concern（任何模型都可以）
   - 添加必要的关联
   - 实现反应逻辑

4. **实现控制器**
   - 创建通用的 ReactionsController（支持多态）
   - 实现创建/删除操作
   - 处理权限检查

5. **实现视图**
   - 创建反应列表
   - 创建添加反应表单
   - 实现实时更新

## 参考资料

- [Fizzy Reaction 模型](https://github.com/basecamp/fizzy/blob/main/app/models/reaction.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

