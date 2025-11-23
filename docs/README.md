# 开发文档索引

本文档目录按开发阶段组织，方便长期开发和维护。

## 📁 文档结构

```
docs/
├── README.md                    # 本文档（文档索引）
├── FEATURES.md                  # 功能清单（所有功能的详细列表）
├── DEVELOPMENT_PLAN.md          # 开发计划总览
├── DEVELOPER_GUIDE.md           # 开发者指南（技术决策、架构设计）
│
├── phase-1-authentication/      # 第一阶段：用户认证系统
│   ├── README.md               # 阶段概览
│   ├── plan.md                 # 详细开发计划
│   ├── progress.md             # 开发进度跟踪
│   └── notes.md                 # 开发笔记和备忘
│
├── phase-2-authorization/       # 第二阶段：权限系统
│   ├── README.md
│   ├── plan.md
│   ├── progress.md
│   └── notes.md
│
├── phase-3-multi-tenant/        # 第三阶段：多租户支持
│   ├── README.md
│   ├── plan.md
│   ├── progress.md
│   └── notes.md
│
└── phase-4-advanced/            # 第四阶段：高级功能
    ├── README.md
    ├── plan.md
    ├── progress.md
    └── notes.md
```

## 📚 文档说明

### 通用文档

- **DEVELOPER_GUIDE.md**：项目整体的技术决策、架构设计和开发规范
  - 认证系统架构
  - Warden 集成方式
  - API 认证策略
  - 开发规范

### 阶段文档

每个阶段包含以下文档：

- **README.md**：阶段概览和目标
- **plan.md**：详细的开发计划和任务清单
- **progress.md**：开发进度跟踪（已完成、进行中、待开始）
- **notes.md**：开发过程中的笔记、问题和解决方案

## 🗺️ 开发路线图

### 第一阶段：用户认证系统
**状态**：🚧 进行中  
**文档位置**：`docs/phase-1-authentication/`  
**主要内容**：
- 邮箱注册/登录
- 密码找回
- 基础用户管理
- Warden 集成

### 第二阶段：权限系统
**状态**：📋 计划中  
**文档位置**：`docs/phase-2-authorization/`  
**主要内容**：
- 角色管理
- 权限控制
- 资源权限

### 第三阶段：多租户支持
**状态**：📋 计划中  
**文档位置**：`docs/phase-3-multi-tenant/`  
**主要内容**：
- 租户隔离
- 组织架构
- 团队管理

### 第四阶段：高级功能
**状态**：📋 计划中  
**文档位置**：`docs/phase-4-advanced/`  
**主要内容**：
- Webhook 系统
- 通知系统
- API 支持
- AI MCP 服务集成

## 📝 如何添加新文档

1. **阶段内文档**：在对应阶段的文件夹中添加
2. **跨阶段文档**：在 `docs/` 根目录添加
3. **技术决策**：更新 `DEVELOPER_GUIDE.md`
4. **开发进度**：更新对应阶段的 `progress.md`

## 🔗 相关链接

- [主 README](../README.md)
- [当前工作状态](../CURRENT_WORK.md) ⭐ 每日必看
- [开发者指南](./DEVELOPER_GUIDE.md)
- [Cursor 规则](../.cursor/rules/)

