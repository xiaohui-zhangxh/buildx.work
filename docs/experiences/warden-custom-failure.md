# Warden custom_failure! 使用经验

**日期**：2025-11-29  
**问题类型**：后端逻辑 / 认证系统  
**状态**：✅ 已解决

## 问题描述

在开发 API 控制器时，遇到以下问题：

1. **控制器返回 401 状态码时被 Warden 拦截**：当 API 控制器返回 401 状态码时，Warden 中间件会拦截响应并重定向到登录页面（`/session/new`），而不是返回 JSON 格式的响应。

2. **测试失败**：测试期望返回 401 状态码和 JSON 响应，但实际返回 302 重定向。

3. **API 控制器需要自定义错误处理**：API 控制器继承自 `ActionController::API`，不需要用户身份验证，但需要返回 JSON 格式的 401 响应。

## 问题原因分析

### Warden 中间件的工作机制

1. **Warden 是全局中间件**：Warden 作为 Rails 中间件，会拦截所有请求，尝试恢复用户会话。

2. **failure_app 处理认证失败**：当 Warden 检测到认证失败时，会调用 `failure_app`（在 `config/initializers/warden.rb` 中配置），默认行为是重定向到登录页面。

3. **401 状态码触发 Warden 拦截**：即使控制器没有调用认证方法，返回 401 状态码也会被 Warden 中间件拦截，因为 Warden 认为这是认证失败。

4. **ActionController::API 的特殊性**：`ActionController::API` 默认不支持 session，但 Warden 中间件仍然会尝试处理请求。

### 为什么需要 custom_failure!

`custom_failure!` 是 Warden 提供的方法，用于告诉 Warden 不要处理认证失败，让控制器自己处理响应。调用 `custom_failure!` 后：

- Warden 不会调用 `failure_app`
- 控制器可以返回自定义的响应（如 JSON 格式的 401 响应）
- 不会触发重定向到登录页面

## 解决方案

### 在控制器中添加 before_action

在 API 控制器中添加 `before_action`，调用 `custom_failure!`：

```ruby
class ApiController < ActionController::API
  # Warden 使用说明：
  # 这是 API 控制器，不需要用户身份验证。
  # 如果要返回 401 状态时内容响应不被 Warden 拦截处理，需要执行 custom_failure!。
  # 如果不调用 custom_failure!，Warden 中间件会拦截 401 响应并重定向到登录页面。
  # 调用 custom_failure! 后，控制器可以返回 JSON 格式的 401 响应，而不是 HTML 重定向。
  before_action -> { request.env["warden"]&.custom_failure! }

  def create
    # 返回 JSON 格式的 401 响应，不会被 Warden 拦截
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
```

### 关键要点

1. **使用安全导航操作符**：`request.env["warden"]&.custom_failure!` 使用 `&.` 避免 `warden` 为 `nil` 时的错误。

2. **在 before_action 中调用**：确保在所有 action 执行前调用，这样即使 action 返回 401，也不会被 Warden 拦截。

3. **Lambda 表达式**：使用 `-> { }` 创建 lambda，可以直接在 `before_action` 中调用。

## 关键经验总结

### 何时使用 custom_failure!

1. **API 控制器返回 401**：当 API 控制器需要返回 401 状态码时，应该调用 `custom_failure!` 避免被 Warden 拦截。

2. **不需要用户身份验证的控制器**：对于不需要用户身份验证的控制器（如 CDN 回源鉴权 API、公开 API 等），应该调用 `custom_failure!`。

3. **自定义错误处理**：当需要自定义错误响应格式（如 JSON）时，应该调用 `custom_failure!`。

### 注意事项

1. **不要在所有控制器中使用**：只有需要自定义错误处理的控制器才需要使用 `custom_failure!`。对于需要用户身份验证的控制器，应该让 Warden 正常处理认证失败。

2. **测试环境**：在测试中，`Warden.test_mode!` 不会影响 `custom_failure!` 的行为，仍然需要调用 `custom_failure!`。

3. **ActionController::API**：`ActionController::API` 默认不支持 session，但 Warden 中间件仍然会尝试处理请求，因此需要调用 `custom_failure!`。

### 替代方案

如果不想在每个控制器中调用 `custom_failure!`，可以考虑：

1. **创建基类**：创建一个 `ApiController` 基类，在其中调用 `custom_failure!`，其他 API 控制器继承这个基类。

2. **修改 failure_app**：在 `config/initializers/warden.rb` 中修改 `failure_app`，根据请求格式（JSON/HTML）返回不同的响应。

3. **使用路由约束**：在路由中为 API 路径添加约束，跳过 Warden 中间件（不推荐，因为会影响其他功能）。

## 相关文件

- `app/controllers/` - 使用 `custom_failure!` 的 API 控制器
- `config/initializers/warden.rb` - Warden 配置，包含 `failure_app` 定义
- `test/controllers/` - 测试文件，验证 401 响应不被拦截

## 参考资料

- [Warden GitHub](https://github.com/wardencommunity/warden)
- [Warden Documentation](https://github.com/wardencommunity/warden/wiki)
- [Rails API Controllers](https://guides.rubyonrails.org/api_app.html)

