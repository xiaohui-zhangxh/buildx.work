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

### 6. 输入验证和防御性编程

#### 6.1 在创建资源前验证输入

**使用 `find_or_initialize_by` 和 `invalid?` 检查，而不是直接 `find_or_create_by!`：**

```ruby
# ❌ Bad（可能导致异常）
def create
  identity = Identity.find_or_create_by!(email_address: params.expect(:email_address))
  # 如果邮箱无效，会抛出异常
end

# ✅ Good（防御性编程）
before_action :set_identity, only: :create

def create
  @join_code.redeem_if { |account| @identity.join(account) }
  # ...
end

private
  def set_identity
    @identity = Identity.find_or_initialize_by(email_address: params.expect(:email_address))

    if @identity.new_record?
      if @identity.invalid?
        head :unprocessable_entity
      else
        @identity.save!
      end
    end
  end
```

**好处**：
- 避免 Sentry 异常：防止攻击者提交无效数据导致异常
- 更好的错误处理：对于无效输入，返回 422 状态码
- 不显示验证错误：如果浏览器已经验证，不需要显示错误消息
- 使用 `before_action` 将验证逻辑提取到私有方法中

#### 6.2 从 Commit 661a7e5e 学到的经验

**时间**：2025-12-07  
**作者**：Mike Dalessio  
**变更文件**：`app/controllers/join_codes_controller.rb`

Fizzy 团队在 join code 兑换时添加了邮箱验证，避免攻击者提交无效邮箱导致 Sentry 异常。这体现了防御性编程的原则：
- 在创建资源前验证输入
- 对于无效输入，返回 422 状态码，不显示验证错误消息（因为浏览器应该已经验证）
- 使用 `before_action` 将验证逻辑提取到私有方法中

**测试示例**：

```ruby
test "create with invalid email address" do
  without_action_dispatch_exception_handling do
    assert_no_difference -> { Identity.count } do
      assert_no_difference -> { User.count } do
        post join_path(code: @join_code.code, script_name: @account.slug), 
             params: { email_address: "not-a-valid-email" }
      end
    end
    assert_response :unprocessable_entity
  end
end
```

### 7. 资源查找

#### 7.1 使用作用域查找资源

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

#### 7.2 使用 `find_by!` 处理不存在的情况

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

### 8. 嵌套资源

#### 8.1 嵌套资源的路由设计

**使用嵌套资源组织相关资源：**

```ruby
# config/routes.rb
resources :splats do
  resources :comments
end
```

**路由生成**：
- `POST /splats/:splat_id/comments` - 创建评论
- `GET /splats/:splat_id/comments/:id` - 查看评论

#### 8.2 嵌套资源的控制器设计

**控制器使用 `before_action` 设置父资源：**

```ruby
class CommentsController < ApplicationController
  before_action :set_splat

  def create
    @comment = @splat.comments.create(comment_params)
    @comment.save
    redirect_to splat_path(@splat)
  end

  private
    def comment_params
      params.require(:comment).permit(:body)
    end

    def set_splat
      @splat = Splat.find(params[:splat_id])
    end
end
```

**关键点**：
- 使用 `before_action :set_splat` 设置父资源
- 使用 `@splat.comments.create` 创建子资源
- 参数中包含 `splat_id`，从路由中获取

#### 8.3 嵌套资源的视图设计

**表单使用嵌套资源路径：**

```erb
<%= form_with model: [@splat, @splat.comments.build], class: "flex flex-column gap full-width" do | form | %>
  <%= form.text_area :body, class: "input full-width", required: true, placeholder: "Type your comment…", rows: 4 %>
  <%= form.button class: "btn btn--reversed center" do %>
    Save
  <% end %>
<% end %>
```

**关键点**：
- 使用 `[@splat, @splat.comments.build]` 构建嵌套资源路径
- 表单会自动提交到 `POST /splats/:splat_id/comments`

**从 Commit 6860a0ea 学到的经验**：

**时间**：2024-08-19  
**作者**：Jason Zimdars  
**变更文件**：
- `app/controllers/comments_controller.rb`
- `app/views/comments/_new.html.erb`
- `app/views/splats/show.html.erb`
- `config/routes.rb`

Fizzy 团队创建了评论系统，使用 Rails 嵌套资源的标准模式。这体现了：
- 使用嵌套资源组织相关资源
- 控制器使用 `before_action` 设置父资源
- 视图使用嵌套资源路径构建表单

### 8.4 提取共享的 before_action 到 Concern

**当多个控制器共享相同的 `before_action` 时，提取到 Concern：**

```ruby
# app/controllers/concerns/bubble_scoped.rb
module BubbleScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_bubble
  end

  private
    def set_bubble
      @bubble = Bubble.find(params[:bubble_id])
    end
end

# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  include BubbleScoped

  def create
    @bubble.comments.create!(comment_params)
    redirect_to @bubble
  end

  private
    def comment_params
      params.require(:comment).permit(:body)
    end
end

# app/controllers/boosts_controller.rb
class BoostsController < ApplicationController
  include BubbleScoped

  def create
    @bubble.boosts.create!
  end
end
```

**关键点**：
- 使用 Concern 组织共享的 `before_action`
- 多个控制器共享相同的父资源设置逻辑
- 体现了 DRY 原则和代码组织的最佳实践

**从 Commit 7f45b8fe 学到的经验**：

**时间**：2024-09-13  
**作者**：Jeffrey Hardy  
**变更文件**：
- `app/controllers/concerns/bubble_scoped.rb`（新建）
- `app/controllers/comments_controller.rb`
- `app/controllers/boosts_controller.rb`

Fizzy 团队将多个控制器共享的 `set_bubble` before_action 提取到 `BubbleScoped` Concern。这体现了：
- 使用 Concern 组织共享的 before_action
- 减少代码重复
- 提高代码可维护性

### 9. 认证和权限控制

#### 9.1 只有活跃用户才能认证

**在认证时检查用户是否活跃：**

```ruby
# app/controllers/sessions_controller.rb
def create
  if user = User.active.authenticate_by(params.permit(:email_address, :password))
    start_new_session_for user
    redirect_to after_authentication_url
  else
    # ...
  end
end
```

**关键点**：
- 使用 `User.active.authenticate_by` 而不是 `User.authenticate_by`
- 确保只有活跃用户才能登录
- 体现了安全性和权限控制的最佳实践

**从 Commit 1d2de248 学到的经验**：

**时间**：2024-09-24  
**作者**：Jeffrey Hardy  
**变更文件**：`app/controllers/sessions_controller.rb`

Fizzy 团队在认证时添加了活跃用户检查。这体现了：
- 安全性考虑：只有活跃用户才能认证
- 使用作用域链式调用，代码简洁
- 体现了防御性编程的思路

### 10. 参数处理

#### 10.1 提取参数处理逻辑

**在视图中提取参数处理逻辑，便于复用：**

```erb
<!-- ❌ Old（重复的参数处理） -->
<% Current.account.tags.order(:title).each do |tag| %>
  <li><%= link_to tag.title, bucket_bubbles_path(bucket, params.permit(:filter, :assignee_id).merge(tag_id: tag.id)) %></li>
<% end %>

<% if tag %>
  <%= link_to bucket_bubbles_path(bucket, params.permit(:filter, :assignee_id)), class: "btn" do %>
    Clear
  <% end %>
<% end %>

<!-- ✅ New（提取参数处理） -->
<% filter_params = params.permit(:filter, :tag_id, :assignee_id) %>

<% Current.account.tags.order(:title).each do |tag| %>
  <li><%= link_to tag.title, bucket_bubbles_path(bucket, filter_params.merge(tag_id: tag.id)) %></li>
<% end %>

<% if tag %>
  <%= link_to bucket_bubbles_path(bucket, filter_params.without(:tag_id)), class: "btn" do %>
    Clear
  <% end %>
<% end %>
```

**关键点**：
- 在视图顶部提取参数处理逻辑
- 使用 `params.permit` 提取允许的参数
- 使用 `filter_params.merge` 合并新参数
- 使用 `filter_params.without` 移除参数
- 减少重复代码，提高可维护性

**从 Commit a14b4e10 学到的经验**：

**时间**：2024-10-04  
**作者**：Jeffrey Hardy  
**变更文件**：`app/views/bubbles/_filters.html.erb`

Fizzy 团队提取了过滤参数处理逻辑，避免了重复的 `params.permit` 调用。这体现了：
- 在视图中提取参数处理逻辑，便于复用
- 使用 `merge` 和 `without` 方法操作参数
- 减少重复代码，提高可维护性

### 8. 架构重构：从嵌套到独立资源

#### 8.1 将过滤器从 Bucket 中解耦

**将过滤器从 Bucket 中解耦，创建独立的 Filter 模型：**

```ruby
# ❌ Old（嵌套在 Bucket 中）
class Bucket < ApplicationRecord
  has_many :views, class_name: "Bucket::View"
end

class Bucket::View < ApplicationRecord
  belongs_to :bucket
  belongs_to :creator, class_name: "User"
end

# app/controllers/buckets/views_controller.rb
class Buckets::ViewsController < ApplicationController
  include BucketScoped

  def create
    @view = @bucket.views.create! filters: filter_params
    redirect_to bucket_bubbles_path(@bucket, **filter_params.merge(view_id: @view.id))
  end
end

# ✅ New（独立的 Filter 模型）
class Filter < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  has_one :account, through: :creator
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :buckets
  has_and_belongs_to_many :assignees, class_name: "User"
end

# app/controllers/filters_controller.rb
class FiltersController < ApplicationController
  def create
    @filter = Current.user.filters.create_or_find_by_params!(filter_params).tap(&:touch)
    redirect_to bubbles_path(@filter.to_params)
  end
end

# app/controllers/bubbles_controller.rb
class BubblesController < ApplicationController
  include BucketScoped

  skip_before_action :set_bucket, only: :index

  before_action :set_filter, only: :index

  def index
    @bubbles = @filter.bubbles
    @bubbles = @bubbles.mentioning(params[:term]) if params[:term].present?
  end

  private
    def set_filter
      @filter = Current.user.filters.build params.permit(*Filter::KNOWN_PARAMS)
    end
end
```

**关键点**：
- 将过滤器从 bucket 级别提升到用户级别
- 使用独立的 `Filter` 模型和 `FiltersController`
- 使用 `skip_before_action` 跳过某些动作的 before_action
- 使用 `create_or_find_by_params!` 避免重复创建相同的过滤器
- 体现了架构演进和代码重构的最佳实践

**从 Commit f2706d0f 学到的经验**：

**时间**：2024-11-05  
**作者**：Jose Farias  
**变更文件**：
- 删除了 `Bucket::View` 相关模型和控制器
- 创建了独立的 `Filter` 模型和 `FiltersController`
- 重构了过滤器系统架构

Fizzy 团队将过滤器从 Bucket 中解耦，创建独立的 Filter 模型。这体现了：
- 架构演进的重要性
- 从嵌套资源到独立资源的重构
- 代码解耦和模块化的最佳实践

#### 8.2 将嵌套控制器移到顶层

**将嵌套的控制器移到顶层，简化架构：**

```ruby
# ❌ Old（嵌套在命名空间中）
class ActionText::Markdown::UploadsController < ApplicationController
  include ActiveStorage::SetCurrent

  def create
    # ...
  end
end

# config/routes.rb
namespace :action_text, path: nil do
  get "/u/*slug" => "markdown/uploads#show", as: :markdown_upload
  post "/uploads" => "markdown/uploads#create", as: :markdown_uploads
end

# ✅ New（顶层控制器）
class UploadsController < ApplicationController
  include ActiveStorage::SetCurrent

  def create
    # ...
  end
end

# config/routes.rb
resources :uploads, only: :create
get "/u/*slug" => "uploads#show", as: :upload
```

**关键点**：
- 将嵌套的控制器移到顶层，简化架构
- 更新路由和 helper 方法
- 减少命名空间的复杂性
- 体现了架构简化的最佳实践

**从 Commit 6164da2e 学到的经验**：

**时间**：2024-11-29  
**作者**：Jose Farias  
**变更文件**：
- 将 `ActionText::Markdown::UploadsController` 移到顶层 `UploadsController`
- 更新了路由和 helper 方法

Fizzy 团队将嵌套的控制器移到顶层，简化了架构。这体现了：
- 架构简化的最佳实践
- 减少命名空间的复杂性
- 提高代码可读性和可维护性

### 9. 缓存控制

#### 8.1 ETag 缓存

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

#### 8.2 条件缓存

**根据条件控制缓存：**

```ruby
def show
  fresh_when etag: @card.pin_for(Current.user) || "none"
end
```

### 10. 应用到 BuildX

#### 10.1 建议采用的实践

1. **薄控制器**：保持控制器简洁，业务逻辑在模型中
2. **使用 Concerns**：组织共享逻辑
3. **参数处理**：使用 `params.expect`
4. **权限检查**：封装在私有方法中
5. **资源查找**：使用模型作用域
6. **响应处理**：使用 Turbo Stream 实现实时更新
7. **缓存控制**：使用 ETag 控制缓存

#### 10.2 实现步骤

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
- **最后更新**：2025-12-08

