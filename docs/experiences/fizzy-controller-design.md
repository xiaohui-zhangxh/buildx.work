---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、控制器设计
status: 已完成
tags: Fizzy、控制器设计、Controller Design、薄控制器
description: 总结从 Basecamp Fizzy 项目学习到的控制器设计模式，包括薄控制器设计、使用 Concerns 组织共享逻辑、权限控制方式等
---

# Fizzy 控制器设计模式

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的控制器设计模式。Fizzy 的控制器设计体现了"薄控制器 + 丰富的领域模型"的理念。

## 核心设计原则

### 1. 薄控制器

**控制器保持简洁，直接调用模型方法：**

```ruby
class CardsController < ApplicationController
  include FilterScoped

  before_action :set_board, only: %i[ create ]
  before_action :set_card, only: %i[ show edit update destroy ]
  before_action :ensure_permission_to_administer_card, only: %i[ destroy ]

  def create
    card = @board.cards.find_or_create_by!(creator: Current.user, status: "drafted")
    redirect_to card
  end

  def update
    @card.update! card_params
  end

  def destroy
    @card.destroy!
    redirect_to @card.board, notice: "Card deleted"
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:id])
    end

    def card_params
      params.expect(card: [ :status, :title, :description, :image, tag_ids: [] ])
    end
end
```

**关键点**：
- 控制器只负责协调，不包含业务逻辑
- 直接调用模型方法
- 使用 `before_action` 组织共享逻辑
- 权限检查封装在私有方法中

### 2. 使用 Concerns 组织共享逻辑

#### 2.1 Application Controller

**使用 Concerns 组织共享逻辑：**

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include BlockSearchEngineIndexing
  include CurrentRequest, CurrentTimezone, SetPlatform
  include RequestForgeryProtection
  include TurboFlash, ViewTransitions
  include RoutingHeaders

  etag { "v1" }
  stale_when_importmap_changes
  allow_browser versions: :modern
end
```

**好处**：
- 功能模块化
- 易于测试
- 易于维护

#### 2.2 Scoped Concerns

**使用 Scoped Concerns 封装资源查找逻辑：**

```ruby
# CardScoped
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:id])
    end
end

# 使用
class Cards::CommentsController < ApplicationController
  include CardScoped
end
```

**好处**：
- 复用资源查找逻辑
- 统一权限检查
- 减少重复代码

### 3. 参数处理

#### 3.1 使用 `params.expect`

**使用 `params.expect` 而不是 `params.require`：**

```ruby
def card_params
  params.expect(card: [ :status, :title, :description, :image, tag_ids: [] ])
end
```

**好处**：
- 更灵活的参数验证
- 支持嵌套数组（如 `tag_ids: []`）
- 更清晰的参数结构

#### 3.2 参数默认值

**使用 `with_defaults` 提供参数默认值：**

```ruby
def create
  @board = Board.create! board_params.with_defaults(all_access: true)
  redirect_to board_path(@board)
end
```

### 4. 权限控制

#### 4.1 权限检查封装

**将权限检查封装在私有方法中：**

```ruby
before_action :ensure_permission_to_administer_card, only: %i[ destroy ]

private
  def ensure_permission_to_administer_card
    head :forbidden unless Current.user.can_administer_card?(@card)
  end
end
```

**好处**：
- 清晰的权限检查逻辑
- 易于测试
- 易于维护

#### 4.2 使用 `head` 返回状态码

**使用 `head` 返回简单的 HTTP 状态码：**

```ruby
def ensure_permission_to_administer_card
  head :forbidden unless Current.user.can_administer_card?(@card)
end
```

### 5. 响应处理

#### 5.1 重定向策略

**使用清晰的重定向：**

```ruby
def create
  card = @board.cards.find_or_create_by!(creator: Current.user, status: "drafted")
  redirect_to card
end

def destroy
  @card.destroy!
  redirect_to @card.board, notice: "Card deleted"
end
```

**关键点**：
- 创建后重定向到资源
- 删除后重定向到父资源
- 使用 `notice` 提供反馈

#### 5.2 Turbo Stream 响应

**使用 Turbo Stream 实现实时更新：**

```ruby
def update
  @card.update! card_params
  # 默认渲染 update.turbo_stream.erb
end
```

**视图文件（update.turbo_stream.erb）：**

```erb
<%= turbo_stream.replace [ @card, :container ], partial: "cards/card", locals: { card: @card } %>
```

#### 5.3 条件响应

**根据条件返回不同的响应：**

```ruby
def update
  @board.update! board_params
  @board.accesses.revise granted: grantees, revoked: revokees if grantees_changed?

  if @board.accessible_to?(Current.user)
    redirect_to edit_board_path(@board), notice: "Saved"
  else
    redirect_to root_path, notice: "Saved (you were removed from the board)"
  end
end
```

### 6. 资源查找

#### 6.1 使用作用域查找资源

**使用模型作用域查找资源：**

```ruby
def set_card
  @card = Current.user.accessible_cards.find_by!(number: params[:id])
end
```

**好处**：
- 自动应用权限过滤
- 统一的查找逻辑
- 易于维护

#### 6.2 使用 `find_by!` 处理不存在的情况

**使用 `find_by!` 自动抛出异常：**

```ruby
def set_card
  @card = Current.user.accessible_cards.find_by!(number: params[:id])
end
```

**好处**：
- 自动处理 404
- 减少重复代码
- 清晰的错误处理

### 7. 缓存控制

#### 7.1 ETag 缓存

**使用 ETag 控制缓存：**

```ruby
class ApplicationController < ActionController::Base
  etag { "v1" }
end

def show_columns
  cards = @board.cards.awaiting_triage.latest.with_golden_first.preloaded
  set_page_and_extract_portion_from cards
  fresh_when etag: [ @board, @page.records, @user_filtering ]
end
```

**好处**：
- 减少服务器负载
- 提高响应速度
- 自动处理缓存验证

#### 7.2 条件缓存

**根据条件控制缓存：**

```ruby
def show
  fresh_when etag: @card.pin_for(Current.user) || "none"
end
```

### 8. 应用到 BuildX

#### 8.1 建议采用的实践

1. **薄控制器**：保持控制器简洁，业务逻辑在模型中
2. **使用 Concerns**：组织共享逻辑
3. **参数处理**：使用 `params.expect`
4. **权限检查**：封装在私有方法中
5. **资源查找**：使用模型作用域
6. **响应处理**：使用 Turbo Stream 实现实时更新
7. **缓存控制**：使用 ETag 控制缓存

#### 8.2 实现步骤

1. **创建 Application Controller**
   - 添加共享 Concerns
   - 配置 ETag 缓存
   - 设置浏览器支持

2. **创建 Scoped Concerns**
   - 为每个资源创建 Scoped Concern
   - 实现资源查找逻辑
   - 实现权限检查

3. **实现控制器**
   - 保持控制器简洁
   - 使用 `before_action` 组织逻辑
   - 直接调用模型方法

4. **实现响应处理**
   - 使用 Turbo Stream 实现实时更新
   - 使用重定向提供反馈
   - 使用 ETag 控制缓存

## 参考资料

- [Fizzy CardsController](https://github.com/basecamp/fizzy/blob/main/app/controllers/cards_controller.rb)
- [Fizzy ApplicationController](https://github.com/basecamp/fizzy/blob/main/app/controllers/application_controller.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

