# 表单 `local: true` 参数使用指南

## 概述

在 Rails 的 `form_with` 中，`local: true` 参数控制表单的提交方式：

- **默认行为**（不设置 `local`）：表单通过 AJAX（Turbo/Unobtrusive JavaScript）提交，不会刷新页面
- **`local: true`**：使用传统 HTML 表单提交，会刷新页面

## 项目中的使用情况

### 当前使用 `local: true` 的表单

1. **管理后台 CRUD 表单**
   - `app/views/admin/roles/new.html.erb`
   - `app/views/admin/roles/edit.html.erb`
   - `app/views/admin/system_configs/edit.html.erb`
   - `app/views/admin/users/edit.html.erb`

2. **个人设置表单**
   - `app/views/my/profile/edit.html.erb`（同时使用了 `data: { controller: "form", turbo: true }`）
   - `app/views/my/security/show.html.erb`（同时使用了 `data: { controller: "form", turbo: true }`）

3. **搜索/筛选表单**
   - `app/views/admin/users/index.html.erb`
   - `app/views/admin/roles/index.html.erb`
   - `app/views/admin/audit_logs/index.html.erb`

### 当前不使用 `local: true` 的表单

1. **认证相关表单**
   - `app/views/sessions/new.html.erb`（登录表单）
   - `app/views/users/new.html.erb`（注册表单）
   - `app/views/passwords/new.html.erb`（忘记密码表单）
   - `app/views/passwords/edit.html.erb`（重置密码表单）

2. **安装向导表单**
   - `app/views/installation/show.html.erb`（使用了 `data: { controller: "form", action: "submit->form#submit" }`）

## 何时使用 `local: true`

### ✅ 应该使用 `local: true` 的场景

1. **控制器使用 `redirect_to` 重定向**
   - 成功提交后需要重定向到其他页面
   - 需要显示 flash 消息（notice/alert）
   - 需要更新页面状态

2. **搜索/筛选表单（GET 请求）**
   - 需要刷新页面显示搜索结果
   - 需要更新 URL 参数

3. **需要完整页面刷新的场景**
   - 更新后需要重新加载页面数据
   - 需要更新导航栏或其他全局状态

### ❌ 不应该使用 `local: true` 的场景

1. **使用 Turbo 进行部分更新**
   - 表单使用 `data: { controller: "form", turbo: true }`
   - 需要无刷新更新页面内容

2. **单页应用（SPA）场景**
   - 使用 JavaScript 处理表单提交
   - 需要动态更新页面内容

## 项目中的最佳实践

### 推荐做法

**对于所有使用 `redirect_to` 的控制器，建议使用 `local: true`**：

```erb
<%= daisy_form_with model: @user, local: true, class: "space-y-5" do |form| %>
  <!-- 表单内容 -->
<% end %>
```

### 原因分析

查看项目中的控制器代码，所有表单提交后都会使用 `redirect_to` 进行重定向：

```ruby
# app/controllers/admin/roles_controller.rb
def update
  if @role.update(role_params)
    redirect_to admin_role_path(@role), notice: "角色更新成功！"
  else
    render :edit, status: :unprocessable_entity
  end
end
```

使用 `local: true` 的好处：
1. **简单直接**：不需要处理 Turbo 的重定向逻辑
2. **Flash 消息正常显示**：页面刷新后 flash 消息可以正常显示
3. **状态更新**：页面刷新后所有状态都会更新

### 特殊情况

**安装向导表单**使用了 Turbo，但控制器仍然使用 `redirect_to`：

```erb
<%= form_with model: @installation, url: installation_path, 
    class: "space-y-5", 
    data: { controller: "form", action: "submit->form#submit" } do |form| %>
```

这种情况下，Turbo 会自动处理 `redirect_to`，所以不需要 `local: true`。

## 统一规范建议

### 方案 1：统一使用 `local: true`（推荐）

**适用于**：所有使用 `redirect_to` 的表单

```erb
<!-- 管理后台表单 -->
<%= daisy_form_with model: [ :admin, @role ], local: true, class: "space-y-5" do |form| %>
  <!-- 表单内容 -->
<% end %>

<!-- 认证表单 -->
<%= form_with url: session_url, local: true, class: "space-y-5" do |form| %>
  <!-- 表单内容 -->
<% end %>
```

**优点**：
- 简单直接，不需要处理 Turbo 逻辑
- Flash 消息正常显示
- 所有状态都会更新

**缺点**：
- 页面会刷新，用户体验稍差

### 方案 2：根据场景选择

**使用 `local: true`**：
- 管理后台 CRUD 表单
- 个人设置表单
- 搜索/筛选表单

**不使用 `local: true`**（使用默认 AJAX）：
- 安装向导表单（使用 Turbo）
- 需要无刷新更新的表单

## 当前项目建议

基于项目中的控制器实现，**建议统一使用 `local: true`**，因为：

1. **所有控制器都使用 `redirect_to`**：成功时重定向，失败时 `render`
2. **需要显示 flash 消息**：页面刷新后 flash 消息可以正常显示
3. **简单可靠**：不需要处理 Turbo 的重定向逻辑

### 需要更新的表单

以下表单建议添加 `local: true`：

1. `app/views/sessions/new.html.erb`
2. `app/views/users/new.html.erb`
3. `app/views/passwords/new.html.erb`
4. `app/views/passwords/edit.html.erb`

## 示例代码

### 使用 `local: true` 的标准表单

```erb
<%= daisy_form_with model: [ :admin, @role ], local: true, class: "space-y-5" do |form| %>
  <%= form.error_messages %>
  <%= form.text_field :name, label_text: "名称" %>
  <%= form.text_area :description, label_text: "描述" %>
  <%= form.card_actions submit_text: "保存", cancel_text: "取消", cancel_url: admin_roles_path %>
<% end %>
```

### 使用 Turbo 的表单（不需要 `local: true`）

```erb
<%= form_with model: @installation, url: installation_path, 
    class: "space-y-5", 
    data: { controller: "form", action: "submit->form#submit" } do |form| %>
  <!-- 表单内容 -->
<% end %>
```

## 相关文件

- FormBuilder 实现: `app/helpers/daisy_form_builder.rb`
- Helper 方法: `app/helpers/application_helper.rb`
- 控制器示例: `app/controllers/admin/roles_controller.rb`

