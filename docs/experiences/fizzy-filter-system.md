---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、过滤系统、Filter、查询构建
description: 总结从 Basecamp Fizzy 项目学习到的过滤系统设计，包括 Filter 模型、模块化设计、链式查询构建、缓存支持和参数摘要等功能
---

# Fizzy 过滤系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的过滤系统设计。过滤系统支持高级过滤功能、条件保存、缓存等功能。

## 核心设计

### 1. Filter 模型

```ruby
class Filter < ApplicationRecord
  include Fields, Params, Resources, Summarized

  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { creator.account }

  class << self
    def from_params(params)
      find_by_params(params) || build(params)
    end

    def remember(attrs)
      create!(attrs)
    rescue ActiveRecord::RecordNotUnique
      find_by_params(attrs).tap(&:touch)
    end
  end

  def cards
    @cards ||= begin
      result = creator.accessible_cards.preloaded.published
      result = result.indexed_by(indexed_by)
      result = result.sorted_by(sorted_by)
      result = result.where(id: card_ids) if card_ids.present?
      result = result.where.missing(:not_now) unless include_not_now_cards?
      result = result.open unless include_closed_cards?
      result = result.unassigned if assignment_status.unassigned?
      result = result.assigned_to(assignees.ids) if assignees.present?
      result = result.where(creator_id: creators.ids) if creators.present?
      result = result.where(board: boards.ids) if boards.present?
      result = result.tagged_with(tags.ids) if tags.present?
      result = result.where("cards.created_at": creation_window) if creation_window
      result = result.closed_at_window(closure_window) if closure_window
      result = result.closed_by(closers) if closers.present?
      result = terms.reduce(result) do |result, term|
        result.mentioning(term, user: creator)
      end

      result.distinct
    end
  end

  def empty?
    self.class.normalize_params(as_params).blank?
  end

  def single_board
    boards.first if boards.one?
  end

  def single_workflow
    boards.first.workflow if boards.pluck(:workflow_id).uniq.one?
  end

  def cacheable?
    boards.exists?
  end

  def cache_key
    ActiveSupport::Cache.expand_cache_key params_digest, "filter"
  end

  def only_closed?
    indexed_by.closed? || closure_window || closers.present?
  end

  private
    def include_closed_cards?
      only_closed? || card_ids.present?
    end

    def include_not_now_cards?
      indexed_by.not_now? || card_ids.present?
    end
end
```

### 2. 关键设计点

#### 2.1 模块化设计

**使用多个 Concerns 组织功能：**

```ruby
include Fields, Params, Resources, Summarized
```

**模块职责**：
- `Fields`：字段定义和验证
- `Params`：参数处理和规范化
- `Resources`：资源关联（boards, tags, users 等）
- `Summarized`：摘要生成

#### 2.2 链式查询构建

**使用链式查询构建复杂过滤：**

```ruby
def cards
  @cards ||= begin
    result = creator.accessible_cards.preloaded.published
    result = result.indexed_by(indexed_by)
    result = result.sorted_by(sorted_by)
    result = result.where(id: card_ids) if card_ids.present?
    result = result.where.missing(:not_now) unless include_not_now_cards?
    result = result.open unless include_closed_cards?
    # ... 更多过滤条件
    result.distinct
  end
end
```

**好处**：
- 清晰的查询逻辑
- 易于扩展
- 支持条件组合

#### 2.3 从参数创建

**从参数创建或查找 Filter：**

```ruby
class << self
  def from_params(params)
    find_by_params(params) || build(params)
  end
end
```

**好处**：
- 避免重复创建
- 支持条件保存
- 提高性能

#### 2.4 缓存支持

**支持缓存过滤结果：**

```ruby
def cacheable?
  boards.exists?
end

def cache_key
  ActiveSupport::Cache.expand_cache_key params_digest, "filter"
end
```

**好处**：
- 提高查询性能
- 减少数据库负载
- 支持缓存失效

#### 2.5 参数摘要

**使用摘要标识 Filter：**

```ruby
def params_digest
  Digest::SHA256.hexdigest(as_params.to_json)
end
```

**好处**：
- 唯一标识过滤条件
- 支持查找和去重
- 支持缓存键生成

### 3. Filterable Concern

**让资源支持过滤：**

```ruby
module Filterable
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :filters

    after_update { filters.touch_all }
    before_destroy :remove_from_filters
  end

  private
    def remove_from_filters
      filters.each { it.resource_removed self }
    end
end
```

**好处**：
- 资源变更时自动更新过滤器
- 资源删除时自动清理过滤器
- 支持多对多关系

### 4. 支持的过滤条件

**Filter 支持多种过滤条件：**

1. **索引类型**（indexed_by）：
   - stalled（停滞）
   - postponing_soon（即将推迟）
   - closed（已关闭）
   - not_now（暂不处理）
   - golden（重要）
   - draft（草稿）

2. **排序方式**（sorted_by）：
   - newest（最新）
   - oldest（最旧）
   - latest（最近活动）

3. **状态过滤**：
   - 包含/排除已关闭的卡片
   - 包含/排除暂不处理的卡片

4. **分配状态**（assignment_status）：
   - unassigned（未分配）
   - assigned（已分配）

5. **资源过滤**：
   - 指定卡片（card_ids）
   - 指定看板（boards）
   - 指定创建者（creators）
   - 指定分配者（assignees）
   - 指定标签（tags）
   - 指定关闭者（closers）

6. **时间窗口**：
   - 创建时间窗口（creation_window）
   - 关闭时间窗口（closure_window）

7. **文本搜索**（terms）：
   - 全文搜索
   - 提及搜索

### 5. 使用示例

#### 5.1 从参数创建 Filter

```ruby
filter = Filter.from_params(
  indexed_by: "stalled",
  sorted_by: "latest",
  boards: [board1, board2],
  tags: [tag1, tag2]
)
```

#### 5.2 保存 Filter

```ruby
filter = Filter.remember(
  indexed_by: "stalled",
  sorted_by: "latest",
  boards: [board1, board2]
)
```

#### 5.3 查询卡片

```ruby
cards = filter.cards
```

### 6. 应用到 BuildX

#### 6.1 建议采用的实践

1. **模块化设计**：使用多个 Concerns 组织功能
2. **链式查询构建**：使用链式查询构建复杂过滤
3. **从参数创建**：从参数创建或查找 Filter
4. **缓存支持**：支持缓存过滤结果
5. **参数摘要**：使用摘要标识 Filter
6. **Filterable Concern**：让资源支持过滤

#### 6.2 实现步骤

1. **创建 Filter 模型**
   - 添加关联（creator, account）
   - 添加过滤字段
   - 实现 `cards` 方法

2. **创建 Concerns**
   - Fields：字段定义和验证
   - Params：参数处理和规范化
   - Resources：资源关联
   - Summarized：摘要生成

3. **实现查询构建**
   - 实现链式查询
   - 支持条件组合
   - 实现缓存

4. **创建 Filterable Concern**
   - 实现资源关联
   - 实现自动更新
   - 实现清理逻辑

5. **实现控制器**
   - 创建 FiltersController
   - 实现创建/更新/删除
   - 实现查询接口

## 参考资料

- [Fizzy Filter 模型](https://github.com/basecamp/fizzy/blob/main/app/models/filter.rb)
- [Fizzy Filterable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/concerns/filterable.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

