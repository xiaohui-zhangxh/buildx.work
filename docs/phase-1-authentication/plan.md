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
- `email` (string, unique, not null) - 邮箱地址
- `password_digest` (string, not null) - 加密后的密码
- `confirmed_at` (datetime) - 邮箱确认时间
- `confirmation_token` (string) - 邮箱确认令牌
- `confirmation_sent_at` (datetime) - 确认邮件发送时间
- `reset_password_token` (string) - 密码重置令牌
- `reset_password_sent_at` (datetime) - 密码重置邮件发送时间
- `timestamps` (created_at, updated_at)

**需要手动添加的字段**（在迁移中添加）：
- `name` (string) - 用户姓名
- `failed_login_attempts` (integer, default: 0) - 登录失败次数
- `locked_at` (datetime) - 账户锁定时间
- `remember_token` (string) - 记住我令牌
- `remember_created_at` (datetime) - 记住我创建时间

##### 3. User 模型
**注意**：Rails 8 Authentication Generator 会自动生成 User 模型，包含：
- `has_secure_password` - 密码加密
- 邮箱格式和唯一性验证
- 邮箱确认相关方法
- 密码重置相关方法

**需要手动添加的功能**：
- [ ] 添加账户锁定相关方法（`failed_login_attempts`、`locked_at`）
- [ ] 添加记住我相关方法（`remember_token`、`remember_created_at`）
- [ ] 添加 `name` 字段的验证

##### 4. 路由设计
**注意**：Rails 8 Authentication Generator 会自动生成认证相关的路由。

**生成的路由**（参考 generator 输出）：
- 注册相关路由
- 登录相关路由
- 密码重置路由

**需要手动添加的路由**：
```ruby
# 用户管理（需要登录）
resources :users, only: [:index, :show, :edit, :update]
```

##### 5. 控制器实现

**AuthenticationController**（Rails generator 自动生成）
- [ ] 查看生成的控制器代码
- [ ] 根据需求进行自定义

**UsersController**（需要手动创建）
- [ ] `index` - 用户列表（需要认证）
- [ ] `show` - 用户详情（需要认证）
- [ ] `edit` - 编辑用户信息（需要认证）
- [ ] `update` - 更新用户信息（需要认证）

**ApplicationController**
- [ ] 集成 Warden
- [ ] 添加 `current_user` 方法（通过 Warden 实现）
- [ ] 添加 `user_signed_in?` 方法（通过 Warden 实现）
- [ ] 添加 `authenticate_user!` before_action
- [ ] 添加 `require_no_authentication` before_action（已登录用户不能访问登录/注册页）

**Warden 配置**
- [ ] 创建 `config/initializers/warden.rb`
- [ ] 配置 Warden 中间件
- [ ] 注册 Password Strategy
- [ ] 配置身份获取方式

##### 6. 视图实现

**注册页面** (`app/views/users/new.html.erb`)
- [ ] 使用 DaisyUI 组件设计注册表单
- [ ] 邮箱输入框
- [ ] 密码输入框
- [ ] 密码确认输入框
- [ ] 姓名输入框（可选）
- [ ] 提交按钮
- [ ] 错误提示显示

**登录页面** (`app/views/sessions/new.html.erb`)
- [ ] 使用 DaisyUI 组件设计登录表单
- [ ] 邮箱输入框
- [ ] 密码输入框
- [ ] "记住我"复选框
- [ ] 提交按钮
- [ ] "忘记密码"链接（后续实现）
- [ ] 错误提示显示

**用户列表** (`app/views/users/index.html.erb`)
- [ ] 使用 DaisyUI 表格组件
- [ ] 显示用户列表
- [ ] 搜索功能（可选）
- [ ] 分页功能（可选）

**用户详情** (`app/views/users/show.html.erb`)
- [ ] 显示用户基本信息
- [ ] 编辑按钮

**用户编辑** (`app/views/users/edit.html.erb`)
- [ ] 编辑表单
- [ ] 更新按钮

##### 7. 邮件功能

**UserMailer**
- [ ] `confirmation_instructions` - 邮箱确认邮件
- [ ] `password_reset` - 密码重置邮件（后续实现）

邮件模板：
- [ ] HTML 模板（使用 DaisyUI 样式）
- [ ] 文本模板

##### 8. 安全功能

- [ ] 密码强度验证（至少 8 位，包含字母和数字）
- [ ] 登录失败次数限制（5 次失败后锁定账户）
- [ ] 账户锁定机制（锁定 30 分钟后自动解锁）
- [ ] CSRF 保护（Rails 默认已启用）
- [ ] 密码加密（使用 bcrypt）

##### 9. 测试

**模型测试** (`test/models/user_test.rb`)
- [ ] 邮箱格式验证测试
- [ ] 邮箱唯一性测试
- [ ] 密码加密测试
- [ ] 邮箱确认测试

**控制器测试** (`test/controllers/users_controller_test.rb`)
- [ ] 注册功能测试
- [ ] 用户列表测试（需要认证）
- [ ] 用户编辑测试（需要认证）

**控制器测试** (`test/controllers/sessions_controller_test.rb`)
- [ ] 登录功能测试
- [ ] 登出功能测试
- [ ] 登录失败测试
- [ ] 账户锁定测试

**系统测试** (`test/system/users_test.rb`)
- [ ] 注册流程测试
- [ ] 登录流程测试
- [ ] 登出流程测试

##### 10. 文档更新

- [ ] 更新 README.md，标记已完成的功能
- [ ] 添加使用说明
- [ ] 添加开发指南

#### 开发顺序建议

1. **第一步**：安装依赖和创建 User 模型
   - 启用 bcrypt
   - 创建数据库迁移
   - 创建 User 模型和基础验证

2. **第二步**：实现注册功能
   - UsersController
   - 注册视图
   - 基础测试

3. **第三步**：实现登录功能
   - SessionsController
   - 登录视图
   - 会话管理
   - 基础测试

4. **第四步**：实现用户管理
   - 用户列表和详情
   - 用户编辑
   - 权限控制

5. **第五步**：完善安全功能
   - 登录失败限制
   - 账户锁定
   - 密码强度验证

6. **第六步**：邮件功能
   - UserMailer
   - 邮件模板
   - 邮箱确认流程

7. **第七步**：测试和优化
   - 完善测试用例
   - 代码优化
   - 文档更新

#### 技术要点

1. **Rails 8 Authentication Generator**：
   - 使用 `bin/rails generate authentication` 生成基础认证代码
   - 参考 [Rails Security Guide](https://guides.rubyonrails.org/security.html#authentication)
   - Generator 会自动生成模型、控制器、视图和路由

2. **Warden 身份管理**：
   - 使用 Warden 统一管理用户身份
   - 通过 Warden 策略模式支持多种认证方式
   - 为未来扩展 API 认证（Token、JWT）做准备
   - 参考 `docs/DEVELOPER_GUIDE.md` 了解架构设计

3. **密码加密**：使用 Rails 的 `has_secure_password`，自动使用 bcrypt

4. **会话管理**：通过 Warden 管理，支持多种存储方式

5. **记住我功能**：使用 `cookies` 存储加密的令牌

6. **邮件发送**：开发环境使用 `letter_opener`，生产环境配置 SMTP

7. **安全考虑**：
   - 密码不存储在数据库中，只存储加密后的 digest
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

