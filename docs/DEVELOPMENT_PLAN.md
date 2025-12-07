# 开发计划总览

本文档提供项目整体开发计划的概览。详细的阶段计划请查看各阶段的文档。

## 📚 文档结构

所有开发文档按阶段组织在 `docs/` 目录下：

```
docs/
├── README.md                    # 文档索引
├── DEVELOPER_GUIDE.md           # 开发者指南
│
├── phase-1-authentication/      # 第一阶段：用户认证系统
├── phase-2-authorization/        # 第二阶段：权限系统
├── phase-3-multi-tenant/         # 第三阶段：多租户支持
└── phase-4-advanced/            # 第四阶段：高级功能
```

每个阶段包含：

- `README.md` - 阶段概览
- `plan.md` - 详细开发计划
- `progress.md` - 开发进度跟踪
- `notes.md` - 开发笔记

## 🗺️ 开发路线图

### 第一阶段：用户认证系统 🚧
**状态**：进行中  
**文档**：[docs/phase-1-authentication/](docs/phase-1-authentication/)  
**主要内容**：

- 邮箱注册/登录
- 密码找回
- 基础用户管理
- Warden 集成

### 第二阶段：权限系统 + 管理后台 📋
**状态**：计划中  
**文档**：[docs/phase-2-authorization/](docs/phase-2-authorization/)  
**主要内容**：

- 角色管理系统（RBAC）
- 权限控制系统
- 资源级权限
- **管理后台**（用户管理、角色管理、系统配置、日志查看、仪表盘）

### 第三阶段：多租户支持 📋
**状态**：计划中  
**文档**：[docs/phase-3-multi-tenant/](docs/phase-3-multi-tenant/)  
**主要内容**：

- 租户隔离
- Account 模型（SaaS 租户账号）
  - 外部 ID（External ID）支持
  - Slug 编码/解码
  - JoinCode 加入码机制
  - Current 对象管理
- 组织架构
- 团队管理

### 第四阶段：通用业务功能系统 📋
**状态**：计划中  
**文档**：[docs/phase-4-common-features/](docs/phase-4-common-features/)  
**主要内容**：

- **内容交互系统**：
  - 评论系统（Comment System）- 多态关联
  - 提及系统（Mention System）
  - 反应系统（Reaction System）- 多态关联
- **内容组织系统**：
  - 标签系统（Tag/Tagging）- 多态关联
  - 置顶系统（Pin）- 多态关联
  - 关注系统（Watch）- 多态关联
  - 分配系统（Assignment）- 多态关联
- **搜索与筛选系统**：
  - 搜索系统（Search）- 全文搜索、自动索引
  - 筛选系统（Filter）- 高级筛选、条件保存
- **访问控制系统**：
  - 资源访问控制（Access）- 多态关联
- **事件系统**：
  - Event 审核日志系统（Eventable Concern）
  - 事件记录和追踪
  - 事件 Webhook 分发

### 第五阶段：通知与 Webhook 系统 📋
**状态**：计划中  
**文档**：[docs/phase-5-notification/](docs/phase-5-notification/)  
**主要内容**：

- **通知系统**：
  - 站内通知（多态关联、已读/未读、推送通知）
  - 通知聚合（Bundle）
  - 通知偏好设置
- **Webhook 系统**：
  - Webhook 创建与配置
  - 事件订阅管理
  - Webhook 签名验证
  - 重试机制
  - Webhook 日志记录

### 第六阶段：高级功能 📋
**状态**：计划中  
**文档**：[docs/phase-6-advanced/](docs/phase-6-advanced/)  
**主要内容**：

- API 支持
- AI MCP 服务集成
- 系统监控
- 健康检查端点

## 🔗 快速链接

- [文档索引](docs/README.md)
- [开发者指南](docs/DEVELOPER_GUIDE.md)
- [第一阶段详细计划](docs/phase-1-authentication/plan.md)
- [第一阶段开发进度](docs/phase-1-authentication/progress.md)

## 📝 开发原则

1. **渐进式开发**：按阶段逐步实现，每个阶段完成后才进入下一阶段
2. **文档先行**：重要决策和设计先记录在文档中
3. **测试驱动**：每个功能都要有对应的测试
4. **代码规范**：遵循 Rails 最佳实践和项目规范
5. **多态关联优先**：通用业务功能（评论、标签、关注等）优先使用多态关联设计，提高代码复用性和可扩展性
6. **学习最佳实践**：参考 Basecamp Fizzy 等优秀项目的设计模式，应用到 BuildX 中

## 📚 学习参考

### Fizzy 最佳实践学习

我们从 Basecamp Fizzy 项目学习到了很多通用业务设计模式，这些模式已经应用到 BuildX 的功能规划中：

- **SaaS 多租户 Account 设计**：外部 ID、Slug、JoinCode、Current 对象管理
- **Event 审核日志系统**：多态关联、Eventable Concern、Particulars
- **通用业务功能**：评论、提及、通知、关注、标签、反应、置顶、分配、搜索、筛选、访问控制
- **多态关联设计模式**：提高代码复用性和可扩展性

详细学习文档请参考：[docs/experiences/fizzy-overview.md](../experiences/fizzy-overview.md)
