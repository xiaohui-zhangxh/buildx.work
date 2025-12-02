# 开发经验记录

本目录专门记录开发过程中遇到的疑难问题和解决方案，便于后续遇到类似问题时快速参考。

## 📋 经验列表

### 前端集成

- [Highlight.js 集成问题](./highlight.js.md) (2025-11-25)
  - Importmap 路径配置
  - ES Module vs CommonJS 兼容性
  - Stimulus Controller 初始化

- [Importmap SSL 证书验证错误](./importmap-ssl-certificate-error.md) (2025-11-25)
  - OpenSSL gem 配置
  - SSL 证书验证问题
  - Importmap HTTPS 连接

### 后端逻辑 / 认证系统

- [Warden custom_failure! 使用经验](./warden-custom-failure.md) (2025-11-29)
  - API 控制器返回 401 时避免 Warden 拦截
  - custom_failure! 的使用场景和注意事项
  - ActionController::API 与 Warden 的配合

### 配置问题

- [ActionMailer 动态配置从数据库读取](./action-mailer-dynamic-config.md) (2025-12-02)
  - after_initialize 中配置 ActionMailer 的正确方式
  - 实现邮件配置动态更新（无需重启服务器）
  - 共享配置读取方法的设计模式
  - ActionMailer::Base 与 Rails.application.config.action_mailer 的区别

## 📝 如何添加新经验

1. 在 `experiences/` 目录下创建新的 Markdown 文件
2. 文件名使用简洁的描述性名称，如 `highlight.js.md`、`importmap-issue.md`
3. 文件内容应包含：
   - 问题描述
   - 问题原因分析
   - 解决方案（步骤清晰）
   - 关键经验总结
   - 相关文件列表
   - 参考资料

4. 在本 README.md 中添加经验索引

## 🎯 文档模板

```markdown
# [问题标题]

**日期**：YYYY-MM-DD  
**问题类型**：前端集成 / 后端逻辑 / 配置问题 / 性能优化  
**状态**：✅ 已解决 / 🚧 进行中 / ❌ 未解决

## 问题描述

详细描述遇到的问题和现象。

## 问题原因分析

分析问题的根本原因。

## 解决方案

### 步骤 1：...

### 步骤 2：...

## 关键经验总结

总结关键经验和注意事项。

## 相关文件

- `path/to/file.rb`
- `path/to/file.js`

## 参考资料

- [链接标题](URL)
```

