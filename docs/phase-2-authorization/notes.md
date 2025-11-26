# 第二阶段开发笔记

## 📝 开发过程中的问题和解决方案

待第一阶段完成后开始记录。

## 💡 技术决策记录

### 权限策略框架选择：Action Policy ⭐

**决策**：使用 [Action Policy](https://github.com/palkan/action_policy) Gem 作为权限策略框架。

**原因**：

1. **成熟稳定**：由知名 Rails 开发者维护，在 Rails 社区广泛使用
2. **高性能**：通过缓存和优化，确保授权检查的高效执行
3. **灵活可测试**：使用 Policy 类定义权限规则，易于测试和维护
4. **Rails 友好**：与 Rails 深度集成，提供控制器和视图辅助方法
5. **可扩展**：支持复杂的权限逻辑，适应各种应用需求

**与阿里云 RAM 的对比**：
**Effect**：Allow 或 Deny
     - **Action**：允许或拒绝的操作（如 `ecs:DescribeInstances`）
     - **Resource**：资源范围（如 `acs:ecs:cn-hangzhou:*:*`）
   - 示例：
     ```json
     {
       "Version": "1",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": ["ecs:DescribeInstances", "ecs:DescribeImages"],
           "Resource": "acs:ecs:cn-hangzhou:*:*"
         }
       ]
     }
     ```

4. **用户组（UserGroup）**
   - 用于批量管理用户权限
   - 用户组可以附加权限策略
   - 用户加入用户组后自动继承组权限

5. **角色扮演（AssumeRole）**
   - 临时凭证机制
   - 通过 STS（Security Token Service）获取临时 AccessKey
   - 临时凭证有过期时间，提高安全性

#### 阿里云 RAM 的设计优势

1. **最小权限原则**：精确控制每个用户/角色的权限范围
2. **临时凭证**：优先使用临时凭证，降低长期凭证泄露风险
3. **策略分离**：权限策略独立于用户和角色，可复用
4. **精细化控制**：支持资源级权限控制（如只能操作特定实例）
5. **可扩展性**：支持自定义策略，灵活应对复杂场景

#### 对我们项目的启发

**适合借鉴的设计**：

1. **权限策略（Policy）模型**
   - 将权限定义为 JSON 格式的策略
   - 支持 Action、Resource、Effect 三个维度
   - 策略可以附加到角色，也可以直接附加到用户

2. **用户组概念**
   - 引入用户组（UserGroup）模型
   - 用户组可以附加权限策略
   - 用户可以通过加入用户组批量获得权限

3. **权限策略格式**
   - 使用结构化的权限定义
   - 支持资源级权限控制
   - 便于权限的查询和管理

**需要简化的部分**：

1. **角色扮演机制**
   - 阿里云的角色扮演主要用于跨账号和临时凭证
   - 我们的项目暂时不需要，可以后续扩展

2. **临时凭证（STS）**
   - 主要用于 API 访问场景
   - 我们可以在第四阶段的 API 支持中实现

#### 建议的权限系统设计

基于阿里云 RAM 的设计思路，结合我们项目的实际情况，建议采用以下设计：

##### 1. 数据模型设计

```ruby
# Role 模型
class Role
  # name, description, timestamps
  has_many :role_policies
  has_many :policies, through: :role_policies
  has_many :user_roles
  has_many :users, through: :user_roles
end

# Policy 模型（权限策略）
class Policy
  # name, description, policy_json (JSON字段存储策略定义)
  # policy_json 格式：
  # {
  #   "version": "1",
  #   "statements": [
  #     {
  #       "effect": "allow",
  #       "actions": ["users:read", "users:write"],
  #       "resources": ["users:*"]
  #     }
  #   ]
  # }
  has_many :role_policies
  has_many :roles, through: :role_policies
  has_many :user_policies
  has_many :users, through: :user_policies
end

# UserGroup 模型（用户组）
class UserGroup
  # name, description, timestamps
  has_many :user_group_members
  has_many :users, through: :user_group_members
  has_many :group_policies
  has_many :policies, through: :group_policies
end

# User 模型扩展
class User
  has_many :user_roles
  has_many :roles, through: :user_roles
  has_many :user_policies  # 直接附加的策略
  has_many :policies, through: :user_policies
  has_many :user_group_members
  has_many :user_groups, through: :user_group_members
end
```

##### 2. 权限检查逻辑

用户的有效权限 = 用户直接附加的策略 + 用户角色的策略 + 用户组的策略

```ruby
class User
  def effective_policies
    # 合并所有来源的策略
    (policies + roles.flat_map(&:policies) + user_groups.flat_map(&:policies)).uniq
  end

  def can?(action, resource = nil)
    effective_policies.any? do |policy|
      policy.allows?(action, resource)
    end
  end
end

class Policy
  def allows?(action, resource = nil)
    statements.any? do |statement|
      statement['effect'] == 'allow' &&
        statement['actions'].include?(action) &&
        (resource.nil? || matches_resource?(statement['resources'], resource))
    end
  end

  private

  def matches_resource?(resource_patterns, resource)
    resource_patterns.any? do |pattern|
      # 支持通配符匹配，如 "users:*" 匹配 "users:123"
      pattern.gsub('*', '.*') =~ resource
    end
  end
end
```

##### 3. 权限定义规范

采用 `资源:操作` 的格式，如：

- `users:read` - 读取用户
- `users:write` - 创建/更新用户
- `users:delete` - 删除用户
- `roles:manage` - 管理角色
- `admin:*` - 管理后台所有权限

##### 4. 实现优先级

1. **第一阶段**：基础 RBAC（Role + Policy，用户通过角色获得权限）
2. **第二阶段**：用户组支持（批量权限管理）
3. **第三阶段**：资源级权限（结合多租户）
4. **第四阶段**：临时凭证和角色扮演（API 场景）

## 🔗 相关文档

- [开发计划](./plan.md)
- [开发进度](./progress.md)
- [阶段概览](./README.md)
- [阿里云 RAM 文档](https://help.aliyun.com/product/28625.html)

