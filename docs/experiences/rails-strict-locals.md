---
date: 2025-12-26
problem_type: 学习笔记、最佳实践、Rails 规范
status: 已完成
tags: Rails、Partial、Strict Locals、最佳实践、Rails 8
description: 学习 Rails 8 中引入的 strict locals 规范，用于在 partial 文件中声明 locals 参数
---

# Rails Strict Locals 规范

## 概述

Rails 8 引入了 **Strict Locals** 功能，允许在 partial 文件中声明 locals 参数，类似于函数签名。这提供了更好的类型安全、文档化和错误检查。

**参考文档**：[Action View Overview - Strict Locals](https://guides.rubyonrails.org/action_view_overview.html#strict-locals)

## 核心概念

### 1. 基本语法

在 partial 文件顶部使用注释声明 locals：

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message:) -%>
<%= message %>
```

**说明**：
- 使用 `<%# locals: (param1:, param2:) %>` 语法
- `-` 符号用于去除注释后的换行符
- 参数名后必须有 `:`，表示这是关键字参数

### 2. 必需参数

如果声明了参数但没有传递，会抛出异常：

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message:) -%>
<%= message %>
```

```ruby
# 缺少 message 参数会抛出异常
render "messages/message"
# => ActionView::Template::Error: missing local: :message for app/views/messages/_message.html.erb

# 正确使用
render "messages/message", message: "Hello, world!"
```

### 3. 默认值

可以为参数设置默认值：

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!") -%>
<%= message %>
```

```ruby
# 不传递 message 时使用默认值
render "messages/message"
# => "Hello, world!"

# 传递 message 时使用传递的值
render "messages/message", message: "Custom message"
# => "Custom message"
```

### 4. 可选参数（使用双 splat）

使用 `**attributes` 允许额外的参数：

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (message: "Hello, world!", **attributes) -%>
<%= tag.p(message, **attributes) %>
```

```ruby
# 可以传递额外的 HTML 属性
render "messages/message", 
       message: "Hello", 
       class: "text-lg", 
       data: { controller: "message" }
```

### 5. 禁止所有 Locals

使用空的 `locals: ()` 来禁止所有 locals：

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: () -%>
<div>Static content</div>
```

```ruby
# 传递任何 local 都会抛出异常
render "messages/message", unknown_local: "will raise"
# => ActionView::Template::Error: no locals accepted for app/views/messages/_message.html.erb
```

### 6. 处理保留关键字

如果参数名与 Ruby 保留关键字相同（如 `class`、`if`），有两种处理方式：

**方式 1：使用 `binding.local_variable_get`（不推荐）**

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (class: "message") -%>
<div class="<%= binding.local_variable_get(:class) %>">...</div>
```

**方式 2：使用替代参数名（推荐）**

```erb
<%# app/views/messages/_message.html.erb %>

<%# locals: (html_class: "message") -%>
<div class="<%= html_class %>">...</div>
```

**推荐使用替代参数名**，因为：
- 代码更清晰易读
- 不需要使用 `binding.local_variable_get`
- 避免与 HTML 的 `class` 属性混淆

**常见的保留关键字替代方案**：
- `class` → `html_class` 或 `css_class`
- `if` → `condition` 或 `show_if`
- `for` → `loop_for` 或 `iterate`

## 完整示例

### 示例 1：基本用法

```erb
<%# app/views/users/_user_card.html.erb %>

<%# locals: (user:, show_email: false) -%>
<div class="user-card">
  <h3><%= user.name %></h3>
  <% if show_email %>
    <p><%= user.email %></p>
  <% end %>
</div>
```

```ruby
# 使用
render "users/user_card", user: @user, show_email: true
```

### 示例 2：带默认值和额外属性

```erb
<%# app/views/shared/_button.html.erb %>

<%# locals: (text: "Click me", variant: "primary", **html_attributes) -%>
<%= button_tag text, 
    class: "btn btn-#{variant}", 
    **html_attributes %>
```

```ruby
# 使用
render "shared/button", 
       text: "Submit", 
       variant: "primary",
       data: { controller: "form" },
       disabled: true
```

### 示例 3：复杂参数

```erb
<%# app/views/articles/_article.html.erb %>

<%# locals: (article:, show_comments: true, comment_count: article.comments.count) -%>
<article>
  <h2><%= article.title %></h2>
  <p><%= article.body %></p>
  
  <% if show_comments %>
    <div class="comments">
      <p><%= comment_count %> comments</p>
    </div>
  <% end %>
</article>
```

## 应用到 BuildX

### 更新现有 Partial

**更新前（`_dialog.html.erb`）：**

```erb
<%#
  参数：
  - id: 对话框的唯一 ID（必需）
  - frame_id: Turbo Frame 的 ID（必需）
  - url: 菜单内容的 URL（可选）
  - title: 对话框标题（可选）
  - size: 对话框大小（可选）
  - class: 额外的 CSS 类（可选）
%>
<%
  id ||= "dialog-#{SecureRandom.hex(4)}"
  frame_id ||= :dialog_frame
  size ||= "md"
  # ...
%>
```

**更新后（使用 strict locals）：**

```erb
<%# locals: (
      id: nil,
      frame_id: :dialog_frame,
      url: nil,
      title: nil,
      size: "md",
      html_class: nil  # 注意：使用 html_class 而不是 class（保留关键字）
    ) -%>
<%
  id ||= "dialog-#{SecureRandom.hex(4)}"
  size_class = {
    "sm" => "max-w-sm",
    "md" => "max-w-md",
    "lg" => "max-w-lg",
    "xl" => "max-w-xl",
    "full" => "max-w-full"
  }[size] || "max-w-md"
%>
```

### 最佳实践

1. **总是声明 locals**：即使是可选的参数，也应该在 `locals:` 中声明
2. **使用默认值**：为可选参数设置合理的默认值
3. **文档化参数**：在注释中说明每个参数的用途
4. **类型提示**：虽然 Ruby 是动态类型，但可以在注释中说明期望的类型

### 示例模板

```erb
<%#
  组件名称：用户卡片
  用途：显示用户基本信息
  
  locals:
    - user (User): 用户对象（必需）
    - show_email (Boolean): 是否显示邮箱（默认：false）
    - avatar_size (String): 头像大小，可选值：sm, md, lg（默认：md）
    - **html_attributes (Hash): 额外的 HTML 属性
%>

<%# locals: (user:, show_email: false, avatar_size: "md", **html_attributes) -%>
<div class="user-card" <%= tag.attributes(**html_attributes) %>>
  <!-- 内容 -->
</div>
```

## 注意事项

### 1. 只支持关键字参数

**不支持位置参数或块参数：**

```erb
<%# ❌ 错误：不支持位置参数 %>
<%# locals: (message) -%>

<%# ❌ 错误：不支持块参数 %>
<%# locals: (&block) -%>
```

### 2. local_assigns 不包含默认值

`local_assigns` 方法不包含在 `locals:` 签名中设置的默认值：

```erb
<%# locals: (message: "Hello") -%>
<%= local_assigns[:message] %>  <%# 如果未传递，这里会是 nil %>
<%= message %>  <%# 如果未传递，这里会是 "Hello" %>
```

### 3. 注释位置

`locals:` 签名可以放在 partial 文件的任何位置，只要是在支持 `#` 前缀注释的模板引擎中：

```erb
<%# 可以在文件开头 %>
<%# locals: (message:) -%>

<%# 也可以在中间 %>
<div>
  <%# locals: (message:) -%>
  <%= message %>
</div>
```

### 4. 模板引擎支持

Strict locals 支持所有支持 `#` 前缀注释的模板引擎：
- ERB (`.erb`)
- Haml (`.haml`)
- Slim (`.slim`)

## 优势

1. **类型安全**：在渲染时检查参数，避免运行时错误
2. **文档化**：参数声明本身就是文档
3. **IDE 支持**：更好的代码补全和错误检查
4. **重构友好**：重命名参数时更容易发现所有使用位置
5. **团队协作**：清晰的接口定义，减少沟通成本

## 迁移指南

### 步骤 1：识别现有 Partial

查找所有使用 locals 的 partial 文件：

```bash
# 查找所有 partial 文件
find app/views -name "_*.erb" -o -name "_*.haml" -o -name "_*.slim"

# 查找使用 local_assigns 的文件
grep -r "local_assigns" app/views
```

### 步骤 2：分析参数使用

检查每个 partial 文件：
- 哪些参数是必需的？
- 哪些参数有默认值？
- 哪些参数是可选的？

### 步骤 3：添加 locals 声明

逐步为每个 partial 添加 `locals:` 声明：

```erb
<%# 之前 %>
<%
  title ||= "Default Title"
  size ||= "md"
%>

<%# 之后 %>
<%# locals: (title: "Default Title", size: "md") -%>
```

### 步骤 4：测试

确保所有使用该 partial 的地方都能正常工作。

## 参考资料

- [Rails Guides - Action View Overview - Strict Locals](https://guides.rubyonrails.org/action_view_overview.html#strict-locals)
- [Rails 8 Release Notes](https://edgeguides.rubyonrails.org/8_0_release_notes.html)

## 更新记录

- **创建日期**：2025-12-26
- **最后更新**：2025-12-26

