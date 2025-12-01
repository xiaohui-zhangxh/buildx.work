# 开发文档索引

本文档目录按开发阶段组织，方便长期开发和维护。

## 📁 文档结构

```
docs/
├── README.md                    # 本文档（文档索引）
├── FEATURES.md                  # 功能清单（所有功能的详细列表）
├── DEVELOPMENT_PLAN.md          # 开发计划总览
├── DEVELOPER_GUIDE.md           # 开发者指南（技术决策、架构设计）
├── PROJECT_CREATION_GUIDE.md    # 新项目创建指南 ⭐ 创建新项目时参考
│
├── experiences/                  # 开发经验记录 ⭐
│   └── highlight.js.md          # Highlight.js 集成问题
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
│   ├── notes.md
│   └── architecture.md          # 权限系统架构图 ⭐
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

- **PROJECT_CREATION_GUIDE.md** ⭐：新项目创建指南
  - 项目规划阶段
  - 项目命名阶段（唯一性检查、域名检查）
  - 技术选型阶段
  - 文档创建阶段
  - 开发计划阶段
  - 项目初始化阶段
  - 完整检查清单

- **DEVELOPER_GUIDE.md**：项目整体的技术决策、架构设计和开发规范
  - 认证系统架构
  - Warden 集成方式
  - API 认证策略
  - 开发规范

- **experiences/**：开发经验记录目录
  - 记录开发过程中遇到的疑难问题和解决方案
  - 包含问题描述、原因分析、解决步骤和关键经验
  - 便于后续遇到类似问题时快速参考

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
5. **开发经验**：在 `experiences/` 目录添加新的问题解决文档

## 🔗 相关链接

- [主 README](../README.md)
- [当前工作状态](../CURRENT_WORK.md) ⭐ 每日必看
- [新项目创建指南](./PROJECT_CREATION_GUIDE.md) ⭐ 创建新项目时参考
- [开发者指南](./DEVELOPER_GUIDE.md)
- [MCP 开发规则](../.cursor/rules/mcp.mdc) ⭐ MCP 服务开发必读（AI 自动参考）
- [Cursor 规则](../.cursor/rules/)

