# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增

- 实现 dialog + turbo frame 菜单交互功能（2025-12-26）
  - 新增 Dialog Manager Stimulus 控制器（`dialog_manager_controller.js`），管理对话框的打开、关闭和内容加载
  - 新增可复用的对话框组件（`_dialog.html.erb`），使用 dialog + turbo frame 实现功能菜单加载
  - 支持延迟加载、局部更新、DaisyUI 样式和响应式设计
  - 学习自 Basecamp Fizzy 项目的交互方式
- 添加 Fizzy dialog + turbo frame 学习文档（2025-12-26）
  - 新增 `fizzy-dialog-turbo-frame.md`：学习文档，包含核心概念、实现方式和最佳实践
  - 新增 `fizzy-dialog-turbo-frame-usage.md`：使用示例文档，包含完整代码示例和使用场景
  - 更新 `fizzy-overview.md`：添加新文档链接
- 添加 Rails strict locals 学习文档（2025-12-26）
  - 新增 `rails-strict-locals.md`：学习文档，包含语法、示例、最佳实践和迁移指南
  - 在 `_dialog.html.erb` 中应用 strict locals 规范，使用 `html_class` 替代 `class` 参数（避免保留关键字冲突）
  - 参考 Rails 8 官方文档：https://guides.rubyonrails.org/action_view_overview.html#strict-locals
- 添加阶段 3 多租户产品文档（2025-12-26）
  - 新增 `docs/phase-3-multi-tenant/PRODUCT.md`：产品文档，包含产品价值、用户故事、功能特性等
  - 更新 `docs/phase-3-multi-tenant/README.md`：更新阶段概览
  - 更新 `docs/phase-3-multi-tenant/plan.md`：更新开发计划
- 添加 Fizzy 项目学习文档（2025-12-07）
  - 新增 27 个 Fizzy 学习专题文档，涵盖代码风格、模型设计、控制器设计、Hotwire 使用、路由设计、测试策略、业务系统设计等内容
  - 包含完整的学习指南和最佳实践总结
  - 新增 Fizzy 项目分析脚本（`script/analyze_fizzy.sh`）
- 增强经验系统功能和 SEO 优化（2025-12-07）
  - 添加相对路径链接自动转换功能，支持经验文档间的链接跳转
  - 添加 meta tags 设置，优化 SEO 和社交媒体分享（description、keywords、OG、Twitter Card）
  - 优化经验列表卡片显示，添加描述信息和标签显示
  - 添加相关测试用例
- 添加 Google Analytics 4 支持（2025-12-04）
  - 集成 Google Analytics 4（gtag.js）
  - 支持通过系统配置（SystemConfig）设置 Google Analytics 测量 ID
  - 在应用布局中自动加载 Google Analytics 脚本（仅当配置了测量 ID 时）
- 集成 RubyLLM 统一 AI 接口库（2025-12-04）
  - 集成 RubyLLM gem（~> 1.9.1）作为统一的 AI 接口库
  - 支持多种 AI 服务提供商（通过 OpenRouter）
  - 配置 OpenRouter API 密钥和模型选择（通过系统配置）
  - 修复 RubyLLM 的 tool_calls 解析问题（Monica API 兼容性）
  - 添加 AI 配置到系统配置（OpenRouter API Key、模型、Google TTS 等）
- 实现导航栏滚动交互功能（2025-12-04）
  - 创建 Stimulus 控制器（navbar_controller.js）实现导航栏自动隐藏/显示
  - 实现上滑隐藏、下滑显示的逻辑
  - 在页面顶部（滚动位置 ≤ 50px）时始终显示导航栏
  - 添加平滑的 CSS 动画过渡效果（300ms）
  - 使用性能优化技巧（requestAnimationFrame、滚动阈值、防抖机制）
  - 创建开发经验文档记录最佳实践
- 扩展 Highlight.js 语言支持（2025-12-04）
  - 添加更多编程语言的语法高亮支持
  - 优化代码高亮显示效果
- 创建合并贡献代码指令（2025-12-04）
  - 添加 `.cursor/commands/83-merge-contribution.md` 指令文件
  - 定义贡献代码合并流程和规范
  - 支持深度代码审查和风险分析
- 添加 Tailwind CSS 配置管理文档（2025-12-05）
  - 创建完整的 Tailwind CSS 配置管理指南（`docs/TAILWIND_CSS_CONFIGURATION.md`）
  - 说明如何通过系统配置管理 Tailwind CSS 主题和配置
  - 记录实际使用的方案（lofi、dracula 主题）
- 添加 Turbo progress bar 样式表（2025-12-05）
  - 添加 `app/assets/stylesheets/turbo-progress-bar.css` 样式文件
  - 优化 Turbo 页面加载进度条显示效果

### 变更

- 更新项目文档和进度（2025-12-26）
  - 更新 `.cursor/rules/base.mdc`：添加 Rails strict locals 相关规则
  - 更新 `CURRENT_WORK.md`：记录当前工作状态
  - 更新 `TEST_COVERAGE_TASKS.md`：更新测试覆盖率任务
  - 更新 `docs/DEVELOPER_GUIDE.md`：更新开发者指南
  - 更新 `docs/FEATURES.md`：更新功能清单
  - 更新 `docs/phase-2-authorization/progress.md`：更新阶段 2 进度
  - 更新 `engines/buildx_core/README.md`：更新核心引擎文档
- 完善测试用例（2025-12-26）
  - 更新 `test/controllers/experiences_controller_test.rb`：添加更多测试用例
  - 更新 `test/forms/installation_form_test.rb`：添加更多测试用例
- 完善经验文档 metadata（2025-12-07）
  - 为 11 个现有经验文档添加 tags 和 description 字段，便于后续通过标签系统进行筛选和检索
  - 修复 form-local-parameter.md 的 YAML 格式问题
- 更新规则文档和脚本路径（2025-12-07）
  - 更新脚本目录路径说明，统一使用 script/ 目录
- 重构系统配置为 YAML 文件管理（2025-12-04）
  - 将系统配置从数据库迁移到 YAML 文件（`config/system_configs.yml`）
  - 支持配置的默认值和描述信息
  - 简化配置管理流程，提高可维护性
  - 更新 SystemConfig 模型以支持 YAML 配置
- 更新 Cursor 指令和规则文档（2025-12-04）
  - 完善指令文件的格式和内容
  - 统一文档风格和结构
- 完善 AI 使用指南并统一经验文档格式（2025-12-04）
  - 更新 AI 使用指南文档
  - 统一经验文档的格式和元数据
  - 添加经验文档索引和分类
- 优化移动端列表界面设计（2025-12-04）
  - 优化 experiences 列表界面的移动端显示
  - 解决移动端"查看详情"按钮与内容关联不清晰的问题
  - 优化移动端卡片视觉边界（背景色块 + 浅边框）
  - 优化卡片内按钮设计（使用 outline 样式）
  - 创建开发经验文档记录最佳实践
- 创建项目更新日志管理指令（2025-12-03）
  - 添加 `.cursor/commands/changelog.md` 指令文件
  - 定义更新日志的创建和管理流程
- 创建项目更新日志文件（2025-12-03）
  - 在项目根目录创建 `CHANGELOG.md` 文件
  - 记录项目的重要变更和里程碑
  - 遵循 [Keep a Changelog](https://keepachangelog.com/) 规范
- 优化更新日志指令文件格式（2025-12-03）
  - 从规则文件格式（`.mdc`）改为指令文件格式（`.md`）
  - 移除元数据头部，适配 BuildX 项目规范
- 完善更新日志内容（2025-12-03）
  - 将贡献摘要中的修复记录到更新日志
  - 添加 Pagy 分页支持、daisy_form_with 修复、邮件端口配置修复等记录
- 清理 Tailwind CSS 配置文档，删除无意义内容（2025-12-05）
  - 删除未采用的方案和与项目无关的内容
  - 删除假设性的"未来阶段"内容
  - 更新为实际使用的方案（lofi、dracula 主题）
  - 简化文档结构，使其更清晰实用
- 将 sync upstream 指令从 rebase 改为 merge 策略（2025-12-05）
  - 使用 git merge 而不是 git rebase
  - 保留合并记录，避免重复检查代码
  - 更新所有相关说明和示例
- 优化布局和视图样式（2025-12-05）
  - 将主题控制器从 body 移到 html 标签，提高主题切换的准确性
  - 格式化 Google Analytics 脚本标签，提高代码可读性
  - 移除 experiences/show 页面中多余的 prose class
- 改进 SystemConfig.ensure_config 方法（2025-12-05）
  - 允许更新描述和分类而不覆盖现有值
  - 保持现有配置值的同时允许元数据更新
  - 提高配置管理的灵活性

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
