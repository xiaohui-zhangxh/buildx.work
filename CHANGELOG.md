# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增

- 创建项目更新日志管理指令（2025-12-03）
  - 添加 `.cursor/commands/changelog.md` 指令文件
  - 定义更新日志的创建和管理流程
- 创建项目更新日志文件（2025-12-03）
  - 在项目根目录创建 `CHANGELOG.md` 文件
  - 记录项目的重要变更和里程碑
  - 遵循 [Keep a Changelog](https://keepachangelog.com/) 规范

### 变更

- 优化更新日志指令文件格式（2025-12-03）
  - 从规则文件格式（`.mdc`）改为指令文件格式（`.md`）
  - 移除元数据头部，适配 BuildX 项目规范
- 完善更新日志内容（2025-12-03）
  - 将贡献摘要中的修复记录到更新日志
  - 添加 Pagy 分页支持、daisy_form_with 修复、邮件端口配置修复等记录

## [0.2.0] - 2025-12-02

### 新增

- 完成第二阶段开发（权限系统 + 管理后台）
  - 实现基于 Action Policy 的权限管理系统
  - 创建管理后台命名空间（admin）
  - 实现管理后台基础功能（Dashboard、Users、Roles、Policies、SystemConfigs、AuditLogs）
  - 实现搜索和筛选功能（用户管理、角色管理、操作日志）
  - 实现批量操作功能（用户管理：批量删除、批量分配角色、批量移除角色）
  - 实现操作日志（AuditLog）功能和自动记录
  - 实现操作日志导出功能（CSV格式）
  - 实现系统安装向导（InstallationController、InstallationForm）
- 添加 Pagy 分页支持
  - 集成 Pagy gem（~> 9.3, >= 9.3.4）和 unicode-display_width gem
  - 在 ApplicationHelper 中添加 Pagy::Frontend 支持
  - 在 ApplicationController 中添加 Pagy::Backend 支持
  - 配置 Pagy 初始器（默认每页 50 条记录）
  - 所有使用基础设施的项目现在都可以直接使用 Pagy 分页功能
- 完善测试覆盖
  - 为管理后台控制器添加完整测试用例
  - 为缺少测试的文件添加测试（179 个新测试用例）
  - 代码覆盖率从 28.33% 提升到 66.28%
  - 所有测试通过（705 个测试，1800 个断言，0 失败，0 错误，3 跳过）
- 优化代码质量
  - 添加 csv gem 消除 Ruby 3.4.0 警告
  - 修复 DEPRECATED 警告
  - 配置测试环境减少干扰输出
  - RuboCop 检查通过（132 个文件，0 错误）
- 修复安全警告
  - 修复 Path Traversal 警告（高优先级）
  - 加强 File Access 和 XSS 保护

### 修复

- 修复 daisy_form_with 参数包装问题
  - 修复当同时提供 `model` 和 `url` 参数时，参数没有被正确包装在模型命名空间中的问题
  - 修复了用户注册时 `ActionController::ParameterMissing: param is missing or the value is empty: user` 错误
  - 文件：`app/helpers/application_helper.rb`
- 修复邮件链接端口配置问题
  - 修复开发环境中邮件链接的端口硬编码为 3000 的问题
  - 现在使用 `ENV.fetch("PORT", "3000")` 动态获取端口
  - 确认邮件中的链接现在会使用正确的服务器端口
  - 文件：`config/environments/development.rb`

### 变更

- 更新 `engines/buildx_core/README.md`，添加权限系统和管理后台说明
- 更新开发计划文档，标记已完成任务
- 优化开发者指南，添加测试规范

## [0.1.0] - 2025-11-24

### 新增

- 完成第一阶段开发（用户认证系统）
  - 使用 Rails 8 Authentication Generator 生成认证系统
  - 集成 Warden gem 实现身份认证
  - 实现用户注册/登录功能（邮箱注册/登录、密码找回、记住我）
  - 实现安全功能（登录失败限制、账户锁定、密码强度验证、密码过期检查）
  - 实现用户管理功能（列表、详情、编辑）
  - 实现个人中心功能（my 命名空间）
    - 个人中心首页（仪表板）
    - 会话管理功能（查看登录日志、退出设备）
    - 个人信息管理
    - 安全设置功能（修改密码、查看账户状态）
  - 实现邮件功能（用户确认邮件、密码重置邮件）
  - 优化 UI/UX 体验
    - Flash 消息自动消失
    - 表单验证实时反馈
    - 表单提交 loading 状态
    - 密码强度指示器
    - 时间显示优化
    - 设备信息显示优化
    - 页面过渡动画
- 完善测试覆盖
  - 为所有主要模型和控制器添加测试用例
  - 所有测试通过（182 个测试，全部通过）
  - 核心文件覆盖率达到 85% 以上
- 代码质量
  - RuboCop 检查通过
  - 遵循 Rails 最佳实践

### 变更

- 更新 `engines/buildx_core/README.md`，添加认证系统说明
- 完善项目文档结构

## [0.0.1] - 2025-11-23

### 新增

- 初始化项目结构
- 创建开发者文档和 Cursor 规则
- 确定技术栈（Rails 8.1.1 + Ruby 3.3.5）
- 配置开发环境

