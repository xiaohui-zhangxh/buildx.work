---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、置顶系统、Pin、多态关联
description: 总结从 Basecamp Fizzy 项目学习到的置顶系统设计，包括 Pin 模型、Pinnable Concern、用户级别的置顶、实时更新等功能
---

# Fizzy 置顶系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的置顶系统设计。置顶系统允许用户将重要的卡片置顶，方便快速访问。

## 核心设计

### 1. Pin 模型

**Fizzy 的实现（仅支持 Card）：**

```ruby
class Pin < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :card
  belongs_to :user

  scope :ordered, -> { order(created_at: :desc) }
end
```

**改进建议（使用多态关联，支持万能模型）：**

```ruby
class Pin < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :pinnable, polymorphic: true
  belongs_to :user

  scope :ordered, -> { order(created_at: :desc) }
end
```

**关键点**：
- 置顶属于用户（每个用户有自己的置顶列表）
- 使用 `created_at` 排序（后置顶的在前）
- 简单的关联关系
- **⭐ 使用多态关联**：支持任何模型（Card、Post、Article 等）

**多态关联的优势**：
- ✅ **通用性**：一个置顶系统可以用于多种模型
- ✅ **可扩展性**：未来添加新模型时无需修改 Pin 表结构
- ✅ **代码复用**：同一套置顶逻辑可以应用到不同模型

### 2. Pinnable Concern

**Fizzy 的实现（Card 专用）：**

```ruby
module Card::Pinnable
  extend ActiveSupport::Concern

  included do
    has_many :pins, dependent: :destroy
    has_many :pinned_by_users, through: :pins, source: :user
  end

  def pinned_by?(user)
    pins.exists?(user: user)
  end

  def pin_by(user)
    pins.find_or_create_by!(user: user)
  end

  def unpin_by(user)
    pins.find_by(user: user)&.destroy
  end
end
```

**改进建议（通用 Pinnable Concern）：**

```ruby
module Pinnable
  extend ActiveSupport::Concern

  included do
    has_many :pins, as: :pinnable, dependent: :destroy
    has_many :pinned_by_users, through: :pins, source: :user
  end

  def pinned_by?(user)
    pins.exists?(user: user)
  end

  def pin_by(user)
    pins.find_or_create_by!(user: user)
  end

  def unpin_by(user)
    pins.find_by(user: user)&.destroy
  end
end
```

**关键改进**：
- 使用 `as: :pinnable` 支持多态关联
- 移除了 `Card::` 命名空间，使其更通用
- 可以在任何模型中包含（Card、Post、Article 等）

### 3. 关键设计点

#### 3.1 用户级别的置顶

**每个用户有自己的置顶列表：**

```ruby
belongs_to :user
```

**好处**：
- 个性化置顶
- 不影响其他用户
- 易于查询和管理

#### 3.2 简单的置顶/取消置顶

**使用 `find_or_create_by!` 和 `destroy`：**

```ruby
def pin_by(user)
  pins.find_or_create_by!(user: user)
end

def unpin_by(user)
  pins.find_by(user: user)&.destroy
end
```

**好处**：
- 简单的实现
- 避免重复置顶
- 支持快速取消

#### 3.3 排序

**按创建时间倒序排序：**

```ruby
scope :ordered, -> { order(created_at: :desc) }
```

**好处**：
- 后置顶的在前
- 符合用户预期
- 易于实现

### 4. 用户模型集成

**在 User 模型中添加置顶关联：**

```ruby
class User < ApplicationRecord
  has_many :pins, dependent: :destroy
  has_many :pinned_cards, through: :pins, source: :card
end
```

### 5. 使用示例

#### 5.1 置顶卡片

```ruby
card.pin_by(Current.user)
```

#### 5.2 取消置顶

```ruby
card.unpin_by(Current.user)
```

#### 5.3 查询置顶的卡片

```ruby
pinned_cards = Current.user.pinned_cards.ordered
```

#### 5.4 检查是否置顶

```ruby
card.pinned_by?(Current.user)
```

### 6. 控制器设计

```ruby
class Cards::PinsController < ApplicationController
  include CardScoped

  def create
    @pin = @card.pin_by Current.user

    broadcast_add_pin_to_tray
    render_pin_button_replacement
  end

  def destroy
    @pin = @card.unpin_by Current.user

    broadcast_remove_pin_from_tray
    render_pin_button_replacement
  end

  private
    def broadcast_add_pin_to_tray
      @pin.broadcast_prepend_to [ Current.user, :pins_tray ], 
        target: "pins", 
        partial: "my/pins/pin"
    end

    def broadcast_remove_pin_from_tray
      @pin.broadcast_remove_to [ Current.user, :pins_tray ]
    end

    def render_pin_button_replacement
      render turbo_stream: turbo_stream.replace(
        [ @card, :pin_button ], 
        partial: "cards/pins/pin_button", 
        locals: { card: @card }
      )
    end
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：⭐ **使用多态关联支持万能模型**（Card、Post、Article 等）
2. **用户级别的置顶**：每个用户有自己的置顶列表
3. **简单的置顶/取消置顶**：使用 `find_or_create_by!` 和 `destroy`
4. **排序**：按创建时间倒序排序
5. **实时更新**：使用 Turbo Streams 实现实时更新

#### 7.2 改进设计（推荐）

**使用多态关联的通用设计：**

```ruby
# Pin 模型
class Pin < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :pinnable, polymorphic: true
  belongs_to :user
end

# 通用 Pinnable Concern
module Pinnable
  extend ActiveSupport::Concern

  included do
    has_many :pins, as: :pinnable, dependent: :destroy
    has_many :pinned_by_users, through: :pins, source: :user
  end

  def pin_by(user)
    pins.find_or_create_by!(user: user)
  end
end

# 在任何模型中使用
class Card < ApplicationRecord
  include Pinnable
end

class Post < ApplicationRecord
  include Pinnable
end
```

#### 7.2 实现步骤

1. **创建 Pin 模型**
   - **使用多态关联**：`belongs_to :pinnable, polymorphic: true`
   - 添加关联（account, user）
   - 添加排序作用域

2. **创建通用 Pinnable Concern**
   - 使用 `as: :pinnable` 支持多态
   - 实现 `pin_by` 和 `unpin_by` 方法
   - 实现 `pinned_by?` 查询方法

3. **在模型中集成**
   - 包含 `Pinnable` Concern（任何模型都可以）
   - 添加必要的关联

4. **实现控制器**
   - 创建通用的 PinsController（支持多态）
   - 实现置顶/取消置顶操作
   - 实现实时广播

5. **实现视图**
   - 创建置顶按钮
   - 创建置顶托盘
   - 实现实时更新

## 参考资料

- [Fizzy Pin 模型](https://github.com/basecamp/fizzy/blob/main/app/models/pin.rb)
- [Fizzy Pinnable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/card/pinnable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

