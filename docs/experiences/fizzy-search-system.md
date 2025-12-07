---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、业务系统设计
status: 已完成
tags: Fizzy、搜索系统、Search、全文搜索
description: 总结从 Basecamp Fizzy 项目学习到的搜索系统设计，包括 Searchable Concern、自动索引、多数据库适配器、搜索高亮等功能
---

# Fizzy 搜索系统设计

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的搜索系统设计。搜索系统支持全文搜索、自动索引、多数据库适配器等功能。

## 核心设计

### 1. Searchable Concern

**使用 Concern 让模型支持搜索：**

```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit :create_in_search_index
    after_update_commit :update_in_search_index
    after_destroy_commit :remove_from_search_index
  end

  def reindex
    update_in_search_index
  end

  private
    def create_in_search_index
      search_record_class.create!(search_record_attributes)
    end

    def update_in_search_index
      search_record_class.upsert!(search_record_attributes)
    end

    def remove_from_search_index
      search_record_class.find_by(
        searchable_type: self.class.name, 
        searchable_id: id
      )&.destroy
    end

    def search_record_attributes
      {
        account_id: account_id,
        searchable_type: self.class.name,
        searchable_id: id,
        card_id: search_card_id,
        board_id: search_board_id,
        title: search_title,
        content: search_content,
        created_at: created_at
      }
    end

    def search_record_class
      Search::Record.for(account_id)
    end

  # Models must implement these methods:
  # - account_id: returns the account id
  # - search_title: returns title string or nil
  # - search_content: returns content string
  # - search_card_id: returns the card id (self.id for cards, card_id for comments)
  # - search_board_id: returns the board id
end
```

### 2. 关键设计点

#### 2.1 自动索引

**使用回调自动索引：**

```ruby
after_create_commit :create_in_search_index
after_update_commit :update_in_search_index
after_destroy_commit :remove_from_search_index
```

**好处**：
- 自动保持索引同步
- 无需手动维护
- 提高搜索准确性

#### 2.2 多数据库适配器

**支持不同的数据库适配器：**

```ruby
def search_record_class
  Search::Record.for(account_id)
end
```

**支持的适配器**：
- SQLite（使用 FTS）
- MySQL（使用 Trilogy）

#### 2.3 模板方法模式

**使用模板方法模式定义接口：**

```ruby
# Models must implement these methods:
# - account_id: returns the account id
# - search_title: returns title string or nil
# - search_content: returns content string
# - search_card_id: returns the card id
# - search_board_id: returns the board id
```

**好处**：
- 清晰的接口定义
- 易于实现
- 支持多种模型

#### 2.4 重新索引

**支持手动重新索引：**

```ruby
def reindex
  update_in_search_index
end
```

**用途**：
- 修复索引问题
- 批量更新索引
- 迁移数据

### 3. Search::Record 模型

**搜索记录模型：**

```ruby
class Search::Record < ApplicationRecord
  self.table_name = "search_records"

  belongs_to :account
  belongs_to :searchable, polymorphic: true
  belongs_to :card, optional: true
  belongs_to :board, optional: true

  scope :for_account, ->(account) { where(account: account) }
  scope :matching, ->(query) { where("MATCH(title, content) AGAINST(? IN NATURAL LANGUAGE MODE)", query) }

  class << self
    def for(account_id)
      # 根据数据库类型返回不同的实现
      case db_adapter
      when "sqlite"
        Search::Record::Sqlite
      when "mysql"
        Search::Record::Trilogy
      end
    end
  end
end
```

### 4. Search::Query

**搜索查询类：**

```ruby
class Search::Query
  def initialize(account:, terms:)
    @account = account
    @terms = Array(terms)
  end

  def results
    @results ||= begin
      records = Search::Record.for_account(@account)
      @terms.each do |term|
        records = records.matching(term)
      end
      records.preload(:searchable, :card, :board)
    end
  end
end
```

### 5. Search::Result

**搜索结果类：**

```ruby
class Search::Result
  attr_reader :record, :highlighter

  def initialize(record, query:)
    @record = record
    @highlighter = Search::Highlighter.new(record, query)
  end

  def title
    highlighter.highlight_title
  end

  def content
    highlighter.highlight_content
  end
end
```

### 6. 使用示例

#### 6.1 在模型中实现搜索

```ruby
class Card < ApplicationRecord
  include Searchable

  def search_title
    title
  end

  def search_content
    description.to_plain_text
  end

  def search_card_id
    id
  end

  def search_board_id
    board_id
  end
end
```

#### 6.2 执行搜索

```ruby
query = Search::Query.new(account: Current.account, terms: ["ruby", "rails"])
results = query.results
```

#### 6.3 重新索引

```ruby
card.reindex
```

### 7. 应用到 BuildX

#### 7.1 建议采用的实践

1. **自动索引**：使用回调自动索引
2. **多数据库适配器**：支持不同的数据库适配器
3. **模板方法模式**：使用模板方法模式定义接口
4. **重新索引**：支持手动重新索引
5. **搜索高亮**：支持搜索高亮

#### 7.2 实现步骤

1. **创建 Searchable Concern**
   - 实现自动索引回调
   - 定义模板方法接口
   - 实现重新索引方法

2. **创建 Search::Record 模型**
   - 实现多态关联
   - 实现多数据库适配器
   - 实现搜索查询

3. **创建 Search::Query 类**
   - 实现查询构建
   - 支持多词搜索
   - 实现结果预加载

4. **创建 Search::Result 类**
   - 实现结果封装
   - 实现搜索高亮
   - 支持结果格式化

5. **在模型中集成**
   - 包含 `Searchable` Concern
   - 实现模板方法
   - 测试搜索功能

## 参考资料

- [Fizzy Searchable Concern](https://github.com/basecamp/fizzy/blob/main/app/models/concerns/searchable.rb)
- [Fizzy Search::Record](https://github.com/basecamp/fizzy/blob/main/app/models/search/record.rb)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

