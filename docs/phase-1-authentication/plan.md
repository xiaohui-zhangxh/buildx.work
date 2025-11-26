# 开发计划

## 第一阶段：用户认证系统

### 第一步：基础用户认证（邮箱注册/登录）

#### 目标
实现最基础的邮箱注册和登录功能，为后续功能打下基础。

#### 任务清单

##### 1. 环境准备
- [ ] 使用 Rails 8 Authentication Generator 生成认证系统
  ```bash
  bin/rails generate authentication
  ```
- [ ] 安装 Warden gem（身份管理）
  ```ruby
  gem "warden"
  ```
- [ ] 配置邮件发送（开发环境使用 letter_opener，生产环境配置 SMTP）
- [ ] 运行 `bundle install`

##### 2. 数据库设计
**注意**：Rails 8 Authentication Generator 会自动创建 `users` 表的迁移，包含以下字段：
密码不存储在数据库中，只存储加密后的 digest
   - 使用 HTTPS（生产环境）
   - 防止暴力破解（登录失败限制）
   - 防止 CSRF 攻击（Rails 默认保护）

#### 参考文档

开发认证功能时，请参考以下文档：

1. **开发者文档**：`docs/DEVELOPER_GUIDE.md`
   - 认证系统架构设计
   - Warden 集成方式
   - API 认证策略设计

2. **Cursor 规则**：`.cursor/rules/authentication.mdc`
   - 开发认证功能时的参考文件索引
   - 代码规范和最佳实践

3. **Rails Security Guide**：https://guides.rubyonrails.org/security.html#authentication
   - Rails 8 Authentication Generator 使用方法
   - 安全最佳实践

#### 下一步计划

完成第一步后，继续实现：

- 密码找回功能
- 邮箱确认功能
- 用户资料完善
- 用户头像上传

