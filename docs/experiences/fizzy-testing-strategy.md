---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、测试策略
status: 已完成
tags: Fizzy、测试策略、Testing、并行测试、UUID Fixtures
description: 总结从 Basecamp Fizzy 项目学习到的测试策略，包括测试组织方式、并行测试、UUID fixtures、测试辅助模块等
---

# Fizzy 测试策略

## 概述

本文档总结了从 Basecamp Fizzy 项目学习到的测试策略。Fizzy 的测试策略体现了对代码质量和可维护性的重视。

## 测试组织

### 1. 测试文件结构

**测试文件与代码文件对应：**

```
test/
├── models/              # 模型测试
├── controllers/         # 控制器测试
├── system/              # 系统测试
├── integration/         # 集成测试
├── helpers/             # 辅助方法测试
├── mailers/             # 邮件测试
├── jobs/                # 任务测试
├── fixtures/            # 测试数据
└── test_helper.rb       # 测试配置
```

**统计**：
- 模型测试：76 个文件
- 控制器测试：83 个文件
- 系统测试：1 个文件
- 集成测试：0 个文件

### 2. 测试配置

#### 2.1 test_helper.rb

**测试辅助文件配置：**

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "mocha/minitest"
require "turbo/broadcastable/test_helper"

WebMock.allow_net_connect!

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<OPEN_AI_KEY>") { 
    Rails.application.credentials.openai_api_key || ENV["OPEN_AI_API_KEY"] 
  }
  config.default_cassette_options = {
    match_requests_on: [ :method, :uri, :body_without_times ]
  }
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    include ActiveJob::TestHelper
    include ActionTextTestHelper, CardTestHelper, ChangeTestHelper, SessionTestHelper
    include Turbo::Broadcastable::TestHelper

    setup do
      Current.account = accounts("37s")
    end

    teardown do
      Current.clear_all
    end
  end
end
```

**关键点**：
- 并行测试（`parallelize`）
- 使用 Fixtures 准备测试数据
- 包含测试辅助模块
- 在 setup/teardown 中管理 Current 对象

#### 2.2 UUID Fixtures 支持

**自定义 Fixtures 以支持 UUID：**

```ruby
module FixturesTestHelper
  extend ActiveSupport::Concern

  class_methods do
    def identify(label, column_type = :integer)
      if label.to_s.end_with?("_uuid")
        column_type = :uuid
        label = label.to_s.delete_suffix("_uuid")
      end

      return super(label, column_type) unless column_type.in?([ :uuid, :string ])
      generate_fixture_uuid(label)
    end

    private

    def generate_fixture_uuid(label)
      # 生成确定性 UUIDv7 用于 fixtures
      # 使用 CRC32 算法确保确定性
      fixture_int = Zlib.crc32("fixtures/#{label}") % (2**30 - 1)
      base_time = Time.utc(2024, 1, 1, 0, 0, 0)
      timestamp = base_time + (fixture_int / 1000.0)
      uuid_v7_with_timestamp(timestamp, label)
    end
  end
end

ActiveSupport.on_load(:active_record_fixture_set) do
  prepend(FixturesTestHelper)
end
```

**好处**：
- 支持 UUID 主键
- 确定性 UUID（测试可重复）
- 保持排序顺序

### 3. 测试辅助方法

#### 3.1 测试辅助模块

**创建可复用的测试辅助模块：**

```ruby
module CardTestHelper
  def sign_in_as(user_label)
    session = sessions(user_label)
    Current.session = session
    Current.user = session.user
  end
end
```

**使用方式**：

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end
end
```

#### 3.2 Current 对象管理

**在 setup/teardown 中管理 Current 对象：**

```ruby
setup do
  Current.account = accounts("37s")
  Current.session = sessions(:david)
end

teardown do
  Current.clear_all
end
```

**好处**：
- 确保测试隔离
- 避免测试之间的干扰
- 清晰的测试环境

### 4. 测试示例

#### 4.1 模型测试

```ruby
class CardTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "create assigns a number to the card" do
    user = users(:david)
    board = boards(:writebook)
    account = board.account
    card = nil

    assert_difference -> { account.reload.cards_count }, +1 do
      card = Card.create!(title: "Test", board: board, creator: user)
    end

    assert_equal account.reload.cards_count, card.number
  end

  test "assignment toggling" do
    assert cards(:logo).assigned_to?(users(:kevin))

    assert_difference({ 
      -> { cards(:logo).assignees.count } => -1, 
      -> { Event.count } => +1 
    }) do
      cards(:logo).toggle_assignment users(:kevin)
    end
    assert_not cards(:logo).reload.assigned_to?(users(:kevin))
  end
end
```

**关键点**：
- 使用 `assert_difference` 测试副作用
- 使用 Fixtures 准备测试数据
- 测试业务逻辑

#### 4.2 控制器测试

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create a new draft" do
    assert_difference -> { Card.count }, 1 do
      post board_cards_path(boards(:writebook))
    end

    card = Card.last
    assert card.drafted?
    assert_redirected_to card
  end

  test "update" do
    patch card_path(cards(:logo)), as: :turbo_stream, params: {
      card: {
        title: "New Title"
      }
    }
    assert_response :success
  end
end
```

**关键点**：
- 使用 `sign_in_as` 辅助方法
- 测试 Turbo Stream 响应（`as: :turbo_stream`）
- 测试重定向

### 5. 测试命令

#### 5.1 快速反馈

**快速运行单元测试：**

```bash
bin/rails test
```

#### 5.2 完整测试

**运行完整的 CI 测试：**

```bash
bin/ci
```

### 6. 应用到 BuildX

#### 6.1 建议采用的实践

1. **并行测试**：使用 `parallelize` 加速测试
2. **测试辅助模块**：创建可复用的测试辅助模块
3. **Current 对象管理**：在 setup/teardown 中管理 Current 对象
4. **UUID Fixtures**：如果需要 UUID，实现自定义 Fixtures 支持
5. **测试组织**：测试文件与代码文件对应
6. **断言使用**：使用 `assert_difference` 测试副作用

#### 6.2 实现步骤

1. **配置测试环境**
   - 设置并行测试
   - 配置测试辅助模块
   - 配置 Fixtures

2. **创建测试辅助模块**
   - 创建认证辅助方法
   - 创建数据准备方法
   - 创建断言辅助方法

3. **实现测试**
   - 编写模型测试
   - 编写控制器测试
   - 编写系统测试

4. **优化测试**
   - 识别慢测试
   - 优化查询
   - 使用并行测试

## 参考资料

- [Fizzy test_helper.rb](https://github.com/basecamp/fizzy/blob/main/test/test_helper.rb)
- [Rails 测试指南](https://guides.rubyonrails.org/testing.html)
- [Fizzy 最佳实践学习总览](fizzy-overview.md)

## 更新记录

- **创建日期**：2025-12-07
- **最后更新**：2025-12-07

