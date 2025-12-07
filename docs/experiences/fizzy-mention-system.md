---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、提及系统、Mention、多态关联、Action Text
description: 总结从 Basecamp Fizzy 项目学习到的提及（Mention）系统设计，包括 Mention 模型、Mentions Concern、从 Action Text 提取提及等
---

# Fizzy 提及（Mention）系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的提及（Mention）系统设计。提及系统允许用户在评论或其他内容中@其他用户，并自动通知被提及的用户。

## 核心设计

### 1. Mention 模型

```ruby
class Mention < ApplicationRecord
  include Notifiable

  belongs_to :account, default: -> { source.account }
  belongs_to :source, polymorphic: true
  belongs_to :mentioner, class_name: "User"
  belongs_to :mentionee, class_name: "User", inverse_of: :mentions

  after_create_commit :watch_source_by_mentionee

  delegate :card, to: :source

  def self_mention?
    mentioner == mentionee
  end

  def notifiable_target
    source
  end

  private
    def watch_source_by_mentionee
      source.watch_by(mentionee)
    end
end
```

### 2. Mentions Concern

**使用 Concern 让模型支持提及：**

```ruby
module Mentions
  extend ActiveSupport::Concern

  included do
    has_many :mentions, as: :source, dependent: :destroy
    has_many :mentionees, through: :mentions
    after_save_commit :create_mentions_later, if: :should_create_mentions?
  end

  def create_mentions(mentioner: Current.user)
    scan_mentionees.each do |mentionee|
      mentionee.mentioned_by mentioner, at: self
    end
  end

  def mentionable_content
    rich_text_associations.collect { send(it.name)&.to_plain_text }.compact.join(" ")
  end

  private
    def scan_mentionees
      mentionees_from_attachments & mentionable_users
    end

    def mentionees_from_attachments
      rich_text_associations.flat_map { 
        send(it.name)&.body&.attachments&.collect { it.attachable } 
      }.compact
    end

    def mentionable_users
      board.users
    end

    def rich_text_associations
      self.class.reflect_on_all_associations(:has_one).filter { 
        it.klass == ActionText::RichText 
      }
    end

    def should_create_mentions?
      mentionable? && (mentionable_content_changed? || should_check_mentions?)
    end

    def mentionable_content_changed?
      rich_text_associations.any? { send(it.name)&.body_previously_changed? }
    end

    def create_mentions_later
      Mention::CreateJob.perform_later(self, mentioner: Current.user)
    end

    # Template method
    def mentionable?
      true
    end

    def should_check_mentions?
      false
    end
end
```

### 3. 关键设计点

#### 3.1 多态关联

**Mention 通过多态关联支持多种来源：**

```ruby
belongs_to :source, polymorphic: true
```

**支持的类型**：
- Comment
- Card（描述）
- 其他富文本内容

#### 3.2 从附件中提取提及

**从 Action Text 的附件中提取用户提及：**

```ruby
def mentionees_from_attachments
  rich_text_associations.flat_map { 
    send(it.name)&.body&.attachments&.collect { it.attachable } 
  }.compact
end
```

**工作原理**：
- Action Text 支持在富文本中嵌入用户对象
- 用户对象作为附件存储在富文本中
- 从附件中提取用户对象作为被提及的用户

#### 3.3 可提及用户范围

**限制可提及的用户范围：**

```ruby
def mentionable_users
  board.users
end
```

**好处**：
- 只允许提及同一 Board 的用户
- 提高安全性
- 减少无关通知

#### 3.4 自动关注

**被提及的用户自动关注来源：**

```ruby
after_create_commit :watch_source_by_mentionee

private
  def watch_source_by_mentionee
    source.watch_by(mentionee)
  end
end
```

**好处**：
- 被提及的用户会自动收到后续更新
- 提高用户参与度
- 简化关注流程

#### 3.5 异步处理

**使用后台任务异步创建提及：**

```ruby
def create_mentions_later
  Mention::CreateJob.perform_later(self, mentioner: Current.user)
end
```

**好处**：
- 不阻塞请求
- 提高响应速度
- 支持重试

#### 3.6 条件检查

**只在内容变更时检查提及：**

```ruby
def should_create_mentions?
  mentionable? && (mentionable_content_changed? || should_check_mentions?)
end

def mentionable_content_changed?
  rich_text_associations.any? { send(it.name)&.body_previously_changed? }
end
```

**好处**：
- 避免不必要的处理
- 提高性能
- 只在需要时创建提及

### 4. 用户模型集成

**在 User 模型中添加提及方法：**

```ruby
class User < ApplicationRecord
  has_many :mentions, foreign_key: :mentionee_id, inverse_of: :mentionee

  def mentioned_by(mentioner, at:)
    mentions.create!(mentioner: mentioner, source: at, account: at.account)
  end
end
```

### 5. 通知集成

**Mention 实现 Notifiable：**

```ruby
class Mention < ApplicationRecord
  include Notifiable

  def notifiable_target
    source
  end
end
```

**好处**：
- 自动发送通知给被提及的用户
- 统一的通知机制
- 支持多种通知方式

### 6. 使用示例

#### 6.1 在 Comment 中使用

```ruby
class Comment < ApplicationRecord
  include Mentions

  has_rich_text :body
end
```

**用户操作**：
1. 用户在评论中输入 `@username`
2. Action Text 将用户对象嵌入为附件
3. 保存时触发 `create_mentions_later`
4. 后台任务提取附件中的用户
5. 创建 Mention 记录
6. 发送通知给被提及的用户

#### 6.2 在 Card 中使用

```ruby
class Card < ApplicationRecord
  include Mentions

  has_rich_text :description
end
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **多态关联**：使用 `polymorphic: true` 支持多种来源
2. **从附件提取**：从 Action Text 附件中提取用户提及
3. **范围限制**：限制可提及的用户范围
4. **自动关注**：被提及的用户自动关注来源
5. **异步处理**：使用后台任务异步创建提及
6. **条件检查**：只在内容变更时检查提及

#### 7.2 实现步骤

1. **创建 Mention 模型**
   - 添加多态关联 `source`
   - 添加关联（mentioner, mentionee, account）

2. **创建 Mentions Concern**
   - 实现 `create_mentions` 方法
   - 实现附件提取逻辑
   - 实现条件检查

3. **在模型中集成**
   - 包含 `Mentions` Concern
   - 添加 `has_rich_text` 关联
   - 实现 `mentionable_users` 方法

4. **实现后台任务**
   - 创建 `Mention::CreateJob`
   - 实现异步处理逻辑

5. **集成通知系统**
   - 实现 `Notifiable`
   - 配置通知规则

6. **前端集成**
   - 实现 @ 用户选择器
   - 集成 Action Text
   - 实现实时预览

## 参考资料

- [Fizzy Mention 模型](https://github.com/basecamp/fizzy/blob/main/app/models/mention.rb)
- [Fizzy Mentions Concern](https://github.com/basecamp/fizzy/blob/main/app/models/concerns/mentions.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

