---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、后台任务
status: 已完成
tags: Fizzy、后台任务、ActiveJob、ActionMailer、多租户
description: 总结从 Basecamp Fizzy 项目学习到的后台任务和邮件系统设计模式，包括薄任务类设计、邮件配置、多租户 URL 处理等
---

# Fizzy 后台任务和邮件系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的后台任务（Jobs）和邮件系统（Mailers）设计模式。

## 1. 后台任务（Jobs）

### 1.1 设计原则

**薄任务类，将逻辑委托给领域模型：**

```ruby
class ApplicationJob < ActiveJob::Base
  # 自动重试遇到死锁的任务
  # retry_on ActiveRecord::Deadlocked

  # 如果底层记录不再可用，大多数任务可以安全地忽略
  # discard_on ActiveJob::DeserializationError
end
```

**关键原则**：
- 任务类保持简洁
- 业务逻辑在模型中实现
- 使用命名空间组织任务

### 1.2 任务示例

#### 推送通知任务

```ruby
class PushNotificationJob < ApplicationJob
  def perform(notification)
    NotificationPusher.new(notification).push
  end
end
```

#### 提及创建任务

```ruby
class Mention::CreateJob < ApplicationJob
  def perform(record, mentioner:)
    record.create_mentions(mentioner:)
  end
end
```

#### 活动峰值检测任务

```ruby
class Card::ActivitySpike::DetectionJob < ApplicationJob
  def perform(card)
    card.detect_activity_spikes
  end
end
```

#### 删除未使用标签任务

```ruby
class DeleteUnusedTagsJob < ApplicationJob
  def perform
    Tag.left_joins(:taggings).where(taggings: { id: nil }).delete_all
  end
end
```

### 1.3 命名空间组织

**使用命名空间组织相关任务：**

```ruby
# Mention::CreateJob
# Card::ActivitySpike::DetectionJob
# Board::CleanInaccessibleDataJob
# Notification::Bundle::DeliverJob
```

**好处**：
- 逻辑分组
- 避免命名冲突
- 易于查找

### 1.4 错误处理

**配置错误处理策略：**

```ruby
class ApplicationJob < ActiveJob::Base
  # 自动重试遇到死锁的任务
  retry_on ActiveRecord::Deadlocked

  # 如果底层记录不再可用，大多数任务可以安全地忽略
  discard_on ActiveJob::DeserializationError
end
```

**策略**：
- `retry_on`：遇到特定错误时重试
- `discard_on`：遇到特定错误时丢弃任务

## 2. 邮件系统（Mailers）

### 2.1 Application Mailer

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "Fizzy <support@fizzy.do>")

  layout "mailer"
  append_view_path Rails.root.join("app/views/mailers")
  helper AvatarsHelper, HtmlHelper

  private
    def default_url_options
      if Current.account
        super.merge(script_name: Current.account.slug)
      else
        super
      end
    end
end
```

**关键点**：
- 使用环境变量配置发件人
- 自定义视图路径
- 共享辅助方法
- 多租户 URL 处理

### 2.2 邮件类示例

#### 魔法链接邮件

```ruby
class MagicLinkMailer < ApplicationMailer
  def sign_in_instructions(magic_link)
    @magic_link = magic_link
    @identity = @magic_link.identity

    mail to: @identity.email_address, subject: "Your Fizzy code is #{ @magic_link.code }"
  end
end
```

**关键点**：
- 使用实例变量传递数据到视图
- 使用关键字参数提高可读性
- 动态生成主题

#### 用户邮件

```ruby
class UserMailer < ApplicationMailer
  def email_change_confirmation(email_address:, token:, user:)
    @token = token
    @user = user
    mail to: email_address, subject: "Confirm your new email address"
  end
end
```

**关键点**：
- 使用关键字参数
- 清晰的参数命名
- 简洁的实现

### 2.3 多租户 URL 处理

**在邮件中处理多租户 URL：**

```ruby
def default_url_options
  if Current.account
    super.merge(script_name: Current.account.slug)
  else
    super
  end
end
```

**好处**：
- 自动生成正确的 URL
- 支持多租户
- 简化邮件模板

### 2.4 邮件预览

**查看邮件预览：**

访问 `http://fizzy.localhost:3006/rails/mailers` 查看所有邮件预览。

**启用/禁用 letter_opener：**

```bash
bin/rails dev:email
```

## 3. 应用到 BuildX

### 3.1 建议采用的实践

1. **薄任务类**：任务类保持简洁，逻辑在模型中
2. **命名空间**：使用命名空间组织任务
3. **错误处理**：配置 `retry_on` 和 `discard_on`
4. **关键字参数**：使用关键字参数提高可读性
5. **多租户 URL**：使用 `default_url_options` 处理多租户
6. **辅助方法**：在 ApplicationMailer 中共享辅助方法

### 3.2 实现步骤

1. **创建 Application Job**
   - 配置错误处理策略
   - 设置默认行为

2. **实现任务类**
   - 保持任务类简洁
   - 将逻辑委托给模型
   - 使用命名空间组织

3. **创建 Application Mailer**
   - 配置默认发件人
   - 设置视图路径
   - 实现多租户 URL 处理

4. **实现邮件类**
   - 使用关键字参数
   - 创建邮件模板
   - 实现邮件预览

## 参考资料

- [Fizzy ApplicationJob](https://github.com/basecamp/fizzy/blob/main/app/jobs/application_job.rb)
- [Fizzy ApplicationMailer](https://github.com/basecamp/fizzy/blob/main/app/mailers/application_mailer.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

