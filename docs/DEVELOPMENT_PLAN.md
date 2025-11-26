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
- 组织架构
- 团队管理

### 第四阶段：高级功能 📋
**状态**：计划中  
**文档**：[docs/phase-4-advanced/](docs/phase-4-advanced/)  
**主要内容**：

- Webhook 系统
- 通知系统
- API 支持
- AI MCP 服务集成

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
