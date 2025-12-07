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

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

