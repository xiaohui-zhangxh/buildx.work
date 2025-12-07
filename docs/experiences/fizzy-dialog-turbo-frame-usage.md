---
date: 2025-12-26
problem_type: 使用示例、最佳实践、前端开发
status: 已完成
tags: Fizzy、Dialog、Turbo Frame、使用示例、BuildX
description: Dialog + Turbo Frame 在 BuildX 项目中的使用示例
---

# Dialog + Turbo Frame 使用示例

本文档提供了在 BuildX 项目中使用 Dialog + Turbo Frame 实现功能菜单的完整示例。

## 快速开始

### 1. 基本使用

**在视图中添加对话框：**

```erb
<!-- 在页面中添加对话框组件 -->
<%= render "shared/dialog",
    id: "menu-dialog",
    frame_id: :menu_frame,
    url: menu_path,
    title: "功能菜单",
    size: "md" %>

<!-- 触发按钮 -->
<button class="btn btn-primary"
        data-action="click->dialog-manager#open"
        data-dialog-manager-url-value="<%= menu_path %>"
        data-dialog-manager-target="dialog">
  打开菜单
</button>
```

### 2. 控制器实现

**创建菜单控制器：**

```ruby
# app/controllers/menus_controller.rb
class MenusController < ApplicationController
  def show
    # 返回菜单内容，包裹在 turbo_frame_tag 中
    # 不需要布局，只返回 Frame 内容
  end
end
```

**添加路由：**

```ruby
# config/routes.rb
resources :menus, only: [:show]
```

### 3. 菜单视图

**创建菜单视图（`app/views/menus/show.html.erb`）：**

```erb
<%= turbo_frame_tag :menu_frame do %>
  <div class="menu">
    <div class="menu__header mb-4">
      <h2 class="text-xl font-bold">功能菜单</h2>
    </div>
    
    <div class="menu__content">
      <ul class="menu menu-vertical bg-base-200 rounded-lg">
        <li>
          <%= link_to "功能 1", feature1_path,
              class: "menu-item",
              data: { turbo_frame: "_top" } %>
        </li>
        <li>
          <%= link_to "功能 2", feature2_path,
              class: "menu-item",
              data: { turbo_frame: "_top" } %>
        </li>
        <li>
          <%= link_to "功能 3", feature3_path,
              class: "menu-item",
              data: { turbo_frame: "_top" } %>
        </li>
      </ul>
    </div>
  </div>
<% end %>
```

## 完整示例

### 示例 1：用户设置菜单

**视图（`app/views/users/show.html.erb`）：**

```erb
<div class="container mx-auto py-8">
  <h1 class="text-3xl font-bold mb-4">用户设置</h1>
  
  <!-- 对话框组件 -->
  <%= render "shared/dialog",
      id: "user-settings-dialog",
      frame_id: :user_settings_frame,
      url: user_settings_menu_path(current_user),
      title: "设置选项",
      size: "lg" %>

  <!-- 触发按钮 -->
  <button class="btn btn-primary"
          data-action="click->dialog-manager#open"
          data-dialog-manager-url-value="<%= user_settings_menu_path(current_user) %>"
          data-dialog-manager-target="dialog">
    打开设置菜单
  </button>
</div>
```

**控制器（`app/controllers/user_settings_menus_controller.rb`）：**

```ruby
class UserSettingsMenusController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end
end
```

**菜单视图（`app/views/user_settings_menus/show.html.erb`）：**

```erb
<%= turbo_frame_tag :user_settings_frame do %>
  <div class="space-y-4">
    <div class="form-control">
      <label class="label">
        <span class="label-text">用户名</span>
      </label>
      <input type="text" 
             value="<%= @user.name %>"
             class="input input-bordered" />
    </div>

    <div class="form-control">
      <label class="label">
        <span class="label-text">邮箱</span>
      </label>
      <input type="email" 
             value="<%= @user.email %>"
             class="input input-bordered" />
    </div>

    <div class="flex gap-2">
      <button class="btn btn-primary">保存</button>
      <button class="btn btn-ghost" 
              data-action="click->dialog-manager#close">取消</button>
    </div>
  </div>
<% end %>
```

### 示例 2：动态内容菜单

**使用 Stimulus 控制器动态设置 URL：**

```erb
<!-- 对话框 -->
<%= render "shared/dialog",
    id: "dynamic-menu-dialog",
    frame_id: :dynamic_menu_frame,
    title: "动态菜单" %>

<!-- 多个触发按钮，每个按钮打开不同的菜单 -->
<div class="flex gap-2">
  <button class="btn"
          data-controller="dialog-manager"
          data-action="click->dialog-manager#open"
          data-dialog-manager-url-value="<%= menu_path(:users) %>"
          data-dialog-manager-target="dialog">
    用户菜单
  </button>

  <button class="btn"
          data-controller="dialog-manager"
          data-action="click->dialog-manager#open"
          data-dialog-manager-url-value="<%= menu_path(:projects) %>"
          data-dialog-manager-target="dialog">
    项目菜单
  </button>

  <button class="btn"
          data-controller="dialog-manager"
          data-action="click->dialog-manager#open"
          data-dialog-manager-url-value="<%= menu_path(:settings) %>"
          data-dialog-manager-target="dialog">
    设置菜单
  </button>
</div>
```

**控制器处理不同的菜单类型：**

```ruby
class MenusController < ApplicationController
  def show
    @menu_type = params[:id] # users, projects, settings
    
    case @menu_type
    when "users"
      @items = User.all
    when "projects"
      @items = Project.all
    when "settings"
      @items = Setting.all
    end
  end
end
```

**菜单视图（`app/views/menus/show.html.erb`）：**

```erb
<%= turbo_frame_tag :dynamic_menu_frame do %>
  <div class="menu">
    <h3 class="text-lg font-bold mb-4"><%= @menu_type.capitalize %> 菜单</h3>
    
    <ul class="menu menu-vertical">
      <% @items.each do |item| %>
        <li>
          <%= link_to item.name, item,
              class: "menu-item",
              data: { turbo_frame: "_top" } %>
        </li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### 示例 3：表单对话框

**在对话框中加载表单：**

```erb
<!-- 对话框 -->
<%= render "shared/dialog",
    id: "new-item-dialog",
    frame_id: :new_item_frame,
    url: new_item_path,
    title: "新建项目",
    size: "lg" %>

<!-- 触发按钮 -->
<button class="btn btn-primary"
        data-action="click->dialog-manager#open"
        data-dialog-manager-url-value="<%= new_item_path %>"
        data-dialog-manager-target="dialog">
  新建项目
</button>
```

**新建表单视图（`app/views/items/new.html.erb`）：**

```erb
<%= turbo_frame_tag :new_item_frame do %>
  <%= form_with model: @item,
      class: "space-y-4",
      data: { controller: "form" } do |f| %>
    
    <div class="form-control">
      <%= f.label :name, class: "label" %>
      <%= f.text_field :name, class: "input input-bordered" %>
    </div>

    <div class="form-control">
      <%= f.label :description, class: "label" %>
      <%= f.text_area :description, class: "textarea textarea-bordered" %>
    </div>

    <div class="flex gap-2">
      <%= f.submit "创建", class: "btn btn-primary" %>
      <button type="button" 
              class="btn btn-ghost"
              data-action="click->dialog-manager#close">
        取消
      </button>
    </div>
  <% end %>
<% end %>
```

**创建成功后自动关闭对话框（`app/controllers/items_controller.rb`）：**

```ruby
class ItemsController < ApplicationController
  def create
    @item = Item.new(item_params)

    if @item.save
      # 使用 Turbo Stream 关闭对话框
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove("new-item-dialog")
        end
        format.html { redirect_to @item }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :description)
  end
end
```

## 高级用法

### 1. 自定义对话框大小

```erb
<%= render "shared/dialog",
    id: "custom-dialog",
    frame_id: :custom_frame,
    url: custom_path,
    size: "xl" %>  <!-- sm, md, lg, xl, full -->
```

### 2. 无标题对话框

```erb
<%= render "shared/dialog",
    id: "no-title-dialog",
    frame_id: :no_title_frame,
    url: no_title_path %>  <!-- 不设置 title 参数 -->
```

### 3. 多个对话框

```erb
<!-- 对话框 1 -->
<%= render "shared/dialog",
    id: "dialog-1",
    frame_id: :frame_1,
    url: path_1 %>

<!-- 对话框 2 -->
<%= render "shared/dialog",
    id: "dialog-2",
    frame_id: :frame_2,
    url: path_2 %>

<!-- 每个对话框需要唯一的 id 和 frame_id -->
```

### 4. 嵌套对话框

虽然技术上可以嵌套对话框，但不推荐。如果需要，确保每个对话框都有唯一的 ID 和 Frame ID。

## 注意事项

1. **Frame ID 唯一性**：确保每个对话框的 `frame_id` 是唯一的
2. **URL 设置**：可以通过 `url` 参数或 `data-dialog-manager-url-value` 设置
3. **突破 Frame**：需要导航到新页面时，使用 `data: { turbo_frame: "_top" }`
4. **关闭处理**：对话框关闭时会自动清空 Frame 内容
5. **加载状态**：Frame 加载时会显示加载指示器

## 相关文档

- [Fizzy Dialog + Turbo Frame 学习文档](fizzy-dialog-turbo-frame.md)
- [Fizzy Hotwire 使用实践](fizzy-hotwire-practices.md)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-26
- **最后更新**：2025-12-26

