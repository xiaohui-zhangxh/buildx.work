---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、路由设计
status: 已完成
tags: Fizzy、路由设计、Routing、RESTful、路由解析器
description: 总结从 Basecamp Fizzy 项目学习到的路由设计模式，包括 RESTful 资源设计、命名空间使用、路由解析器等
---

# Fizzy 路由设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的路由设计模式。Fizzy 的路由设计体现了 RESTful 原则和清晰的资源组织。

## 核心设计原则

### 1. RESTful 资源设计

**使用资源而不是自定义动作：**

```ruby
# ❌ Bad
resources :cards do
  post :close
  post :reopen
end

# ✅ Good
resources :cards do
  scope module: :cards do
    resource :closure
  end
end
```

**好处**：
- 更符合 RESTful 原则
- 路由更清晰
- 控制器动作更标准

### 2. 命名空间和模块

#### 2.1 使用 `scope module:`

**使用 `scope module:` 组织嵌套资源：**

```ruby
resources :cards do
  scope module: :cards do
    resource :board
    resource :closure
    resource :column
    resource :goldness
    resource :pin
    resource :publish
    resource :reading
    resource :triage
    resource :watch

    resources :assignments
    resources :steps
    resources :taggings

    resources :comments do
      resources :reactions, module: :comments
    end
  end
end
```

**好处**：
- 控制器组织清晰
- 避免命名冲突
- 易于维护

#### 2.2 使用 `namespace`

**使用 `namespace` 组织相关路由：**

```ruby
namespace :account do
  resource :join_code
  resource :settings
  resource :entropy
  resources :exports, only: [ :create, :show ]
end

namespace :public do
  resources :boards do
    scope module: :boards do
      namespace :columns do
        resource :not_now, only: :show
        resource :stream, only: :show
        resource :closed, only: :show
      end

      resources :columns, only: :show
    end

    resources :cards, only: :show
  end
end
```

**好处**：
- 逻辑分组
- URL 结构清晰
- 权限控制方便

### 3. 路由解析器

#### 3.1 使用 `direct`

**使用 `direct` 创建自定义路由辅助方法：**

```ruby
direct :published_board do |board, options|
  route_for :public_board, board.publication.key
end

direct :published_card do |card, options|
  route_for :public_board_card, card.board.publication.key, card
end
```

**使用方式**：

```ruby
published_board_path(@board)
published_card_path(@card)
```

**好处**：
- 简化路由生成
- 隐藏实现细节
- 易于重构

#### 3.2 使用 `resolve`

**使用 `resolve` 为模型创建路由：**

```ruby
resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end

resolve "Mention" do |mention, options|
  polymorphic_url(mention.source, options)
end

resolve "Notification" do |notification, options|
  polymorphic_url(notification.notifiable_target, options)
end

resolve "Event" do |event, options|
  polymorphic_url(event.eventable, options)
end
```

**使用方式**：

```ruby
url_for(@comment)  # => /cards/123#comment_456
url_for(@mention)  # => /cards/123
url_for(@notification)  # => /cards/123
```

**好处**：
- 统一路由生成
- 支持多态关联
- 易于维护

### 4. 路由组织

#### 4.1 嵌套资源

**合理使用嵌套资源：**

```ruby
resources :boards do
  resources :columns
  resources :cards, only: :create
end

resources :columns, only: [] do
  resource :left_position, module: :columns
  resource :right_position, module: :columns
end
```

**关键点**：
- 只在有逻辑关联时嵌套
- 避免过深嵌套（通常不超过 2 层）
- 使用 `only:` 限制路由

#### 4.2 单数资源

**使用单数资源表示唯一资源：**

```ruby
resource :session do
  scope module: :sessions do
    resources :transfers
    resource :magic_link
    resource :menu
  end
end

resource :signup, only: %i[ new create ] do
  collection do
    scope module: :signups, as: :signup do
      resource :completion, only: %i[ new create ]
    end
  end
end
```

**好处**：
- 语义清晰
- 避免 ID 参数
- 符合 RESTful 原则

### 5. 路由重定向

#### 5.1 支持旧 URL

**使用重定向支持旧 URL：**

```ruby
# Support for legacy URLs
get "/collections/:collection_id/cards/:id", to: redirect { |params, request| 
  "#{request.script_name}/cards/#{params[:id]}" 
}

get "/collections/:id", to: redirect { |params, request| 
  "#{request.script_name}/boards/#{params[:id]}" 
}

get "/public/collections/:id", to: redirect { |params, request| 
  "#{request.script_name}/public/boards/#{params[:id]}" 
}
```

**好处**：
- 保持向后兼容
- 支持 URL 迁移
- 不影响现有链接

#### 5.2 使用 Lambda

**使用 Lambda 动态生成重定向 URL：**

```ruby
get "/signup", to: redirect("/signup/new")
```

### 6. 应用到 BuildX

#### 6.1 建议采用的实践

1. **RESTful 资源**：使用资源而不是自定义动作
2. **命名空间**：使用 `scope module:` 和 `namespace` 组织路由
3. **路由解析器**：使用 `resolve` 和 `direct` 创建自定义路由
4. **嵌套资源**：合理使用嵌套，避免过深
5. **单数资源**：使用单数资源表示唯一资源
6. **路由重定向**：支持旧 URL 迁移

#### 6.2 实现步骤

1. **设计路由结构**
   - 识别资源
   - 设计嵌套关系
   - 确定命名空间

2. **实现路由**
   - 使用 RESTful 资源
   - 使用命名空间组织
   - 使用 `only:` 限制路由

3. **创建路由解析器**
   - 使用 `direct` 创建辅助方法
   - 使用 `resolve` 为模型创建路由
   - 支持多态关联

4. **处理旧 URL**
   - 识别需要重定向的旧 URL
   - 实现重定向路由
   - 测试兼容性

## 参考资料

- [Fizzy routes.rb](https://github.com/basecamp/fizzy/blob/main/config/routes.rb)
- [Rails 路由指南](https://guides.rubyonrails.org/routing.html)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

