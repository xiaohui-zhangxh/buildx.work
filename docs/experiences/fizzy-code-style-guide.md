---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、代码风格
status: 已完成
tags: Fizzy、代码风格、Code Style、最佳实践
description: 总结从 Basecamp Fizzy 项目学习到的代码风格规范，包括条件返回、方法排序、可见性修饰符、CRUD 控制器设计等
---

# Fizzy 代码风格指南

## 概述

本文档总结了从 Basecamp Fizzy 项目的 [STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md) 学习到的代码风格规范。这些规范体现了 Basecamp 对代码可读性和维护性的重视。

## 核心原则

Basecamp 的代码风格指南强调：
- **代码应该是一种享受阅读的体验**
- **对代码质量设置高标准**
- **关注代码如何阅读、如何看起来、如何让你感觉**

## 1. 条件返回

### 1.1 偏好展开的条件语句

**Basecamp 偏好展开的条件语句，而不是 guard clauses：**

```ruby
# ❌ Bad (Guard Clause)
def todos_for_new_group
  ids = params.require(:todolist)[:todo_ids]
  return [] unless ids
  @bucket.recordings.todos.find(ids.split(","))
end

# ✅ Good (展开的条件)
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end
```

**原因**：Guard clauses 可能难以阅读，特别是当它们嵌套时。

### 1.2 例外情况

**在方法开头使用 guard clause 提前返回是可以的**，特别是当主方法体比较复杂时：

```ruby
def after_recorded_as_commit(recording)
  return if recording.parent.was_created?

  if recording.was_created?
    broadcast_new_column(recording)
  else
    broadcast_column_change(recording)
  end
end
```

**适用场景**：
- 返回在方法开头
- 主方法体不是简单的，涉及多行代码

## 2. 方法排序

### 2.1 类中方法的排序

**方法在类中的排序：**

1. `class` 方法
2. `public` 方法（`initialize` 在最前面）
3. `private` 方法

### 2.2 调用顺序

**方法按调用顺序垂直排列**，帮助理解代码流程：

```ruby
class SomeClass
  def some_method
    method_1
    method_2
  end

  private
    def method_1
      method_1_1
      method_1_2
    end
  
    def method_1_1
      # ...
    end
  
    def method_1_2
      # ...
    end
  
    def method_2
      method_2_1
      method_2_2
    end
  
    def method_2_1
      # ...
    end
  
    def method_2_2
      # ...
    end
end
```

**好处**：
- 按照调用顺序阅读代码，更容易理解流程
- 相关的方法放在一起，提高可读性

## 3. 可见性修饰符

### 3.1 标准格式

**不使用换行符，内容缩进：**

```ruby
class SomeClass
  def some_method
    # ...
  end

  private
    def some_private_method_1
      # ...
    end

    def some_private_method_2
      # ...
    end
end
```

### 3.2 只有私有方法的模块

**如果模块只有私有方法，在顶部标记 `private`，后面加一个空行但不缩进：**

```ruby
module SomeModule
  private
  
  def some_private_method
    # ...
  end
end
```

## 4. CRUD 控制器

### 4.1 使用资源而不是自定义动作

**Basecamp 偏好使用资源而不是自定义动作：**

```ruby
# ❌ Bad
resources :cards do
  post :close
  post :reopen
end

# ✅ Good
resources :cards do
  resource :closure
end
```

**原因**：
- 更符合 RESTful 设计
- 路由更清晰
- 控制器动作更标准

## 5. 控制器和模型交互

### 5.1 Vanilla Rails 方式

**偏好 Vanilla Rails 方式：薄控制器 + 丰富的领域模型**

- 直接调用 Active Record 操作是可以的
- 对于复杂行为，使用清晰的、意图明确的模型 API
- 必要时可以使用服务或表单对象，但不把它们当作特殊工件

### 5.2 示例

**简单操作：**

```ruby
class Cards::CommentsController < ApplicationController
  def create
    @comment = @card.comments.create!(comment_params)
  end
end
```

**复杂行为：**

```ruby
class Cards::GoldnessesController < ApplicationController
  def create
    @card.gild
  end
end
```

**服务对象：**

```ruby
Signup.new(email_address: email_address).create_identity
```

**关键点**：
- 控制器保持简洁
- 业务逻辑在模型中
- 使用清晰的、意图明确的 API

## 6. 异步操作

### 6.1 命名约定

**使用 `_later` 后缀标记入队方法，使用 `_now` 后缀标记同步方法：**

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    # ...
  end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

**命名规则**：
- `_later`：入队异步任务的方法
- `_now`：同步执行的方法
- 任务类调用 `_now` 方法执行实际逻辑

### 6.2 任务类设计

**任务类保持简洁，将逻辑委托给领域模型：**

```ruby
class PushNotificationJob < ApplicationJob
  def perform(notification)
    NotificationPusher.new(notification).push
  end
end
```

## 7. To Bang or Not to Bang

### 7.1 使用规则

**作为一般规则，只在有对应的不带 `!` 的方法时才使用 `!`。**

特别是，**不使用 `!` 来标记破坏性操作**。Ruby 和 Rails 中有很多破坏性方法不以 `!` 结尾。

## 8. 查找类似代码

### 8.1 编写新代码时

**在编写新代码时，除非你非常熟悉我们的方法，否则尝试找到类似的代码作为参考。**

Pull Request 是进行这种讨论的好地方。

## 应用到 BuildX

### 建议采用的实践

1. **条件返回**：优先使用展开的条件语句，除非在方法开头需要提前返回
2. **方法排序**：按调用顺序组织方法，帮助理解代码流程
3. **可见性修饰符**：不使用换行符，内容缩进
4. **CRUD 控制器**：使用资源而不是自定义动作
5. **控制器和模型交互**：薄控制器 + 丰富的领域模型
6. **异步操作命名**：使用 `_later` 和 `_now` 后缀

### 需要讨论的实践

1. **条件返回**：是否完全采用展开的条件语句，还是保留 guard clauses 的使用场景？
2. **方法排序**：是否严格按照调用顺序组织方法？

## 参考资料

- [Fizzy STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

