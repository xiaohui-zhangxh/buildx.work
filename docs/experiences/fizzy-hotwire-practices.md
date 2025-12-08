---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、前端开发
status: 已完成
tags: Fizzy、Hotwire、Turbo、Stimulus、实时更新
description: 总结从 Basecamp Fizzy 项目学习到的 Hotwire 使用实践，包括 Turbo Streams、Turbo Frames、Stimulus 控制器组织等
---

# Fizzy Hotwire 使用实践

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的 Hotwire 使用实践。Fizzy 是 Hotwire 的创建者 Basecamp 开发的项目，是 Hotwire 的最佳实践示例。

## 核心组件

Hotwire 包含三个主要组件：
- **Turbo Drive**：增强链接和表单
- **Turbo Frames**：局部更新
- **Turbo Streams**：实时更新
- **Stimulus**：交互逻辑

## 1. Turbo Streams

### 1.1 控制器中的 Turbo Stream

**使用 Turbo Stream 实现实时更新：**

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
      @pin.broadcast_prepend_to [ Current.user, :pins_tray ], target: "pins", partial: "my/pins/pin"
    end

    def broadcast_remove_pin_from_tray
      @pin.broadcast_remove_to [ Current.user, :pins_tray ]
    end

    def render_pin_button_replacement
      render turbo_stream: turbo_stream.replace([ @card, :pin_button ], partial: "cards/pins/pin_button", locals: { card: @card })
    end
end
```

**关键点**：
- 使用 `broadcast_*_to` 广播到特定频道
- 使用 `render turbo_stream:` 渲染 Turbo Stream 响应
- 使用 `turbo_stream.replace` 替换元素

### 1.2 Turbo Stream 视图

**创建 Turbo Stream 视图文件：**

```erb
<!-- create.turbo_stream.erb -->
<%= turbo_stream.before [ @card, :new_comment ], partial: "cards/comments/comment", locals: { comment: @comment } %>

<%= turbo_stream.update [ @card, :new_comment ], partial: "cards/comments/new", locals: { card: @card } %>
```

**可用的 Turbo Stream 操作**：
- `turbo_stream.append` - 追加到目标元素
- `turbo_stream.prepend` - 前置到目标元素
- `turbo_stream.before` - 插入到目标元素之前
- `turbo_stream.after` - 插入到目标元素之后
- `turbo_stream.replace` - 替换目标元素
- `turbo_stream.update` - 更新目标元素内容
- `turbo_stream.remove` - 删除目标元素

### 1.3 广播机制

**使用 `broadcast_*_to` 广播更新：**

```ruby
# 追加到目标
@pin.broadcast_prepend_to [ Current.user, :pins_tray ], target: "pins", partial: "my/pins/pin"

# 删除元素
@pin.broadcast_remove_to [ Current.user, :pins_tray ]

# 替换元素
@card.broadcast_replace_to @card, partial: "cards/card", locals: { card: @card }
```

**广播目标**：
- 单个对象：`@card`
- 数组（用户和频道）：`[ Current.user, :pins_tray ]`
- 字符串频道：`"cards"`

### 1.4 订阅广播

**在视图中订阅广播：**

```erb
<%= turbo_stream_from @card %>
<%= turbo_stream_from @card, :activity %>
```

**好处**：
- 自动接收更新
- 无需手动刷新
- 实时同步

## 2. Turbo Frames

### 2.1 基本使用

**使用 Turbo Frame 实现局部更新：**

```erb
<%= turbo_frame_tag comment, :container do %>
  <div id="<%= dom_id(comment) %>" class="comment">
    <!-- 评论内容 -->
  </div>
<% end %>
```

**关键点**：
- 使用 `turbo_frame_tag` 创建 Frame
- 使用 `dom_id` 生成唯一 ID
- Frame 内的链接和表单自动在 Frame 内更新

### 2.2 Frame 嵌套

**支持 Frame 嵌套：**

```erb
<%= turbo_frame_tag :card_container do %>
  <%= turbo_frame_tag :comments do %>
    <!-- 评论列表 -->
  <% end %>
<% end %>
```

### 2.3 突破 Frame

**使用 `data-turbo-frame="_top"` 突破 Frame：**

```erb
<%= link_to comment.creator.name, comment.creator, 
    class: "txt-ink btn btn--plain fill-transparent", 
    data: { turbo_frame: "_top" } %>
```

**用途**：
- 导航到新页面
- 更新整个页面
- 避免在 Frame 内更新

### 2.4 永久元素

**使用 `data-turbo-permanent` 标记永久元素：**

```erb
<div class="comment__body rich-text-content" data-controller="syntax-highlight retarget-links" data-turbo-permanent>
  <%= comment.body %>
</div>
```

**用途**：
- 防止 Turbo 更新特定元素
- 保留 JavaScript 状态
- 保持交互状态

## 3. Stimulus 控制器

### 3.1 基本结构

**Stimulus 控制器基本结构：**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = [ "element" ]

  connect() {
    // 控制器连接时执行
  }

  disconnect() {
    // 控制器断开时执行
  }

  actionMethod() {
    // 动作方法
  }
}
```

### 3.2 常用控制器

**Fizzy 中常用的 Stimulus 控制器：**

- `dialog_manager_controller.js` - 对话框管理
- `retarget_links_controller.js` - 链接重定向
- `collapsible_columns_controller.js` - 可折叠列
- `fetch_on_visible_controller.js` - 可见时获取
- `navigable_list_controller.js` - 可导航列表
- `syntax_highlight_controller.js` - 语法高亮
- `notifications_tray_controller.js` - 通知托盘

### 3.3 数据绑定

**使用 Values 和 Targets：**

```erb
<div data-controller="beacon" data-beacon-url-value="<%= card_reading_path(@card) %>">
  <!-- 内容 -->
</div>
```

```javascript
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.fetchOnVisible()
  }

  fetchOnVisible() {
    // 使用 this.urlValue 访问值
  }
}
```

### 3.4 自定义删除对话框

**使用 Dialog 元素和 Stimulus 控制器实现自定义删除确认对话框：**

```erb
<!-- app/views/cards/_delete.html.erb -->
<div data-controller="dialog" data-dialog-modal-value="true" data-action="keydown.esc->dialog#close:stop">
  <button type="button" class="btn txt-negative borderless txt-small" data-action="dialog#open">
    <%= icon_tag "trash" %>
    <span>Delete this card</span>
  </button>
  <dialog class="dialog panel fill-white shadow gap flex-column" style="max-width: 40ch" data-dialog-target="dialog">
    <h3 class="txt-large txt-bold">Delete this card?</h3>
    <p class="txt-medium margin-block-half">Are you sure you want to permanently delete this card?</p>
    <div class="flex gap-half justify-center margin-block-start">
      <button type="button" class="btn" data-action="dialog#close">Cancel</button>
      <%= button_to card_path(card), method: :delete, class: "btn txt-negative", data: { turbo_frame: "_top" } do %>
        <span>Delete card</span>
      <% end %>
    </div>
  </dialog>
</div>
```

**关键点**：
- 使用 `<dialog>` 元素提供原生对话框功能
- 使用 `dialog_controller` 管理对话框的打开和关闭
- 删除按钮使用 `button_to` 和 `data: { turbo_frame: "_top" }` 确保正确导航
- 按钮布局使用 `justify-center` 居中显示
- 按 ESC 键关闭对话框（`keydown.esc->dialog#close:stop`）

**替代方案对比**：

```ruby
# ❌ Old（使用 turbo_confirm）
def button_to_delete_card(card)
  button_to card_path(card),
      method: :delete, 
      class: "btn txt-negative borderless txt-small", 
      data: { 
        turbo_frame: "_top", 
        turbo_confirm: "Are you sure you want to permanently delete this card?" 
      } do
    concat(icon_tag("trash"))
    concat(tag.span("Delete this card"))
  end
end

# ✅ New（使用自定义对话框）
# 移除 helper，直接在视图中使用 dialog 元素
```

**好处**：
- 更好的用户体验：自定义对话框提供更好的视觉一致性
- 更灵活：可以自定义对话框的样式和内容
- 更符合现代 Web 标准：使用 HTML5 的 `<dialog>` 元素

**从 Commit 4a6f28b7 学到的经验**：

**时间**：2025-12-07  
**作者**：Jorge Manrubia  
**变更文件**：
- `app/helpers/cards_helper.rb`（移除了 `button_to_delete_card` helper）
- `app/views/cards/_delete.html.erb`（新增自定义删除对话框）
- `app/views/boards/edit/_delete.html.erb`（更新为自定义对话框）

Fizzy 团队用自定义删除模态框替换了 turbo 确认对话框，提供了更好的用户体验和视觉一致性。这体现了：
- 使用 HTML5 的 `<dialog>` 元素
- 使用 Stimulus `dialog_controller` 管理对话框
- 保持代码简洁，移除不必要的 helper

## 4. 视图组织

### 4.1 使用 Partials

**视图通过 Partials 组织：**

```erb
<%= render "cards/container", card: @card %>
<%= render "cards/messages",  card: @card unless @card.drafted? %>
```

**好处**：
- 代码复用
- 易于维护
- 清晰的视图结构

### 4.2 缓存

**使用片段缓存：**

```erb
<% cache comment do %>
  <%= turbo_frame_tag comment, :container do %>
    <!-- 内容 -->
  <% end %>
<% end %>
```

**关键点**：
- 缓存键使用对象本身
- 自动处理缓存失效
- 提高性能

### 4.3 Content For

**使用 `content_for` 组织页面特定内容：**

```erb
<% content_for :head do %>
  <%= card_social_tags(@card) %>
<% end %>

<% content_for :header do %>
  <div class="header__actions header__actions--start">
    <%= link_back_to_board(@card.board) %>
  </div>
<% end %>
```

### 4. Combobox 集成

#### 4.1 使用 hotwire_combobox 实现下拉选择框

**集成 hotwire_combobox gem 实现下拉选择框：**

```ruby
# Gemfile
gem "hotwire_combobox", github: "josefarias/hotwire_combobox", branch: :main
```

**在视图中使用 combobox：**

```erb
<!-- app/views/bubbles/_assignments.html.erb -->
<%= combobox_field_tag :assignee_id,
    options: bubble.assignees.map { |user| [ user.name, user.id ] },
    url: bubble_users_path(bubble),
    placeholder: "Assign to..." %>
```

**创建专门的控制器处理 combobox 操作：**

```ruby
# app/controllers/assignments/swaps_controller.rb
class Assignments::SwapsController < ApplicationController
  include BubbleScoped

  def create
    @assignment = @bubble.assignments.find_or_create_by!(assignee: assignee)
    @assignment.update! assignee: assignee

    render turbo_stream: turbo_stream.replace([ @bubble, :assignments ], partial: "bubbles/assignments")
  end

  private
    def assignee
      User.find(params[:assignee_id])
    end
end

# app/controllers/assignments/toggles_controller.rb
class Assignments::TogglesController < ApplicationController
  include BubbleScoped

  def create
    @assignment = @bubble.assignments.find_or_create_by!(assignee: assignee)
    @assignment.destroy

    render turbo_stream: turbo_stream.replace([ @bubble, :assignments ], partial: "bubbles/assignments")
  end

  private
    def assignee
      User.find(params[:assignee_id])
    end
end
```

**使用 Turbo Streams 实现实时更新：**

```erb
<!-- app/views/bubbles/users/_select_option.turbo_stream.erb -->
<%= turbo_stream.replace [ @bubble, :assignments ], partial: "bubbles/assignments" %>
```

**使用 Stimulus 控制器增强交互：**

```javascript
// app/javascript/controllers/autofocus_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.focus()
  }
}

// app/javascript/controllers/expandable_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content" ]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

**关键点**：
- 使用第三方组件库（hotwire_combobox）实现下拉选择框
- 创建专门的控制器处理 combobox 操作（swaps, toggles）
- 使用 Turbo Streams 实现实时更新
- 使用 Stimulus 控制器增强交互（autofocus, expandable）
- 体现了第三方组件集成和 UI 交互的最佳实践

**从 Commit f266e46b 学到的经验**：

**时间**：2024-11-21  
**作者**：Jose Farias  
**变更文件**：
- 集成了 `hotwire_combobox` gem
- 创建了多个 combobox 相关的控制器和视图
- 重构了 assignments 和 tags 的 UI

Fizzy 团队集成了 hotwire_combobox 实现下拉选择框。这体现了：
- 第三方组件集成的最佳实践
- 使用 Turbo Streams 实现实时更新
- 创建专门的控制器处理交互操作
- 使用 Stimulus 控制器增强交互

### 4.2 动态时间更新

**定期刷新相对时间显示，确保时间始终是最新的：**

```javascript
// app/javascript/controllers/local_time_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ago"]

  connect() {
    this.#refreshInterval = setInterval(() => this.#refreshAgoTargets(), 60000) // 每分钟刷新一次
  }

  disconnect() {
    if (this.#refreshInterval) {
      clearInterval(this.#refreshInterval)
    }
  }

  #refreshAgoTargets() {
    this.agoTargets.forEach(target => {
      const dt = new Date(target.getAttribute("datetime"))
      target.textContent = this.agoFormatter.format(dt)
    })
  }
}
```

**关键点**：
- 使用 `setInterval` 定期刷新相对时间
- 在控制器连接时启动定时器
- 在控制器断开时清理定时器
- 确保时间显示始终是最新的
- 体现了用户体验优化和动态更新的最佳实践

**从 Commit 7189e7a3 学到的经验**：

**时间**：2025-02-05  
**作者**：Kevin McConnell  
**变更文件**：`app/javascript/controllers/local_time_controller.js`

Fizzy 团队定期刷新相对时间显示，确保时间始终是最新的。这体现了：
- 用户体验优化的重要性
- 使用定时器动态更新内容
- 确保时间显示始终准确

### 4.3 自动保存到本地存储

**自动保存表单内容到本地存储，防止丢失工作：**

```javascript
// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = ["input"]
  static values = { key: String }
  
  initialize() {
    this.debouncedSave = debounce(() => {
      const content = this.inputTarget.value
      if (content) {
        localStorage.setItem(this.keyValue, content)
      } else {
        this.clear()
      }
    }, 300)
  }
  
  connect() {
    this.restoreContent()
  }
  
  submit({ detail: { success } }) {
    if (success) {
      this.clear()
    }
  }

  save() {
    this.debouncedSave()
  }
  
  clear() {
    localStorage.removeItem(this.keyValue)
  }
  
  restoreContent() {
    const savedContent = localStorage.getItem(this.keyValue)
    if (savedContent) {
      this.inputTarget.value = savedContent
      this.inputTarget.dispatchEvent(new CustomEvent('house-md:change', {
        bubbles: true,
        detail: { 
          previousContent: '',
          newContent: savedContent 
        }
      }))
    }
  }
}
```

**在视图中使用：**

```erb
<!-- app/views/comments/_new.html.erb -->
<%= form_with model: Comment.new, url: bucket_bubble_comments_path(bubble.bucket, bubble),
      data: { controller: "form paste autosave",
             autosave_key_value: "comment-#{bubble.id}",
             action: "turbo:submit-end->autosave#submit" } do |form| %>
  <%= form.markdown_area :body, class: "input comment__input", required: true,
        data: { autosave_target: "input", action: "house-md:change->autosave#save" } %>
<% end %>
```

**关键点**：
- 使用 `localStorage` 存储草稿内容
- 使用 `debounce` 延迟保存（300ms），避免频繁写入
- 在表单提交成功后清除本地存储
- 在控制器连接时恢复保存的内容
- 使用自定义事件触发 Markdown 编辑器更新
- 体现了用户体验优化和本地存储的最佳实践

**从 Commit a0ffbc80 学到的经验**：

**时间**：2025-02-26  
**作者**：Jason Zimdars  
**变更文件**：
- `app/javascript/controllers/autosave_controller.js`（新建）
- `app/views/comments/_new.html.erb`

Fizzy 团队实现了自动保存评论到本地存储，防止丢失工作。这体现了：
- 用户体验优化的重要性
- 使用 localStorage 保存草稿
- 使用 debounce 优化性能
- 在提交成功后清除本地存储

### 4.4 自定义 Turbo Stream Action

**创建自定义 Turbo Stream action 实现自动更新：**

```ruby
# app/helpers/turbo_stream_helper.rb
module TurboStreamHelper
  def turbo_stream_reflect_color(card)
    turbo_stream_action :reflect_color, target: dom_id(card), color: card.color
  end
end

# app/views/cards/colors/update.turbo_stream.erb
<%= turbo_stream_reflect_color @card %>
```

**在 JavaScript 中处理自定义 action：**

```javascript
// app/javascript/application.js
import { StreamActions } from "@hotwired/turbo"

StreamActions.reflect_color = function() {
  const color = this.getAttribute("color")
  const target = this.targetElements[0]
  
  if (target) {
    target.style.setProperty("--card-color", color)
  }
}
```

**关键点**：
- 使用 `turbo_stream_action` helper 生成自定义 stream action
- 在 JavaScript 中注册自定义 action 处理器
- 使用 `StreamActions` 对象注册自定义 action
- 通过 `getAttribute` 获取传递的参数
- 通过 `targetElements` 获取目标元素
- 体现了 Turbo Stream 扩展和自定义 action 的最佳实践

**从 Commit e21bb991 学到的经验**：

**时间**：2025-04-10  
**作者**：Jorge Manrubia  
**变更文件**：
- 创建了自定义 Turbo Stream action
- 使用 Rails helper 生成自定义 stream action

Fizzy 团队使用自定义 Turbo Stream action 实现自动更新。这体现了：
- Turbo Stream 扩展的最佳实践
- 使用自定义 action 实现复杂更新逻辑
- 在 JavaScript 中注册自定义 action 处理器

### 4.5 实时广播通知阅读状态

**使用 Turbo Stream 广播通知阅读状态，实现实时同步：**

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  def mark_as_read!
    update! read_at: Time.current
    broadcast_mark_as_read
  end

  private
    def broadcast_mark_as_read
      broadcast_update_to [ recipient, :notifications ],
        target: dom_id(self),
        partial: "notifications/notification",
        locals: { notification: self }
    end
end
```

**关键点**：
- 使用 `broadcast_update_to` 广播通知阅读状态
- 当用户阅读通知时，实时更新其他用户的视图
- 使用 `dom_id` 确保目标元素正确
- 体现了实时同步和广播机制的最佳实践

**从 Commit 822ec5b5 学到的经验**：

**时间**：2025-05-08  
**作者**：Mike Dalessio  
**变更文件**：
- 实现了通知阅读状态的实时广播

Fizzy 团队使用 Turbo Stream 广播通知阅读状态，实现实时同步。这体现了：
- 实时同步的重要性
- 使用广播机制更新多个用户的视图
- 确保数据一致性

### 4.6 Turbo Stream Flash 消息

**使用 turbo_stream_flash helper 实现 flash 消息：**

```ruby
# app/helpers/turbo_stream_helper.rb
module TurboStreamHelper
  def turbo_stream_flash(notice: nil, alert: nil)
    turbo_stream.replace "flash", partial: "shared/flash", locals: { notice: notice, alert: alert }
  end
end

# app/controllers/collections_controller.rb
def update
  @collection.update! collection_params
  render turbo_stream: turbo_stream_flash(notice: "Collection updated")
end
```

**提取 flash 消息到 partial：**

```erb
<!-- app/views/shared/_flash.html.erb -->
<%= turbo_frame_tag "flash" do %>
  <% if notice %>
    <div class="flash flash--notice"><%= notice %></div>
  <% elsif alert %>
    <div class="flash flash--alert"><%= alert %></div>
  <% end %>
<% end %>
```

**关键点**：
- 使用 `turbo_stream_flash` helper 生成 flash 消息的 Turbo Stream
- 提取 flash 消息到 partial，便于复用
- 使用 `turbo_frame_tag` 包装 flash 消息，实现局部更新
- 使用 `turbo_stream.replace` 替换 flash 消息
- 体现了 Turbo Stream 和 flash 消息的最佳实践

**从 Commit 988b20a3 学到的经验**：

**时间**：2025-08-07  
**作者**：Mike Dalessio  
**变更文件**：
- 引入了 `turbo_stream_flash` helper
- 提取了 flash 消息到 partial
- 使用 turbo frame 包装 flash 消息

Fizzy 团队使用 turbo_stream_flash helper 实现 flash 消息。这体现了：
- Turbo Stream 和 flash 消息的最佳实践
- 使用 helper 方法简化代码
- 使用 partial 组织视图代码
- 使用 turbo frame 实现局部更新

### 4.7 局部更新优化

**使用 turbo stream 替换部分内容而不是替换整个资源，避免丢失编辑上下文：**

```ruby
# ❌ Old（替换整个卡片，会丢失编辑上下文）
def create
  @card.toggle_assignment @collection.users.active.find(params[:assignee_id])
  render_card_replacement  # 替换整个卡片
end

# ✅ New（只替换分配者部分）
def create
  @card.toggle_assignment @collection.users.active.find(params[:assignee_id])
  
  render turbo_stream: turbo_stream.replace([ @card, :assignees ], 
    partial: "cards/display/perma/assignees", 
    locals: { card: @card.reload })
end
```

**关键点**：
- 使用 `turbo_stream.replace` 只替换部分内容
- 使用 `dom_id(@card, :assignees)` 定位目标元素
- 避免替换整个资源，保持编辑上下文
- 体现了局部更新和用户体验优化的最佳实践

**从 Commit be246d20 学到的经验**：

**时间**：2025-09-09  
**作者**：Jorge Manrubia  
**变更文件**：
- `app/controllers/cards/assignments_controller.rb`
- `app/views/cards/edit.html.erb`

Fizzy 团队使用 turbo stream 替换分配者而不是替换整个卡片，避免丢失编辑上下文。这体现了：
- 局部更新的重要性
- 保持编辑上下文的最佳实践
- 用户体验优化

### 4.8 广播删除操作

**广播被删除的通知，防止 404 错误：**

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  after_create_commit :broadcast_unread
  after_destroy_commit :broadcast_read

  private
    def broadcast_read
      broadcast_remove_to user, :notifications
    end
end
```

**关键点**：
- 使用 `after_destroy_commit :broadcast_read` 在删除通知后广播
- 使用 `broadcast_remove_to` 从视图中移除通知
- 防止用户在没有刷新页面的情况下看到 404 错误
- 体现了实时同步和用户体验优化的最佳实践

**从 Commit 58c525e5 学到的经验**：

**时间**：2025-09-10  
**作者**：Jorge Manrubia  
**变更文件**：`app/models/notification.rb`

Fizzy 团队广播被删除的通知，防止 404 错误。这体现了：
- 实时同步的重要性
- 防止 404 错误的最佳实践
- 用户体验优化

### 4.9 Turbo Frame 延迟加载优化

**使用 lazy loading 的 turbo frame 减少请求，提升性能：**

```erb
<!-- ❌ Old（立即加载） -->
<%= turbo_frame_tag card, :assignment, src: new_card_assignment_path(card), refresh: "morph" %>

<!-- ✅ New（延迟加载） -->
<%= turbo_frame_tag card, :assignment, src: new_card_assignment_path(card), loading: :lazy, refresh: "morph" %>
```

**在 dialog 打开时加载 lazy frames：**

```javascript
// app/javascript/controllers/dialog_controller.js
export default class extends Controller {
  show(event) {
    // ... 其他代码 ...
    
    this.#loadLazyFrames()
    this.dialogTarget.setAttribute("aria-hidden", "false")
    this.dispatch("show")
  }

  #loadLazyFrames() {
    Array.from(this.dialogTarget.querySelectorAll("turbo-frame")).forEach(frame => { 
      frame.loading = "eager" 
    })
  }
}
```

**关键点**：
- 在 turbo frame 上使用 `loading: :lazy` 延迟加载
- 在 dialog 打开时使用 `#loadLazyFrames()` 方法将 lazy frames 设置为 eager
- 权衡：在重新分配时可能有微小的延迟，但值得
- 体现了性能优化和用户体验权衡的最佳实践

**从 Commit 07ec3f49 学到的经验**：

**时间**：2025-11-07  
**作者**：David Heinemeier Hansson  
**变更文件**：
- `app/javascript/controllers/dialog_controller.js`
- `app/views/cards/display/perma/_assignees.html.erb`
- `app/views/cards/display/perma/_board.html.erb`
- `app/views/cards/display/perma/_tags.html.erb`

Fizzy 团队使用 lazy loading 的 turbo frame 减少请求，提升性能。这体现了：
- 性能优化的重要性
- 使用 lazy loading 减少初始请求
- 在需要时动态加载内容
- 用户体验权衡的最佳实践

### 4.10 广播优化：条件广播和异步广播

**只在预览改变时广播，使用异步广播提升性能：**

```ruby
# app/models/card/broadcastable.rb
module Card::Broadcastable
  extend ActiveSupport::Concern

  included do
    broadcasts_refreshes

    before_update :remember_if_preview_changed
  end

  private
    def remember_if_preview_changed
      @preview_changed ||= title_changed? || column_id_changed? || board_id_changed?
    end

    def preview_changed?
      @preview_changed
    end
end

# app/models/card/pinnable.rb
module Card::Pinnable
  extend ActiveSupport::Concern

  included do
    has_many :pins, dependent: :destroy

    after_update_commit :broadcast_pin_updates, if: :preview_changed?
  end

  private
    def broadcast_pin_updates
      pins.find_each do |pin|
        pin.broadcast_replace_later_to [ pin.user, :pins_tray ], partial: "my/pins/pin"
      end
    end
end
```

**关键点**：
- 使用 `before_update :remember_if_preview_changed` 记住预览是否改变
- 使用 `after_update_commit :broadcast_pin_updates, if: :preview_changed?` 条件广播
- 使用 `broadcast_replace_later_to` 异步广播
- 使用 `find_each` 批量处理 pins
- 体现了广播优化和性能优化的最佳实践

**从 Commit c89db89f 学到的经验**：

**时间**：2025-12-05  
**作者**：Jorge Manrubia  
**变更文件**：
- `app/models/card/broadcastable.rb`
- `app/models/card/pinnable.rb`

Fizzy 团队只在预览改变时广播，使用异步广播提升性能。这体现了：
- 条件广播的重要性
- 异步广播的性能优势
- 批量处理的最佳实践

## 5. 应用到 BuildX

### 5.1 建议采用的实践

1. **Turbo Streams**：实现实时更新
2. **Turbo Frames**：实现局部更新
3. **广播机制**：使用 `broadcast_*_to` 广播更新
4. **订阅广播**：使用 `turbo_stream_from` 订阅更新
5. **Stimulus**：处理交互逻辑
6. **Partials**：组织视图代码
7. **缓存**：使用片段缓存提高性能

### 5.2 实现步骤

1. **设置 Turbo Streams**
   - 配置 Action Cable
   - 实现广播机制
   - 创建 Turbo Stream 视图

2. **实现 Turbo Frames**
   - 识别可以局部更新的区域
   - 创建 Turbo Frame
   - 实现局部更新逻辑

3. **创建 Stimulus 控制器**
   - 识别交互需求
   - 创建对应的控制器
   - 实现交互逻辑

4. **优化视图**
   - 使用 Partials 组织代码
   - 使用缓存提高性能
   - 使用 Content For 组织页面内容

## 参考资料

- [Hotwire 文档](https://hotwired.dev/)
- [Turbo 文档](https://turbo.hotwired.dev/)
- [Stimulus 文档](https://stimulus.hotwired.dev/)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

### 3.5 使用 HTML5 datalist 实现简单自动完成

**使用 HTML5 的 `datalist` 元素实现简单的自动完成功能：**

```erb
<%= form.text_field :title, class: "input borderless", autofocus: "on", list: "categories-list" %>

<datalist id="categories-list">
  <% Category.all.each do | category | %>
    <option value="<%= category.title %>"></option>
  <% end %>
</datalist>
```

**控制器中使用 `find_or_create_by` 避免重复创建：**

```ruby
def create
  @category = Category.find_or_create_by(category_params)
  @category.save
  # ...
end
```

**关键点**：
- 使用原生 HTML5 功能，不需要 JavaScript 库
- 使用 `list` 属性关联 datalist
- 使用 `find_or_create_by` 避免重复创建
- 体现了"使用简单方案"的思路

**从 Commit 056a3c306 学到的经验**：

**时间**：2024-08-05  
**作者**：Jason Zimdars  
**变更文件**：
- `app/controllers/categories_controller.rb`
- `app/views/categories/new.html.erb`

Fizzy 团队使用 HTML5 的 `datalist` 元素实现简单的自动完成功能，而不是使用复杂的 JavaScript 库。这体现了：
- 优先使用原生 HTML 功能
- 使用 `find_or_create_by` 避免重复创建
- 简单有效的解决方案

### 3.6 简化用户流程

**从复杂的 dialog 改为简单的页面跳转：**

```erb
<!-- ❌ Old（使用 dialog） -->
<div data-controller="dialog">
  <button popovertarget="new-splat-panel">Create</button>
  <dialog id="new-splat-panel" popover>
    <turbo_frame_tag :new_splat, src: new_splat_path />
  </dialog>
</div>

<!-- ✅ New（直接链接） -->
<%= link_to new_splat_path, class: "btn" do %>
  Create
<% end %>
```

**关键点**：
- 简化用户流程，减少交互步骤
- 使用简单的页面跳转，而不是复杂的 dialog
- 在目标页面中直接显示完整的 UI

**从 Commit fdc0937bc 学到的经验**：

**时间**：2024-08-07  
**作者**：Jason Zimdars  
**变更文件**：
- `app/views/splats/index.html.erb`
- `app/views/splats/new.html.erb`

Fizzy 团队简化了创建 splat 的流程，从 dialog 改为直接链接。这体现了：
- 简化用户流程的重要性
- 有时候简单的方案更好
- 减少不必要的复杂性

### 3.7 使用 Turbo Frame 实现点击编辑

**使用 Turbo Frame 实现点击编辑功能：**

```erb
<!-- app/views/bubbles/_bubble.html.erb -->
<h1 class="bubble__title">
  <%= turbo_frame_tag bubble, :edit do %>
    <%= link_to bubble.title, edit_bubble_path(bubble), class: "txt-undecorated" %>
  <% end %>
</h1>

<!-- app/views/bubbles/edit.html.erb -->
<%= turbo_frame_tag @bubble, :edit do %>
  <%= form_with model: @bubble, class: "flex flex-column gap full-width", data: { controller: "form" } do | form | %>
    <%= form.text_area :title, class: "input input--textara unpad full-width borderless",
        required: true, rows: 5, autofocus: true, placeholder: "Name it…",
        data: { action: "keydown.ctrl+enter->form#submit:prevent keydown.meta+enter->form#submit:prevent keydown.esc->form#cancel" } %>
    <%= form.submit "Save", hidden: true %>
    <%= link_to "Close editor and discard changes", bubble_path(@bubble), data: { form_target: "cancel" }, hidden: true %>
  <% end %>
<% end %>
```

**关键点**：
- 使用 `turbo_frame_tag bubble, :edit` 包裹编辑区域
- 点击链接时，Turbo Frame 会加载编辑页面
- 提交表单后，Turbo Frame 会自动更新显示区域
- 支持键盘快捷键（Ctrl+Enter 提交，Esc 取消）

**从 Commit 24643341 学到的经验**：

**时间**：2024-09-06  
**作者**：Jason Zimdars  
**变更文件**：
- `app/views/bubbles/_bubble.html.erb`
- `app/views/bubbles/edit.html.erb`

Fizzy 团队使用 Turbo Frame 实现点击编辑标题功能。这体现了：
- 使用 Turbo Frame 实现局部更新
- 不需要 JavaScript，纯 HTML 和 Turbo
- 支持键盘快捷键，提升用户体验

## 4. 视图组织

