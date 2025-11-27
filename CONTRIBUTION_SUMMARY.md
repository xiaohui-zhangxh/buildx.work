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

## ✅ 需要贡献的修复

### 1. daisy_form_with 参数包装问题

**问题**：当同时提供 `model` 和 `url` 参数时，参数没有被正确包装在模型命名空间中。

**修复**：
```ruby
# 修复前
if url.present? || scope.present?
  form_with(scope: scope, url: url, ...)  # 参数不会被包装

# 修复后
if model.present?
  form_with(model: model, url: url, ...)  # 参数会被正确包装为 user[...]
```

**文件**：`app/helpers/application_helper.rb`

---

### 2. 邮件链接端口配置

**问题**：开发环境中邮件链接的端口硬编码为 3000，但服务器可能运行在其他端口。

**修复**：
```ruby
# 修复前
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

# 修复后
port = ENV.fetch("PORT", "3000").to_i
config.action_mailer.default_url_options = { host: "localhost", port: port }
```

**文件**：`config/environments/development.rb`

---

### 3. Pagy 分页支持

**需求**：业务项目需要使用 Pagy 分页功能。

**添加内容**：
- Gemfile：添加 `pagy` gem
- ApplicationHelper：添加 `include Pagy::Frontend`
- ApplicationController：添加 `include Pagy::Backend`
- Initializer：添加 `config/initializers/pagy.rb`

---

## 📝 贡献步骤

所有修复将在 `fix/contribute-fixes-from-sub-projects` 分支中提交。

