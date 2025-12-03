# BuildX.work 🚀

> 一个开源的 Ruby on Rails 业务网站生成平台，集成企业级基础功能，让您专注于业务逻辑开发。

## 📖 关于本项目

**BuildX.work** 是一个功能完整的 Rails 应用模板，用于生成不同业务网站。通过提供一套经过验证的企业级功能模块，帮助开发者快速启动新项目，避免因复制代码而遗漏关键功能。

## 🎯 快速导航

### 📚 基础设施文档

**详细的基础设施文档请查看**：[`engines/buildx_core/README.md`](engines/buildx_core/README.md)

包含：
- 项目简介和定位
- 技术栈说明
- 功能模块介绍
- 快速开始指南
- 部署说明
- 开发计划
- 完整文档索引

### 📁 业务项目文档

**如果您正在基于 BuildX.work 开发业务项目**，请将业务相关的文档放在 `docs/project-[项目名称]/` 目录下。

**当前业务项目**：
- 📋 [项目名称](docs/project-[项目名称]/README.md) - 项目文档索引

> 💡 **提示**：项目初始化时，请更新此处的项目名称和链接地址，方便快速跳转到业务项目文档。

**文档存放规范**：
- ✅ **基础设施文档**：保持在 `docs/` 根目录（如 `docs/DEVELOPER_GUIDE.md`、`docs/phase-*/`）
- ✅ **业务项目文档**：存放在 `docs/project-[项目名称]/` 目录下
- ✅ **根目录 README**：保持为基础设施文档，但可以更新业务项目链接部分

**示例结构**：

```
docs/
├── [基础设施文档]              # buildx.work 的通用文档
│   ├── README.md
│   ├── DEVELOPER_GUIDE.md
│   ├── phase-1-authentication/
│   └── ...
│
└── project-[项目名称]/         # 业务项目的特定文档
    ├── README.md              # 项目文档索引（不使用数字前缀）
    ├── 01-BUSINESS_ANALYSIS.md
    ├── 02-PROJECT_PLAN.md
    └── ...
```

**这样设计的好处**：
- ✅ 降低合并冲突：基础设施文档和业务文档隔离
- ✅ 便于维护：基础设施更新不会影响业务文档
- ✅ 清晰分离：基础设施和业务逻辑职责明确

## 🔗 重要链接

- 📖 [基础设施详细文档](engines/buildx_core/README.md) ⭐ **查看完整文档**
- 📋 [当前工作状态](CURRENT_WORK.md) ⭐ 每日必看
- 📚 [文档索引](docs/README.md) - 所有文档的导航
- 🚀 [使用指南](docs/USAGE_GUIDE.md) - 如何创建子项目、如何扩展、如何更新
- 🤖 [AI 使用教程](docs/AI_USAGE_GUIDE.md) - 快速上手 AI 开发

## 📧 联系方式

- 提交 [Issue](https://github.com/xiaohui-zhangxh/buildx.work/issues)
- 查看 [开发文档](docs/README.md)

---

**注意**：本项目仍在积极开发中，部分功能可能尚未完成。欢迎参与贡献！
