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

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

