---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、总览
status: 已完成
tags: Fizzy、学习总览、文档索引、最佳实践
description: Fizzy 最佳实践学习的总览文档，包含所有专题文档的索引和链接，以及可以应用到 BuildX 的实践总结
---

# Fizzy 最佳实践学习总览

## 项目概述

**Fizzy** 是 Basecamp/37signals 开源的 Kanban 看板工具，采用 Ruby on Rails 8.1 + Hotwire 开发。

- **GitHub**: https://github.com/basecamp/fizzy
- **技术栈**: Rails 8.1, Hotwire (Turbo + Stimulus), Kamal, SQLite/MySQL
- **代码规模**: 588 个 Ruby 文件, 305 个 ERB 视图, 175 个测试文件
- **最新提交**: 2025-12-07

## 学习目标

1. 理解 Basecamp 的 Rails 项目结构组织方式
2. 学习他们的代码风格和最佳实践
3. 了解他们的部署和配置方式
4. 学习 Hotwire 的使用方式
5. 理解他们的测试策略

## 学习文档索引

本文档是 Fizzy 最佳实践学习的总览，详细内容请参考以下专题文档：

### 1. 📝 [代码风格指南](fizzy-code-style-guide.md)

学习 Basecamp 的代码风格规范，包括：
- 条件返回的写法
- 方法排序和组织
- 可见性修饰符的使用
- CRUD 控制器的设计
- 控制器和模型的交互方式
- 异步操作的命名约定

### 2. 🗄️ [模型设计模式](fizzy-model-design.md)

学习 Fizzy 的模型设计，包括：
- 使用 Concerns 组织功能
- 作用域（Scopes）的设计
- 业务逻辑封装
- 查询优化策略
- 模型关系设计

### 3. 🎮 [控制器设计模式](fizzy-controller-design.md)

学习 Fizzy 的控制器设计，包括：
- 薄控制器设计
- 使用 Concerns 组织共享逻辑
- 权限控制方式
- 参数处理
- 响应格式处理

### 4. ⚡ [Hotwire 使用实践](fizzy-hotwire-practices.md)

学习 Fizzy 中 Hotwire 的使用，包括：
- Turbo Streams 实时更新
- Turbo Frames 局部更新
- Stimulus 控制器组织
- 广播机制
- 视图组织方式

### 5. 🛣️ [路由设计](fizzy-routing-design.md)

学习 Fizzy 的路由设计，包括：
- RESTful 资源设计
- 命名空间和模块使用
- 路由解析器（resolve 和 direct）
- 路由组织方式

### 6. 🧪 [测试策略](fizzy-testing-strategy.md)

学习 Fizzy 的测试策略，包括：
- 测试组织方式
- 测试辅助方法
- UUID Fixtures 支持
- 并行测试配置
- 测试模式

### 7. 📧 [后台任务和邮件系统](fizzy-jobs-and-mailers.md)

学习 Fizzy 的后台任务和邮件系统，包括：
- 任务设计原则
- 邮件类设计
- 多租户 URL 处理
- 错误处理策略

### 8. 🚀 [高级特性](fizzy-advanced-features.md)

学习 Fizzy 的高级特性，包括：
- Action Cable 连接管理
- Rails 扩展（rails_ext）
- 内容安全策略（CSP）
- 自定义库组织

### 9. 🐳 [部署和配置](fizzy-deployment.md)

学习 Fizzy 的部署和配置，包括：
- Kamal 部署配置
- 应用配置
- 数据库配置
- 环境变量管理

## 通用业务设计技巧

以下文档总结了从 Fizzy 学习到的通用业务设计技巧，这些技巧可以应用到各种 SaaS 项目中：

### 10. 🏢 [SaaS 多租户 Account 设计](fizzy-saas-account-design.md)

学习 Fizzy 的多租户 Account 设计，包括：
- Account 模型设计
- 外部 ID 和 Slug
- 数据隔离策略
- URL 路由设计
- Join Code 设计
- Current 对象管理

### 11. 📝 [Event 审核日志系统](fizzy-event-audit-log.md)

学习 Fizzy 的 Event 审核日志系统，包括：
- Event 模型设计
- Eventable Concern
- 多态关联
- Action 命名
- Particulars 详细信息
- 条件记录
- Webhook 集成

### 12. 💬 [评论系统设计](fizzy-comment-system.md)

学习 Fizzy 的评论系统设计，包括：
- Comment 模型设计
- 富文本支持
- 自动关注
- 系统评论
- 反应功能
- Turbo Stream 集成

### 13. @ [提及（Mention）系统设计](fizzy-mention-system.md)

学习 Fizzy 的提及系统设计，包括：
- Mention 模型设计
- Mentions Concern
- 从附件提取提及
- 可提及用户范围
- 自动关注
- 异步处理

### 14. 🔔 [通知系统设计](fizzy-notification-system.md)

学习 Fizzy 的通知系统设计，包括：
- Notification 模型设计
- Notifiable Concern
- Notifier 模式
- 已读/未读状态管理
- 推送通知
- 通知聚合（Bundle）

### 15. 👀 [关注系统设计](fizzy-watch-system.md)

学习 Fizzy 的关注系统设计，包括：
- Watch 模型设计
- Watchable Concern
- 自动关注创建者
- 软关注/取消关注
- 通知集成

### 16. 🏷️ [标签系统设计](fizzy-tag-system.md)

学习 Fizzy 的标签系统设计，包括：
- Tag/Tagging 模型设计
- Taggable Concern
- 标签规范化
- 切换标签
- 标签过滤
- Hashtag 支持

### 18. 🔍 [过滤系统设计](fizzy-filter-system.md)

学习 Fizzy 的过滤系统设计，包括：
- Filter 模型设计
- 模块化设计（Fields, Params, Resources, Summarized）
- 链式查询构建
- 条件保存和缓存
- Filterable Concern

### 19. 👍 [反应系统设计](fizzy-reaction-system.md)

学习 Fizzy 的反应系统设计，包括：
- Reaction 模型设计
- 反应者记录
- 表情内容支持
- 更新关联资源

### 21. 📌 [置顶系统设计](fizzy-pin-system.md)

学习 Fizzy 的置顶系统设计，包括：
- Pin 模型设计
- Pinnable Concern
- 用户级别的置顶
- 实时更新

### 22. 👥 [分配系统设计](fizzy-assignment-system.md)

学习 Fizzy 的分配系统设计，包括：
- Assignment 模型设计
- Assignable Concern
- 记录分配者和被分配者
- 自动关注和事件记录

### 23. 🔎 [搜索系统设计](fizzy-search-system.md)

学习 Fizzy 的搜索系统设计，包括：
- Searchable Concern
- 自动索引
- 多数据库适配器
- 搜索高亮

### 24. 🔐 [访问控制系统设计](fizzy-access-control.md)

学习 Fizzy 的访问控制系统设计，包括：
- Access 模型设计
- Accessible Concern
- 访问级别（Involvement）
- 访问历史记录

### 25. 🔄 [多态关联通用设计模式](fizzy-polymorphic-design-patterns.md) ⭐

学习 Fizzy 的多态关联通用设计模式，包括：
- 为什么使用多态关联
- 适用场景和系统
- 实现指南
- 注意事项和最佳实践

### 26. 📋 [通用业务设计模式总结](fizzy-common-business-patterns.md)

总结 Fizzy 中其他通用的业务设计模式，包括：
- 通知系统（Notification）
- 关注系统（Watch）
- 标签系统（Tag/Tagging）
- 反应系统（Reaction）
- 访问控制（Access）
- 过滤系统（Filter）
- 置顶系统（Pin）
- 分配系统（Assignment）
- 搜索系统（Search）

## 学习工具

### 分析脚本

使用 `script/analyze_fizzy.sh` 脚本可以自动分析 Fizzy 项目结构：

```bash
./script/analyze_fizzy.sh ~/Codes/fizzy
```

分析结果保存在 `tmp/fizzy-analysis/` 目录。

### 阅读指南

详细的代码阅读指南请参考：[Fizzy 代码阅读指南](fizzy-code-reading-guide.md)

## 可以应用到 BuildX 的实践

### 代码风格
- ✅ 条件返回：优先使用展开的条件语句
- ✅ 方法排序：按调用顺序组织方法
- ✅ 可见性修饰符：不使用换行符，内容缩进
- ✅ CRUD 控制器：使用资源而不是自定义动作
- ✅ 异步操作命名：使用 `_later` 和 `_now` 后缀

### 模型设计
- ✅ 使用 Concerns：通过 Concerns 模块化功能
- ✅ 作用域链：使用链式作用域封装查询
- ✅ 业务逻辑封装：在模型中封装业务逻辑
- ✅ 默认值：使用 `default: -> { }` 提供动态默认值

### 控制器设计
- ✅ 薄控制器：保持控制器简洁
- ✅ 使用 Concerns：组织共享逻辑
- ✅ 参数处理：使用 `params.expect`
- ✅ 权限检查：封装在私有方法中

### Hotwire 使用
- ✅ Turbo Streams：实现实时更新
- ✅ Turbo Frames：实现局部更新
- ✅ Stimulus：处理交互逻辑
- ✅ 广播机制：使用 `broadcast_prepend_to`、`broadcast_remove_to` 等

### 路由设计
- ✅ RESTful 资源：使用资源而不是自定义动作
- ✅ 命名空间：使用 `scope module:` 和 `namespace` 组织路由
- ✅ 路由解析器：使用 `resolve` 和 `direct` 创建自定义路由

### 测试策略
- ✅ 并行测试：使用 `parallelize` 加速测试
- ✅ 测试辅助模块：创建可复用的测试辅助模块
- ✅ Current 对象管理：在 setup/teardown 中管理 Current 对象

### 配置
- ✅ UUID 主键：考虑为新表使用 UUID 主键
- ✅ 自动加载：配置 `autoload_lib` 包含自定义库
- ✅ 事件日志：启用事件日志调试模式

### 通用业务设计
- ✅ 多租户 Account：使用外部 ID 和 Slug 设计
- ✅ Event 审核日志：使用多态关联和 Particulars 记录详细信息
- ✅ 评论系统：支持富文本、自动关注、反应功能
- ✅ 提及系统：从 Action Text 附件中提取用户提及

## 参考资料

- [Fizzy GitHub](https://github.com/basecamp/fizzy)
- [STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md)
- [Hotwire 文档](https://hotwired.dev/)
- [Kamal 文档](https://kamal-deploy.org/)
- [Rails 指南](https://guides.rubyonrails.org/)
- [Basecamp 博客](https://world.hey.com/dhh)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

