# 第一阶段开发笔记

## 📝 开发过程中的问题和解决方案

### 2024-XX-XX

**问题**：如何集成 Warden 和 Rails 8 Authentication Generator？  
**解决方案**：Warden 作为身份管理中间件，Authentication Generator 生成基础认证代码，两者可以很好地配合使用。

### 2025-11-24

**问题**：Warden 策略在测试中无法正确获取参数  
**解决方案**：修改 Warden Password Strategy，使用多种方式获取参数（request.params、params、env["rack.request.form_hash"]），确保在测试和生产环境中都能正常工作。

**问题**：测试中 Current.user 在请求间无法正确保持  
**解决方案**：在测试中，Current 是请求级别的，每个新请求都会重置。需要确保 Warden 在请求中正确恢复 session。部分测试需要进一步调试。

**问题**：用户管理功能实现  
**解决方案**：实现了 UsersController 的 index、show、edit、update 方法，创建了相应的视图文件（使用 DaisyUI 样式），添加了路由配置。用户只能编辑自己的资料。

**问题**：邮件模板样式  
**解决方案**：使用内联样式（邮件客户端不支持外部 CSS）创建了美观的密码重置邮件模板，参考 DaisyUI 的设计风格。

**问题**：测试覆盖率提升  
**解决方案**：
- 配置 SimpleCov 过滤不需要测试的文件（config、db、lib/tasks 等），只统计 app/ 目录下的代码
- 为 Session 模型添加了完整的测试，覆盖所有方法和边界情况（覆盖率 100%）
- 为 Authentication concern 添加了 21 个测试，覆盖了大部分代码路径（覆盖率 89.36%）
- 主要代码文件（User、Session、主要控制器）的覆盖率都达到了 100%
- 剩余未覆盖的代码主要是 `restore_user_from_remember_token` 中 `warden.logout` 的分支，在集成测试中难以直接模拟 signed cookies

**问题**：Authentication concern 中部分代码难以测试  
**解决方案**：对于难以在集成测试中模拟的场景（如 signed cookies），采用间接测试的方式，通过测试功能行为来验证代码逻辑。对于特别复杂的场景（如 ActionCable Connection），暂时排除在覆盖率计算外，但已添加基础测试覆盖主要代码路径。

**问题**：个人中心功能设计  
**解决方案**：
- 使用 `my` 命名空间，路由更简洁直观（如 `/my`、`/my/sessions`）
- 个人中心首页（仪表板）显示账户概览、统计信息和最近登录记录
- 会话管理功能：
  - 显示所有活跃会话和历史会话
  - 支持退出单个设备（使用 `terminate_session_by_id` 方法）
  - 支持批量退出所有其他设备（排除当前会话）
  - 会话记录保留用于审计（不删除，只标记为 inactive）
- 整合现有的个人信息编辑功能到 `My::ProfileController`
- 安全设置独立页面，用于修改密码和查看账户状态
- 使用 DaisyUI 组件保持 UI 风格一致

**问题**：UI/UX 优化和测试失败修复  
**解决方案**：
- Flash 消息自动消失：使用 Stimulus flash_controller，支持 5 秒后自动关闭
- 表单提交 loading 状态：使用 DaisyUI loading spinner 图标，通过 Stimulus form_controller 管理，支持 Turbo 事件
- 时间显示优化：format_time helper 自动选择格式（今天/本周/本月/更长时间）
- 设备信息显示优化：使用 useragent gem 解析 user_agent，提供更友好的浏览器和系统信息
- 导航栏提取：将导航栏提取为独立 partial，便于维护
- 主题切换封装：使用 Stimulus theme_controller，支持 Turbo 页面切换
- 测试失败修复：修复 User 模型测试中的错误消息断言（从英文改为中文，适配 zh-CN locale）

**问题**：密码修改时间记录和智能提示  
**解决方案**：
- 添加 `password_changed_at` 字段到 User 模型，记录上次修改密码的时间
- 使用 `before_save` 回调自动跟踪密码修改（当 `password_digest_changed?` 时）
- 新用户创建时，通过迁移和 `after_create` 回调设置初始 `password_changed_at` 为 `created_at`
- 实现密码过期检查功能：
  - 默认过期时间为 90 天（`PASSWORD_EXPIRATION_DAYS` 常量）
  - `password_expired?` - 检查密码是否已过期
  - `password_expires_soon?` - 检查密码是否即将过期（默认 7 天内）
  - `days_since_password_change` - 密码已使用天数
  - `days_until_password_expires` - 距离过期还有多少天
- 在安全设置页面显示密码状态、上次修改时间、过期提示
- 在个人中心首页显示密码过期警告（已过期或即将过期时）
- 使用不同颜色的徽章和警告提示用户密码状态（正常/即将过期/已过期）

**问题**：个人中心功能测试覆盖  
**解决方案**：
- 为所有 my 命名空间的控制器创建了完整的测试文件：
  - `My::DashboardController` - 测试认证要求、数据显示、密码警告等场景（6 个测试用例）
  - `My::ProfileController` - 测试 show、edit、update 的所有场景，包括成功和失败情况（10 个测试用例）
  - `My::SecurityController` - 测试 show、update 的所有场景，包括密码更新逻辑（9 个测试用例）
  - `My::SessionsController` - 测试 index、destroy、destroy_all_others 的所有场景（9 个测试用例）
- 为 User 模型的密码过期功能添加了完整测试（13 个测试用例）：
  - 测试所有密码过期相关方法的所有分支和边界情况
  - 测试回调函数的正确执行
- 所有测试通过（178 个测试，492 个断言，0 失败，0 错误，1 跳过）

## 💡 技术决策记录

### 为什么选择 Warden？

1. **策略模式**：支持多种认证方式（密码、Token、OAuth）
2. **可扩展性**：易于添加新的认证策略
3. **统一接口**：为 Web 和 API 提供统一的身份管理
4. **社区支持**：成熟稳定的 gem

### 为什么使用 Rails 8 Authentication Generator？

1. **官方支持**：Rails 官方维护，与框架深度集成
2. **最佳实践**：遵循 Rails 安全最佳实践
3. **代码质量**：生成的代码简洁、安全
4. **快速启动**：节省大量基础开发时间

## 🐛 已知问题

- [ ] Authentication concern 中 `restore_user_from_remember_token` 的 `warden.logout` 分支未完全覆盖
  - 影响范围：代码覆盖率 89.36%（42/47），剩余 5 行未覆盖
  - 问题原因：在集成测试中难以直接模拟 signed cookies 来触发该分支
  - 解决方案：考虑使用单元测试或控制器测试来覆盖该分支，或接受当前覆盖率水平

## 📚 参考资料

- [Rails Security Guide](https://guides.rubyonrails.org/security.html#authentication)
- [Warden Documentation](https://github.com/wardencommunity/warden)
- [DaisyUI Documentation](https://daisyui.com/)

## 🔗 相关文档

- [开发计划](./plan.md)
- [开发进度](./progress.md)
- [阶段概览](./README.md)

