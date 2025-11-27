# 基础设施修复贡献总结

> 从子项目中发现并贡献回基础设施的修复

## 📋 安装向导检查分析

### 当前状态

**基础设施（buildx.work）**：
- ✅ 已有 `check_installation_status` before_action
- ✅ 已有完整的安装检查逻辑
- ✅ 会跳过 installation 控制器和 health check
- ✅ 会跳过 admin 命名空间

**buildx-notify**：
- ✅ 与基础设施完全一致
- ✅ 没有额外的改动

**结论**：安装向导检查功能在基础设施中已经完整实现，**不需要贡献任何改动**。

---

## ✅ 已贡献的修复

### 1. daisy_form_with 参数包装问题 ✅

**问题**：当同时提供 `model` 和 `url` 参数时，参数没有被正确包装在模型命名空间中。

**修复前**：
```ruby
if url.present? || scope.present?
  form_with(scope: scope, url: url, ...)  # 参数不会被包装
```

**修复后**：
```ruby
if model.present?
  form_with(model: model, url: url, ...)  # 参数会被正确包装为 user[...]
elsif scope.present?
  form_with(scope: scope, url: url, ...)
elsif url.present?
  form_with(url: url, ...)
```

**文件**：`app/helpers/application_helper.rb`

**影响**：修复了用户注册时 `ActionController::ParameterMissing: param is missing or the value is empty: user` 错误。

---

### 2. 邮件链接端口配置 ✅

**问题**：开发环境中邮件链接的端口硬编码为 3000，但服务器可能运行在其他端口（如 3002）。

**修复前**：
```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

**修复后**：
```ruby
port = ENV.fetch("PORT", "3000").to_i
config.action_mailer.default_url_options = { host: "localhost", port: port }
```

**文件**：`config/environments/development.rb`

**影响**：确认邮件中的链接现在会使用正确的服务器端口。

---

### 3. Pagy 分页支持 ✅

**需求**：业务项目需要使用 Pagy 分页功能。

**添加内容**：
1. **Gemfile**：
   - 添加 `gem "pagy", "~> 9.3", ">= 9.3.4"`
   - 添加 `gem "unicode-display_width", "~> 2.5"`

2. **ApplicationHelper**：
   - 添加 `include Pagy::Frontend`
   - 提供 `pagy_nav` 等分页辅助方法

3. **ApplicationController**：
   - 添加 `include Pagy::Backend`
   - 提供 `pagy` 方法用于分页查询

4. **Initializer**：
   - 创建 `config/initializers/pagy.rb`
   - 配置默认每页 50 条记录
   - 配置溢出处理为 `empty_page`

**影响**：所有使用基础设施的项目现在都可以直接使用 Pagy 分页功能，无需额外配置。

---

## 📊 贡献统计

- ✅ **3 个修复/功能**已贡献到基础设施
- ✅ **2 个 bug 修复**（daisy_form_with、邮件端口）
- ✅ **1 个新功能**（Pagy 分页支持）
- ✅ **0 个安装向导相关改动**（基础设施已完整）

---

## 🔄 下一步

1. **测试基础设施**：
   ```bash
   cd buildx.work
   bundle install
   bin/rails test
   ```

2. **更新子项目**：
   - buildx-notify 和 buildx-qiniu-auth 可以通过 `git merge upstream/main` 获取这些修复
   - 子项目可以移除 Pagy 相关的扩展代码（因为基础设施已包含）

3. **文档更新**：
   - 更新使用指南，说明 Pagy 分页功能
   - 更新贡献指南，记录此次贡献过程

---

## 📚 参考

- [buildx-notify CONTRIBUTE_FIXES.md](../buildx.run/buildx-notify/CONTRIBUTE_FIXES.md)
- [buildx-qiniu-auth CONTRIBUTE_FIXES.md](../buildx.run/buildx-qiniu-auth/CONTRIBUTE_FIXES.md)
- [贡献指南](./docs/CONTRIBUTING.md)
