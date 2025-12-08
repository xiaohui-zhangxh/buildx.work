---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、多租户、Account、SaaS、数据隔离
description: 总结从 Basecamp Fizzy 项目学习到的 SaaS 多租户 Account 设计模式，包括 Account 模型、外部 ID、Slug、JoinCode、Current 对象管理等
---

# Fizzy SaaS 多租户 Account 设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的 SaaS 多租户 Account 设计模式。Account 作为租户账号，实现了数据隔离和组织管理。

**重要**：Fizzy 最初使用 `Organization` 作为租户实体，后来改为 `Account`。这个决策体现了多租户设计的演进过程。

## 核心设计

### 1. Account 模型

```ruby
class Account < ApplicationRecord
  include Entropic, Seedeable

  has_one :join_code
  has_many :users, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :cards, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :columns, dependent: :destroy
  has_many :exports, class_name: "Account::Export", dependent: :destroy

  has_many_attached :uploads

  before_create :assign_external_account_id
  after_create :create_join_code

  validates :name, presence: true

  class << self
    def create_with_owner(account:, owner:)
      create!(**account).tap do |account|
        account.users.create!(role: :system, name: "System")
        account.users.create!(**owner.reverse_merge(role: "owner", verified_at: Time.current))
      end
    end
  end

  def slug
    "/#{AccountSlug.encode(external_account_id)}"
  end

  def account
    self
  end

  def system_user
    users.find_by!(role: :system)
  end

  private
    def assign_external_account_id
      self.external_account_id ||= ExternalIdSequence.next
    end
end
```

### 2. 关键设计点

#### 2.1 外部 ID（External Account ID）

**使用外部 ID 而不是数据库主键：**

```ruby
before_create :assign_external_account_id

def assign_external_account_id
  self.external_account_id ||= ExternalIdSequence.next
end
```

**好处**：
- 隐藏内部数据库 ID
- 可以使用更友好的 URL（如 `/account-slug`）
- 安全性更好

#### 2.2 Slug 生成

**使用 Slug 作为 URL 标识：**

```ruby
def slug
  "/#{AccountSlug.encode(external_account_id)}"
end
```

**用途**：
- 生成友好的 URL
- 在路由中使用（如 `/account-slug/boards`）
- 多租户 URL 前缀

#### 2.3 系统用户

**每个 Account 都有一个系统用户：**

```ruby
def system_user
  users.find_by!(role: :system)
end
```

**用途**：
- 系统自动操作（如系统评论）
- 审核日志记录
- 自动化任务

#### 2.4 创建 Account 和 Owner

**使用工厂方法创建 Account 和 Owner：**

```ruby
class << self
  def create_with_owner(account:, owner:)
    create!(**account).tap do |account|
      account.users.create!(role: :system, name: "System")
      account.users.create!(**owner.reverse_merge(role: "owner", verified_at: Time.current))
    end
  end
end
```

**好处**：
- 原子性操作（Account + System User + Owner）
- 简化创建流程
- 确保数据一致性

### 3. 数据隔离

#### 3.1 所有模型关联到 Account

**所有主要模型都关联到 Account：**

```ruby
# Board
belongs_to :account

# Card
belongs_to :account, default: -> { board.account }

# User
belongs_to :account

# Comment
belongs_to :account, default: -> { card.account }

# Event
belongs_to :account, default: -> { board.account }
```

#### 3.2 使用 Current.account

**通过 Current 对象管理当前租户：**

```ruby
# ApplicationController
include CurrentRequest, CurrentTimezone, SetPlatform

# 在 Action Cable 中
def set_current_user
  if session = find_session_by_cookie
    account = Account.find_by(external_account_id: request.env["fizzy.external_account_id"])
    Current.account = account
    self.current_user = session.identity.users.find_by!(account: account) if account
  end
end
```

#### 3.3 查询时自动过滤

**在查询时自动过滤 Account：**

```ruby
# 在模型中
scope :for_account, ->(account) { where(account: account) }

# 在控制器中
def set_board
  @board = Current.user.boards.find params[:id]
end
```

### 4. URL 路由设计

#### 4.1 使用 script_name

**在路由中使用 script_name 作为 Account 标识：**

```ruby
# config/routes.rb
# 通过 script_name 识别 Account

# ApplicationMailer
def default_url_options
  if Current.account
    super.merge(script_name: Current.account.slug)
  else
    super
  end
end
```

#### 4.2 多租户 URL 结构

**URL 结构：`/account-slug/resource`**

```
/account-slug/boards
/account-slug/cards/123
/account-slug/users
```

### 5. Join Code 设计

#### 5.1 Join Code 关联

**每个 Account 有一个 Join Code：**

```ruby
has_one :join_code

after_create :create_join_code
```

**用途**：
- 邀请用户加入 Account
- 通过代码加入（如 `/join/ABC123`）
- 简化用户加入流程

### 6. 应用到 BuildX

#### 6.1 建议采用的实践

1. **外部 ID**：使用 `external_account_id` 而不是数据库主键
2. **Slug**：使用 Slug 作为 URL 标识
3. **系统用户**：每个 Account 创建一个系统用户
4. **工厂方法**：使用 `create_with_owner` 创建 Account
5. **数据隔离**：所有模型关联到 Account
6. **Current 对象**：使用 `Current.account` 管理当前租户
7. **URL 路由**：使用 `script_name` 作为 Account 标识

#### 6.2 实现步骤

1. **创建 Account 模型**
   - 添加 `external_account_id` 字段
   - 实现 `slug` 方法
   - 创建系统用户

2. **更新所有模型**
   - 添加 `belongs_to :account`
   - 设置默认值（如 `default: -> { parent.account }`）

3. **实现 Current 对象**
   - 创建 `Current` 模块
   - 在控制器中设置 `Current.account`
   - 在 Action Cable 中设置 `Current.account`

4. **更新路由**
   - 使用 `script_name` 识别 Account
   - 更新邮件 URL 生成

5. **实现 Join Code**
   - 创建 `JoinCode` 模型
   - 实现加入流程

## 参考资料

- [Fizzy Account 模型](https://github.com/basecamp/fizzy/blob/main/app/models/account.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 从 Organization 到 Account 的演进

### 从 Commit 683338fb 学到的经验

**时间**：2024-08-13  
**作者**：Jeffrey Hardy  
**变更文件**：
- `app/models/account.rb`（新建）
- `app/models/organization.rb`（删除）
- `db/migrate/20240813200622_rename_organizations_to_accounts.rb`

**重要决策**：Fizzy 团队从 `Organization` 改为 `Account` 作为顶级租户实体。

**迁移过程**：

```ruby
class RenameOrganizationsToAccounts < ActiveRecord::Migration[8.0]
  def change
    rename_table :organizations, :accounts
    add_index :accounts, :name, unique: true

    rename_column :users, :organization_id, :account_id
    add_index :users, :account_id
  end
end
```

**关键点**：
- 使用数据库迁移重命名表和列
- 更新了所有相关的模型、视图和测试
- 在 Current 对象中从 `organization` 改为 `account`
- 保持了数据完整性（使用 `rename_table` 和 `rename_column`）

**为什么改为 Account**：
- `Account` 更符合 SaaS 业务的术语
- 更清晰地表达"账户"的概念
- 与行业标准术语一致

**学习要点**：
- 架构决策可以演进，重要的是如何平滑迁移
- 使用数据库迁移确保数据完整性
- 更新所有相关代码（模型、视图、测试、fixtures）

### 3. 多租户数据作用域

#### 3.1 按租户作用域关联数据

**使用 `through` 关联实现多租户数据作用域：**

```ruby
# app/models/bucket.rb
class Bucket < ApplicationRecord
  has_many :bubbles, dependent: :destroy
  has_many :tags, -> { distinct }, through: :bubbles
end
```

**在视图中使用作用域后的数据：**

```erb
<!-- ❌ Old（使用全局作用域） -->
<% Current.account.tags.order(:title).each do |tag| %>
  <!-- ... -->
<% end %>

<!-- ✅ New（使用 bucket 作用域） -->
<% bucket.tags.order(:title).each do |tag| %>
  <!-- ... -->
<% end %>
```

**关键点**：
- 使用 `has_many :tags, through: :bubbles` 实现多租户数据作用域
- 使用 `-> { distinct }` 去重
- 在视图中使用 `bucket.tags` 而不是 `Current.account.tags`
- 体现了多租户数据隔离的最佳实践

**从 Commit d38bab96 学到的经验**：

**时间**：2024-10-07  
**作者**：Jeffrey Hardy  
**变更文件**：
- `app/models/bucket.rb`
- `app/views/bubbles/_filters.html.erb`

Fizzy 团队将 tags 按 bucket 作用域，而不是使用全局的 `Current.account.tags`。这体现了：
- 多租户数据隔离的重要性
- 使用 `through` 关联实现数据作用域
- 在视图中使用作用域后的数据，而不是全局数据

#### 3.2 访问控制批量更新

**使用 `revise` 方法批量更新访问权限：**

```ruby
# app/models/bucket/accessible.rb
module Bucket::Accessible
  extend ActiveSupport::Concern

  included do
    has_many :accesses, dependent: :delete_all do
      def revise(granted: [], revoked: [])
        transaction do
          grant_to granted
          revoke_from revoked
        end
      end

      private
        def grant_to(users)
          Access.insert_all Array(users).collect { |user| 
            { bucket_id: proxy_association.owner.id, user_id: user.id } 
          }
        end

        def revoke_from(users)
          destroy_by user: users
        end
    end

    has_many :users, through: :accesses

    after_create -> { accesses.grant_to(creator) }
  end
end

# app/controllers/buckets_controller.rb
def update
  @bucket.transaction do
    @bucket.update! bucket_params
    @bucket.accesses.revise granted: grantees, revoked: revokees
  end
  redirect_to bucket_bubbles_url(@bucket)
end
```

**关键点**：
- 使用关联扩展（association extension）定义 `revise` 方法
- 使用 `Access.insert_all` 批量插入访问记录
- 使用 `destroy_by` 批量删除访问记录
- 使用事务确保数据一致性
- 体现了批量操作和性能优化的最佳实践

**从 Commit dd1752de 学到的经验**：

**时间**：2024-10-09  
**作者**：Jose Farias  
**变更文件**：
- `app/models/bucket/accessible.rb`
- `app/controllers/buckets_controller.rb`

Fizzy 团队实现了访问控制的批量更新功能。这体现了：
- 使用关联扩展组织批量操作逻辑
- 使用 `insert_all` 提高批量插入性能
- 使用事务确保数据一致性
- 清晰的 API 设计（`revise(granted:, revoked:)`）

### 5. 通知系统设计

#### 5.1 使用 Watches 跟踪通知偏好

**使用 Watches 模型跟踪用户对 bubble 的通知偏好：**

```ruby
# app/models/watch.rb
class Watch < ApplicationRecord
  belongs_to :user
  belongs_to :bubble
end

# app/models/bubble/watchable.rb
module Bubble::Watchable
  extend ActiveSupport::Concern

  included do
    has_many :watches, dependent: :destroy
    has_many :watchers, through: :watches, source: :user

    after_create :create_initial_watches
  end

  private
    def create_initial_watches
      Watch.insert_all(bucket.users.pluck(:id).collect { |user_id| { user_id: user_id, bubble_id: id } })
    end
end

# app/models/bubble.rb
class Bubble < ApplicationRecord
  include Watchable
  # ...
end

# app/models/notifier.rb
class Notifier
  def recipients
    bubble.watchers.without(creator)
  end
end
```

**数据库迁移：**

```ruby
class CreateWatches < ActiveRecord::Migration[8.1]
  def change
    create_table :watches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bubble, null: false, foreign_key: true
      t.boolean :watching, null: false, default: true

      t.timestamps
    end
  end
end
```

**关键点**：
- 使用 `Watch` 模型跟踪用户对 bubble 的通知偏好
- 使用 `Bubble::Watchable` Concern 组织相关逻辑
- 使用 `after_create :create_initial_watches` 自动创建初始 watches
- 使用 `Watch.insert_all` 批量创建 watches
- 通知系统使用 `bubble.watchers` 而不是 `bubble.bucket.users`
- 支持用户自定义通知偏好（watching 字段）
- 体现了通知系统设计和批量操作的最佳实践

**从 Commit 59144ad1 学到的经验**：

**时间**：2025-02-24  
**作者**：Kevin McConnell  
**变更文件**：
- `app/models/watch.rb`（新建）
- `app/models/bubble/watchable.rb`（新建）
- `db/migrate/20250224111311_create_watches.rb`（新建）

Fizzy 团队使用 Watches 跟踪通知偏好。这体现了：
- 通知系统设计的最佳实践
- 使用 Concern 组织相关逻辑
- 使用批量操作提高性能
- 支持用户自定义通知偏好

### 4.5 多租户身份管理：Identity 模型

**引入 Identity 模型简化跨租户登录：**

```ruby
# app/models/untenanted_record.rb
class UntenantedRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :untenanted }
end

# app/models/identity.rb
class Identity < UntenantedRecord
  # Mock 对象用于缓存和 etag，避免数据库读取
  Mock = Struct.new(:id, :updated_at)

  has_many :memberships, dependent: :destroy
end

# app/models/membership.rb
class Membership < UntenantedRecord
  belongs_to :identity, touch: true

  # 跨租户关联 User
  def user
    User.with_tenant(user_tenant) { User.find_by(id: user_id) }
  end
end

# app/models/user/identifiable.rb
module User::Identifiable
  extend ActiveSupport::Concern

  included do
    has_one :membership, ->(user) { where(user_tenant: user.tenant) }
    has_one :identity, through: :membership
  end
end
```

**使用 `identity_token` cookie 跨租户保持状态：**

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  def link_identity(user)
    token_value = cookies.signed[:identity_token]
    token_identity = Identity.find_signed(token_value["id"]) if token_value.present?
    identity = user.set_identity(token_identity)
    cookies.signed.permanent[:identity_token] = { 
      value: { "id" => identity.signed_id, "updated_at" => identity.updated_at }, 
      httponly: true, 
      same_site: :lax,
      path: "/"  # 跨租户路径
    }
  end

  def set_current_identity_token
    Current.identity_token = Identity::Mock.new(**cookies.signed[:identity_token])
  end
end
```

**关键点**：
- 创建 `UntenantedRecord` 基类，连接到 untenanted 数据库
- 使用 `identity_token` cookie（path "/"）跨租户保持状态
- 使用 `Identity::Mock` 对象避免数据库读取，用于缓存和 etag
- 在 cookie 中跟踪 `signed_id` 和 `updated_at`，实现有效的缓存
- 创建 `Membership` 模型连接 Identity 和 User
- 使用 `User::Identifiable` Concern 管理身份关联
- 体现了多租户身份管理和跨租户状态保持的最佳实践

**从 Commit 3399e451 学到的经验**：

**时间**：2025-10-09  
**作者**：Mike Dalessio  
**变更文件**：
- 创建了 `Identity` 和 `Membership` 模型
- 创建了 `UntenantedRecord` 基类
- 引入了 `identity_token` cookie
- 创建了 `User::Identifiable` Concern

Fizzy 团队引入 Identity 模型简化跨租户登录。这体现了：
- 多租户身份管理的最佳实践
- 跨租户状态保持的设计
- 使用 Mock 对象优化缓存和 etag
- 使用 untenanted 数据库存储跨租户数据

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-08

