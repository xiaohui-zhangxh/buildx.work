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
测试所有密码过期相关方法的所有分支和边界情况
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

