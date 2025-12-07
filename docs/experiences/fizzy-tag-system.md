---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、标签系统、Tag、Tagging、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的标签系统设计，包括 Tag 和 Tagging 模型、Taggable Concern、标签规范化、标签过滤和切换等功能
---

# Fizzy 标签系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的标签系统设计。标签系统支持多对多关系、标签过滤、切换标签等功能。

## 核心设计

### 1. Tag 模型

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

  def cards_count
    cards.open.count
  end
end
```

**关键点**：
- 标签属于 Account（多租户）
- 使用 `normalizes` 自动转换为小写
- 禁止以 `#` 开头（`hashtag` 方法会自动添加）
- 支持查询未使用的标签

### 2. Tagging 模型

**Fizzy 的实现（仅支持 Card）：**

```ruby
class Tagging < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :tag
  belongs_to :card, touch: true
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Tagging < ApplicationRecord
  belongs_to :account, default: -> { taggable.account }
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, touch: true
end
```

**关键点**：
- 多对多关系的中间表
- **使用多态关联**：支持任何模型（Card、Post、Article 等）
- 使用 `touch: true` 更新资源时间戳
- 自动设置 account（从 taggable 获取）

**多态关联的优势**：
- ✅ **通用性**：一个标签系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Tagging 表结构
- ✅ **代码复用**：同一套标签逻辑可以应用到不同模型
- ✅ **灵活性**：不同模型可以共享标签，也可以独立使用

### 3. Taggable Concern

**Fizzy 的实现（Card 专用）：**

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

**改进建议（通用 Taggable Concern）：**

```ruby
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings

    scope :tagged_with, ->(tags) { 
      joins(:taggings).where(taggings: { tag: tags }) 
    }
  end

  def toggle_tag_with(title)
    tag = account.tags.find_or_create_by!(title: title)

    transaction do
      if tagged_with?(tag)
        taggings.destroy_by tag: tag
      else
        taggings.create tag: tag, taggable: self
      end
    end
  end

  def tagged_with?(tag)
    tags.include? tag
  end
end
```

**关键改进**：
- 使用 `as: :taggable` 支持多态关联
- 移除了 `Card::` 命名空间，使其更通用
- 可以在任何模型中包含（Card、Post、Article 等）

### 4. 关键设计点

#### 4.1 多对多关系

**使用标准的多对多关系：**

```ruby
# Tag
has_many :taggings, dependent: :destroy
has_many :cards, through: :taggings

# Card
has_many :taggings, dependent: :destroy
has_many :tags, through: :taggings
```

**好处**：
- 标准 Rails 模式
- 易于查询和过滤
- 支持统计

#### 4.2 标签规范化

**使用 `normalizes` 自动规范化标签：**

```ruby
normalizes :title, with: -> { it.downcase }
```

**好处**：
- 统一标签格式
- 避免重复标签（如 "Ruby" 和 "ruby"）
- 提高查询效率

#### 4.3 切换标签

**使用 `toggle_tag_with` 切换标签：**

```ruby
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
```

**好处**：
- 原子操作
- 自动创建标签
- 支持切换（添加/移除）

#### 4.4 标签过滤

**使用作用域过滤标签：**

```ruby
scope :tagged_with, ->(tags) { joins(:taggings).where(taggings: { tag: tags }) }
```

**使用方式**：

```ruby
cards.tagged_with([tag1, tag2])
```

#### 4.5 Hashtag 支持

**支持 Hashtag 格式：**

```ruby
def hashtag
  "#" + title
end

validates :title, format: { without: /\A#/ }
```

**好处**：
- 显示时自动添加 `#`
- 存储时不包含 `#`
- 避免重复

#### 4.6 标签统计

**支持标签使用统计：**

```ruby
def cards_count
  cards.open.count
end

scope :unused, -> { left_outer_joins(:taggings).where(taggings: { id: nil }) }
```

**用途**：
- 显示标签使用次数
- 查找未使用的标签
- 清理未使用的标签

### 5. 标签附件支持

**标签可以作为附件嵌入到富文本中：**

```ruby
module Tag::Attachable
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar
  end

  def attachable_plain_text_representation
    hashtag
  end
end
```

**好处**：
- 支持在富文本中 @标签
- 自动生成标签链接
- 支持标签头像

### 6. 使用示例

#### 6.1 在 Card 中使用

```ruby
class Card < ApplicationRecord
  include Taggable

  # 切换标签
  card.toggle_tag_with("ruby")
  card.toggle_tag_with("rails")

  # 查询标签
  card.tagged_with?(tag)

  # 过滤标签
  cards.tagged_with([tag1, tag2])
end
```

#### 6.2 控制器中使用

```ruby
class Cards::TaggingsController < ApplicationController
  include CardScoped

  def create
    @card.toggle_tag_with(params[:tag_title])
    redirect_to @card
  end

  def destroy
    @card.toggle_tag_with(params[:tag_title])
    redirect_to @card
  end
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Card、Post、Article 等）
2. **多对多关系**：使用标准的多对多关系
3. **标签规范化**：使用 `normalizes` 自动规范化标签
4. **切换标签**：使用 `toggle_tag_with` 切换标签
5. **标签过滤**：使用作用域过滤标签
6. **Hashtag 支持**：支持 Hashtag 格式
7. **标签统计**：支持标签使用统计

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Tagging 模型
class Tagging < ApplicationRecord
  belongs_to :account, default: -> { taggable.account }
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, touch: true
end

# Tag 模型
class Tag < ApplicationRecord
  belongs_to :account
  has_many :taggings, dependent: :destroy
  has_many :taggables, through: :taggings  # 通用关联
  
  # 如果需要特定模型的统计
  def cards_count
    taggings.where(taggable_type: "Card").joins("INNER JOIN cards ON taggings.taggable_id = cards.id").where(cards: { status: "published" }).count
  end
end

# 通用 Taggable Concern
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end
end

# 在任何模型中使用
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

**优势**：
- ✅ 一个标签系统适用于所有模型
- ✅ 未来扩展新模型时无需修改数据库结构
- ✅ 代码复用，减少重复
- ✅ 支持跨模型的标签查询和统计

#### 7.3 实现步骤

1. **创建 Tag 模型**
   - 添加关联（account, taggings）
   - 添加 `normalizes` 规范化
   - 添加验证和统计方法
   - **使用多态关联**：`has_many :taggables, through: :taggings`

2. **创建 Tagging 模型**
   - **使用多态关联**：`belongs_to :taggable, polymorphic: true`
   - 添加关联（account, tag）
   - 使用 `touch: true` 更新资源

3. **创建通用 Taggable Concern**
   - 使用 `as: :taggable` 支持多态
   - 实现 `toggle_tag_with` 方法
   - 实现 `tagged_with?` 查询方法
   - 实现标签过滤作用域

4. **在模型中集成**
   - 包含 `Taggable` Concern（任何模型都可以）
   - 添加必要的关联
   - 实现标签逻辑

5. **实现控制器**
   - 创建通用的 TaggingsController（支持多态）
   - 实现切换标签操作
   - 处理重定向

6. **实现标签附件支持**
   - 创建 Tag::Attachable Concern
   - 支持在富文本中 @标签
   - 实现标签头像

## 参考资料

- [Fizzy Tag 模型](https://github.com/basecamp/fizzy/blob/main/app/models/tag.rb)
- [Fizzy Tagging 模型](https://github.com/basecamp/fizzy/blob/main/app/models/tagging.rb)
- [Fizzy Taggable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/card/taggable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

