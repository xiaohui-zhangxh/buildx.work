---
date: 2025-11-26
problem_type: 使用指南、前端开发、表单构建器
status: 已解决
---

# DaisyFormBuilder 使用指南

## 概述

`DaisyFormBuilder` 是一个自定义的 Rails FormBuilder，用于统一项目中所有表单的样式和结构。它基于 DaisyUI 5 组件库，提供了一致的表单字段样式、错误提示和按钮布局。

## 快速开始

### 基本用法

使用 `daisy_form_with` helper 方法创建表单：

```erb
<%= daisy_form_with model: @user, local: true, class: "space-y-5" do |form| %>
  <%= form.error_messages %>
  <%= form.text_field :name %>
  <%= form.email_field :email_address %>
  <%= form.submit %>
<% end %>
```

### `local: true` 参数

**重要**：对于使用 `redirect_to` 重定向的控制器，建议使用 `local: true`：

- `local: true`：使用传统 HTML 表单提交，页面会刷新（推荐用于需要重定向的表单）
- 默认（不设置）：使用 AJAX 提交，不会刷新页面（适用于需要无刷新更新的表单）

详细说明请参考：[表单 `local: true` 参数使用指南](./form-local-parameter.md)

### 与标准 form_with 的区别

**重要**：DaisyFormBuilder **保留 Rails 原有的渲染逻辑**，不会自动添加 label 和 wrapper。只有当明确指定 `label_text` 时，才会自动添加 label。

**标准用法**（保留原有逻辑）：
```erb
<%= daisy_form_with model: @user do |form| %>
  <div class="form-control">
    <%= form.label :name, class: "label" do %>
      <span class="label-text font-medium">姓名</span>
    <% end %>
    <%= form.text_field :name %>
    <!-- 自动应用默认样式类，无需手动添加 class -->
  </div>
<% end %>
```

**使用 label_text 选项**（自动添加 label）：

`label_text` 支持三种用法：

1. **不指定**（默认）：保留 Rails 原有行为，不添加 label
```erb
<%= daisy_form_with model: @user do |form| %>
  <%= form.text_field :username %>
  <!-- 不输出 label，只应用默认样式类 -->
<% end %>
```

2. **指定字符串**：使用指定的文字作为 label
```erb
<%= daisy_form_with model: @user do |form| %>
  <%= form.text_field :username, label_text: "用户名" %>
  <!-- 输出 label，文字为 "用户名" -->
<% end %>
```

3. **指定 true**：使用 human attribute name 作为 label
```erb
<%= daisy_form_with model: @user do |form| %>
  <%= form.text_field :username, label_text: true %>
  <!-- 输出 label，使用 User.human_attribute_name(:username) -->
<% end %>
```

## 主要功能

### 1. 统一的错误提示

`error_messages` 方法会自动渲染 DaisyUI 风格的错误提示：

```erb
<%= form.error_messages %>
<!-- 或自定义标题 -->
<%= form.error_messages title: "请修复以下错误：" %>
```

### 2. 表单字段

所有表单字段方法都支持统一的样式和结构：

#### 文本字段

```erb
<%= form.text_field :name %>
<%= form.text_field :name, label_text: "姓名", placeholder: "请输入姓名" %>
<!-- 隐藏标签 -->
<%= form.text_field :name, label_text: false, placeholder: "请输入姓名" %>
```

#### 邮箱字段

```erb
<%= form.email_field :email_address %>
<%= form.email_field :email_address, placeholder: "example@email.com" %>
```

#### 密码字段

```erb
<%= form.password_field :password %>
<%= form.password_field :password, placeholder: "至少 8 位字符" %>
```

#### 文本区域

```erb
<%= form.text_area :description %>
<%= form.text_area :description, rows: 5, placeholder: "请输入描述" %>
```

#### 下拉选择

```erb
<%= form.select :role, [["管理员", "admin"], ["用户", "user"]] %>
<%= form.select :role, options_for_select([["管理员", "admin"], ["用户", "user"]]) %>
```

#### 复选框

```erb
<%= form.check_box :remember_me, label_text: "记住我" %>
```

#### 单选按钮组

```erb
<%= form.collection_radio_buttons :role, Role.all, :id, :name %>
```

### 3. 按钮和操作

#### 提交按钮

```erb
<%= form.submit "保存" %>
<%= form.submit "保存", size: "lg", full_width: true %>
```

#### 表单操作（按钮组）

使用 `actions` 方法创建提交和取消按钮：

```erb
<%= form.actions submit_text: "保存", cancel_text: "取消", cancel_url: users_path %>
```

#### 卡片操作（右对齐按钮）

使用 `card_actions` 方法创建右对齐的按钮组：

```erb
<%= form.card_actions submit_text: "更新", cancel_text: "取消", cancel_url: admin_system_configs_path %>
```

## 完整示例

### 示例 1：简单表单（推荐使用最大宽度限制）

对于字段较少的简单表单，建议使用 `max-w-2xl mx-auto` 来限制宽度并居中显示：

```erb
<div class="max-w-2xl mx-auto">
  <div class="card bg-base-100 shadow">
    <div class="card-body">
      <%= daisy_form_with model: @user, local: true, class: "space-y-5" do |form| %>
        <%= form.error_messages %>

        <%= form.text_field :name, label_text: "姓名", placeholder: "请输入姓名" %>
        <%= form.email_field :email_address, label_text: "邮箱地址", placeholder: "example@email.com" %>
        <%= form.text_area :bio, label_text: "个人简介", rows: 4, placeholder: "请输入个人简介" %>

        <%= form.card_actions submit_text: "保存更改", cancel_text: "取消", cancel_url: user_path(@user) %>
      <% end %>
    </div>
  </div>
</div>
```

**注意**：简单表单（字段少于 5 个）建议使用 `max-w-2xl`，复杂表单可以使用全宽或 `max-w-4xl`。

### 示例 2：登录表单

```erb
<div class="card bg-base-100 shadow-2xl border border-base-300">
  <div class="card-body p-8">
    <%= daisy_form_with url: session_url, class: "space-y-5" do |form| %>
      <%= form.email_field :email_address, label_text: "邮箱地址", placeholder: "Enter your email address" %>
      <%= form.password_field :password, label_text: "密码", placeholder: "Enter your password" %>
      <%= form.check_box :remember_me, label_text: "记住我" %>

      <div class="form-control mt-6">
        <%= form.submit "登录", full_width: true, size: "lg" %>
      </div>
    <% end %>
  </div>
</div>
```

### 示例 3：带自定义样式的字段

如果需要覆盖默认样式，可以使用 `no_default_classes` 选项：

```erb
<%= form.text_field :name, no_default_classes: true, class: "input input-ghost" %>
```

### 示例 4：隐藏标签的字段

某些情况下可能不需要显示标签（比如标签已经在其他地方显示）：

```erb
<%= form.text_field :search, label_text: false, placeholder: "搜索..." %>
<%= form.text_field :hidden_field, label_text: false, class: "input input-ghost" %>
```

## 自定义选项

### 字段选项

- `label_text`: 自定义标签文本（可选）
  - **不指定**（默认）：保留 Rails 原有渲染逻辑，不自动添加 label 和 wrapper，只应用默认样式类
  - **字符串**：自动添加 label 和 wrapper，使用指定的文本作为标签
  - **`true`**：自动添加 label 和 wrapper，使用 `human_attribute_name` 作为标签文本
  - **`false`**：自动添加 wrapper，但不显示 label
- `placeholder`: 占位符文本
- `rows`: 文本区域的行数（默认 3）
- `no_default_classes`: 禁用默认样式类
- 其他标准 Rails 表单字段选项

**重要**：
- 如果不指定 `label_text`，FormBuilder 会保留 Rails 原有的渲染逻辑，只自动应用默认样式类。这样就能兼容现有的表单结构。
- 使用 `label_text: true` 时，会调用模型的 `human_attribute_name` 方法获取属性的人类可读名称。

### 错误提示选项

- `title`: 自定义错误提示标题（默认："请修复以下错误："）
- `class`: 自定义 CSS 类（默认包含 `alert alert-error mb-4 shadow-lg`）

### 按钮选项

- `submit_text`: 提交按钮文本（默认："保存"）
- `cancel_text`: 取消按钮文本（默认："取消"）
- `cancel_url`: 取消按钮链接
- `size`: 按钮尺寸（`xs`, `sm`, `md`, `lg`, `xl`）
- `full_width`: 是否全宽（布尔值）

## 默认样式类

FormBuilder 会自动应用以下默认样式：

- **输入框**: `input input-bordered w-full focus:input-primary`
- **文本区域**: `textarea textarea-bordered w-full`
- **下拉选择**: `select select-bordered w-full`
- **复选框**: `checkbox checkbox-primary`
- **单选按钮**: `radio radio-primary`

## 优势

1. **一致性**: 所有表单使用统一的样式和结构
2. **简洁性**: 减少重复的 HTML 和 CSS 类
3. **可维护性**: 样式修改只需在一个地方进行
4. **错误处理**: 自动显示字段级别的错误信息
5. **可访问性**: 自动生成正确的 label 和错误提示结构

## 迁移指南

### 从标准表单迁移

**之前**：
```erb
<%= form_with model: @user do |form| %>
  <% if @user.errors.any? %>
    <div class="alert alert-error">
      <ul>
        <% @user.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-control">
    <%= form.label :name, class: "label" do %>
      <span class="label-text font-medium">姓名</span>
    <% end %>
    <%= form.text_field :name, class: "input input-bordered w-full focus:input-primary" %>
  </div>

  <div class="form-control mt-6">
    <%= form.submit "保存", class: "btn btn-primary" %>
    <%= link_to "取消", users_path, class: "btn btn-ghost ml-2" %>
  </div>
<% end %>
```

**之后**：
```erb
<%= daisy_form_with model: @user, local: true, class: "space-y-5" do |form| %>
  <%= form.error_messages %>
  <%= form.text_field :name, label_text: "姓名" %>
  <%= form.card_actions submit_text: "保存", cancel_text: "取消", cancel_url: users_path %>
<% end %>
```

## 注意事项

1. 使用 `daisy_form_with` 而不是 `form_with` 来启用 FormBuilder
2. 表单容器建议使用 `class: "space-y-5"` 来统一字段间距
3. **FormBuilder 保留 Rails 原有渲染逻辑**：默认情况下不会自动添加 label 和 wrapper，只自动应用默认样式类
4. **使用 `label_text` 选项**：只有当明确指定 `label_text` 时，才会自动添加 label 和 wrapper
5. 错误提示会自动显示在字段下方（如果字段有错误且使用了 `label_text`）
6. 所有字段方法都支持标准的 Rails 表单选项
7. **对于使用 `redirect_to` 重定向的控制器，建议使用 `local: true`**（详见 [表单 `local: true` 参数使用指南](./form-local-parameter.md)）
8. **简单表单建议使用最大宽度限制**：对于字段较少的表单（少于 5 个字段），建议使用 `max-w-2xl mx-auto` 来限制宽度并居中显示，避免表单占据整个屏幕宽度

## 相关文件

- FormBuilder 实现: `app/helpers/daisy_form_builder.rb`
- Helper 方法: `app/helpers/application_helper.rb`
- DaisyUI 规则: `.cursor/rules/daisy-ui.mdc`
- 表单 `local: true` 参数使用指南: `docs/experiences/form-local-parameter.md`

