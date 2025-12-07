---
date: 2025-12-07
problem_type: 学习笔记、最佳实践、总结
status: 已完成
tags: Fizzy、最佳实践、总结、代码风格、设计模式
description: Fizzy 最佳实践学习的综合总结，包括代码风格指南、模型设计、控制器设计、Hotwire 使用、测试策略等核心内容
---

# Fizzy 最佳实践学习总结

## 项目概览

**Fizzy** 是 Basecamp/37signals 开源的 Kanban 看板工具，采用 Ruby on Rails 8.1 + Hotwire 开发。

- **GitHub**: https://github.com/basecamp/fizzy
- **技术栈**: Rails 8.1, Hotwire (Turbo + Stimulus), Kamal, SQLite/MySQL
- **代码规模**: 588 个 Ruby 文件, 305 个 ERB 视图, 175 个测试文件
- **最新提交**: 2025-12-07 (3 小时前)

## 核心发现

### 1. 代码风格指南（STYLE.md）

#### 1.1 条件返回

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

**例外情况**：在方法开头使用 guard clause 提前返回是可以的，特别是当主方法体比较复杂时。

#### 1.2 方法排序

**方法在类中的排序：**

1. `class` 方法
2. `public` 方法（`initialize` 在最前面）
3. `private` 方法

#### 1.3 调用顺序

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

#### 1.4 可见性修饰符

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

**如果模块只有私有方法，在顶部标记 `private`，后面加一个空行但不缩进：**

```ruby
module SomeModule
  private
  
  def some_private_method
    # ...
  end
end
```

#### 1.5 CRUD 控制器

**使用资源而不是自定义动作：**

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

#### 1.6 控制器和模型交互

**偏好 Vanilla Rails 方式：薄控制器 + 丰富的领域模型**

- 直接调用 Active Record 操作是可以的
- 对于复杂行为，使用清晰的、意图明确的模型 API
- 必要时可以使用服务或表单对象，但不把它们当作特殊工件

```ruby
# 简单操作
class Cards::CommentsController < ApplicationController
  def create
    @comment = @card.comments.create!(comment_params)
  end
end

# 复杂行为
class Cards::GoldnessesController < ApplicationController
  def create
    @card.gild
  end
end

# 服务对象
Signup.new(email_address: email_address).create_identity
```

#### 1.7 异步操作

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

### 2. 应用配置

#### 2.1 Application 配置

```ruby
module Fizzy
  class Application < Rails::Application
    config.load_defaults 8.1

    # 包含 lib 目录到自动加载路径
    config.autoload_lib ignore: %w[ assets tasks rails_ext ]

    # 启用调试模式用于 Rails 事件日志
    config.after_initialize do
      Rails.event.debug_mode = true
    end

    # 为新表使用 UUID 主键
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.mission_control.jobs.http_basic_auth_enabled = false
  end
end
```

**关键点：**
- 使用 UUID 作为主键（所有新表）
- 启用事件日志调试模式
- 自定义自动加载路径

#### 2.2 Application Controller

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include BlockSearchEngineIndexing
  include CurrentRequest, CurrentTimezone, SetPlatform
  include RequestForgeryProtection
  include TurboFlash, ViewTransitions
  include RoutingHeaders

  etag { "v1" }
  stale_when_importmap_changes
  allow_browser versions: :modern
end
```

**关键点：**
- 使用 Concerns 组织共享逻辑
- 启用 ETag 缓存
- 支持现代浏览器

### 3. 路由设计

#### 3.1 RESTful 资源设计

**使用资源而不是自定义动作：**

```ruby
resources :cards do
  scope module: :cards do
    resource :board
    resource :closure
    resource :column
    resource :goldness
    resource :pin
    resource :publish
    resource :reading
    resource :triage
    resource :watch

    resources :assignments
    resources :steps
    resources :taggings

    resources :comments do
      resources :reactions, module: :comments
    end
  end
end
```

#### 3.2 命名空间和模块

**使用 `scope module:` 和 `namespace` 组织路由：**

```ruby
resources :boards do
  scope module: :boards do
    resource :subscriptions
    resource :involvement
    resource :publication
    resource :entropy

    namespace :columns do
      resource :not_now
      resource :stream
      resource :closed
    end

    resources :columns
  end
end
```

#### 3.3 路由解析器

**使用 `resolve` 和 `direct` 创建自定义路由：**

```ruby
direct :published_board do |board, options|
  route_for :public_board, board.publication.key
end

direct :published_card do |card, options|
  route_for :public_board_card, card.board.publication.key, card
end

resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end
```

### 4. 模型设计

#### 4.1 使用 Concerns 组织功能

**模型通过 Concerns 组织功能：**

```ruby
class Card < ApplicationRecord
  include Assignable, Attachments, Broadcastable, Closeable, Colored, Entropic, Eventable,
    Exportable, Golden, Mentions, Multistep, Pinnable, Postponable, Promptable,
    Readable, Searchable, Stallable, Statuses, Taggable, Triageable, Watchable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

**关键点：**
- 使用 Concerns 模块化功能
- 使用 `default: -> { }` 提供默认值
- 清晰的模型关系

#### 4.2 作用域（Scopes）

**使用作用域封装查询逻辑：**

```ruby
scope :reverse_chronologically, -> { order created_at: :desc, id: :desc }
scope :chronologically,         -> { order created_at: :asc,  id: :asc  }
scope :latest,                  -> { order last_active_at: :desc, id: :desc }
scope :with_users,              -> { preload(creator: [ :avatar_attachment, :account ], assignees: [ :avatar_attachment, :account ]) }
scope :preloaded,               -> { with_users.preload(:column, :tags, :steps, :closure, :goldness, :activity_spike, :image_attachment, board: [ :entropy, :columns ], not_now: [ :user ]).with_rich_text_description_and_embeds }

scope :indexed_by, ->(index) do
  case index
  when "stalled" then stalled
  when "postponing_soon" then postponing_soon
  when "closed" then closed
  when "not_now" then postponed.latest
  when "golden" then golden
  when "draft" then drafted
  else all
  end
end
```

**关键点：**
- 使用链式作用域
- 使用 `preload` 避免 N+1 查询
- 使用参数化作用域

#### 4.3 业务逻辑封装

**在模型中封装业务逻辑：**

```ruby
def move_to(new_board)
  transaction do
    card.update!(board: new_board)
    card.events.update_all(board_id: new_board.id)
  end
end

def filled?
  title.present? || description.present?
end
```

### 5. 控制器设计

#### 5.1 薄控制器

**控制器保持简洁，直接调用模型方法：**

```ruby
class CardsController < ApplicationController
  include FilterScoped

  before_action :set_board, only: %i[ create ]
  before_action :set_card, only: %i[ show edit update destroy ]
  before_action :ensure_permission_to_administer_card, only: %i[ destroy ]

  def create
    card = @board.cards.find_or_create_by!(creator: Current.user, status: "drafted")
    redirect_to card
  end

  def update
    @card.update! card_params
  end

  def destroy
    @card.destroy!
    redirect_to @card.board, notice: "Card deleted"
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:id])
    end

    def card_params
      params.expect(card: [ :status, :title, :description, :image, tag_ids: [] ])
    end
end
```

**关键点：**
- 使用 `params.expect` 而不是 `params.require`
- 使用 `before_action` 组织共享逻辑
- 权限检查封装在私有方法中

#### 5.2 使用 Concerns

**使用 Concerns 组织控制器共享逻辑：**

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include FilterScoped
  include TurboFlash, ViewTransitions
end
```

### 6. Hotwire 使用

#### 6.1 Turbo Streams

**使用 Turbo Streams 实现实时更新：**

**控制器示例：**

```ruby
class Cards::PinsController < ApplicationController
  include CardScoped

  def create
    @pin = @card.pin_by Current.user

    broadcast_add_pin_to_tray
    render_pin_button_replacement
  end

  def destroy
    @pin = @card.unpin_by Current.user

    broadcast_remove_pin_from_tray
    render_pin_button_replacement
  end

  private
    def broadcast_add_pin_to_tray
      @pin.broadcast_prepend_to [ Current.user, :pins_tray ], target: "pins", partial: "my/pins/pin"
    end

    def broadcast_remove_pin_from_tray
      @pin.broadcast_remove_to [ Current.user, :pins_tray ]
    end

    def render_pin_button_replacement
      render turbo_stream: turbo_stream.replace([ @card, :pin_button ], partial: "cards/pins/pin_button", locals: { card: @card })
    end
end
```

**视图示例（create.turbo_stream.erb）：**

```erb
<%= turbo_stream.before [ @card, :new_comment ], partial: "cards/comments/comment", locals: { comment: @comment } %>

<%= turbo_stream.update [ @card, :new_comment ], partial: "cards/comments/new", locals: { card: @card } %>
```

**视图示例（destroy.turbo_stream.erb）：**

```erb
<%= turbo_stream.remove [ @comment, :container ] %>
```

#### 6.2 Turbo Frames

**使用 Turbo Frames 实现局部更新：**

```erb
<%= turbo_frame_tag comment, :container do %>
  <div id="<%= dom_id(comment) %>" data-creator-id="<%= comment.creator_id %>" class="comment">
    <!-- 评论内容 -->
  </div>
<% end %>
```

#### 6.3 Turbo Stream From

**在视图中订阅广播：**

```erb
<%= turbo_stream_from @card %>
<%= turbo_stream_from @card, :activity %>
```

#### 6.4 Stimulus 控制器

**使用 Stimulus 处理交互逻辑：**

```erb
<div data-controller="beacon lightbox" data-beacon-url-value="<%= card_reading_path(@card) %>">
  <!-- 内容 -->
</div>
```

**Stimulus 控制器示例：**

- `dialog_manager_controller.js` - 对话框管理
- `retarget_links_controller.js` - 链接重定向
- `collapsible_columns_controller.js` - 可折叠列
- `fetch_on_visible_controller.js` - 可见时获取
- `navigable_list_controller.js` - 可导航列表
- `syntax_highlight_controller.js` - 语法高亮
- `notifications_tray_controller.js` - 通知托盘

### 7. 视图组织

#### 7.1 使用 Partials

**视图通过 Partials 组织：**

```erb
<%= render "cards/container", card: @card %>
<%= render "cards/messages",  card: @card unless @card.drafted? %>
```

#### 7.2 缓存

**使用片段缓存：**

```erb
<% cache comment do %>
  <%= turbo_frame_tag comment, :container do %>
    <!-- 内容 -->
  <% end %>
<% end %>
```

#### 7.3 Content For

**使用 `content_for` 组织页面特定内容：**

```erb
<% content_for :head do %>
  <%= card_social_tags(@card) %>
<% end %>

<% content_for :header do %>
  <div class="header__actions header__actions--start">
    <%= link_back_to_board(@card.board) %>
  </div>
<% end %>
```

### 8. 测试策略

#### 8.1 测试组织

- **模型测试**: 76 个文件
- **控制器测试**: 83 个文件
- **系统测试**: 1 个文件
- **集成测试**: 0 个文件

#### 8.2 测试命令

```bash
# 快速反馈循环
bin/rails test

# 完整 CI 测试
bin/ci
```

### 9. 部署配置

#### 9.1 Kamal 部署

**使用 Kamal 进行部署：**

```yaml
# config/deploy.yml
servers:
  web:
    host: your-server.com

proxy:
  ssl: true
  host: your-server.com

env:
  clear:
    MAILER_FROM_ADDRESS: noreply@your-server.com
```

#### 9.2 环境变量

**使用 `.kamal/secrets` 管理密钥：**

```ini
SECRET_KEY_BASE=...
VAPID_PUBLIC_KEY=...
VAPID_PRIVATE_KEY=...
SMTP_USERNAME=...
SMTP_PASSWORD=...
```

### 10. 数据库配置

#### 10.1 多数据库支持

**支持 SQLite 和 MySQL：**

```bash
# 默认使用 SQLite
bin/setup

# 使用 MySQL
DATABASE_ADAPTER=mysql bin/setup --reset
```

#### 10.2 UUID 主键

**所有新表使用 UUID 主键：**

```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

### 11. 后台任务（Jobs）

#### 11.1 任务设计原则

**薄任务类，将逻辑委托给领域模型：**

```ruby
class ApplicationJob < ActiveJob::Base
  # 自动重试遇到死锁的任务
  # retry_on ActiveRecord::Deadlocked

  # 如果底层记录不再可用，大多数任务可以安全地忽略
  # discard_on ActiveJob::DeserializationError
end
```

#### 11.2 任务示例

**推送通知任务：**

```ruby
class PushNotificationJob < ApplicationJob
  def perform(notification)
    NotificationPusher.new(notification).push
  end
end
```

**提及创建任务：**

```ruby
class Mention::CreateJob < ApplicationJob
  def perform(record, mentioner:)
    record.create_mentions(mentioner:)
  end
end
```

**活动峰值检测任务：**

```ruby
class Card::ActivitySpike::DetectionJob < ApplicationJob
  def perform(card)
    card.detect_activity_spikes
  end
end
```

**关键点：**
- 任务类保持简洁
- 业务逻辑在模型中实现
- 使用命名空间组织任务（如 `Mention::CreateJob`）

### 12. 邮件系统（Mailers）

#### 12.1 Application Mailer

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

#### 12.2 邮件类示例

**魔法链接邮件：**

```ruby
class MagicLinkMailer < ApplicationMailer
  def sign_in_instructions(magic_link)
    @magic_link = magic_link
    @identity = @magic_link.identity

    mail to: @identity.email_address, subject: "Your Fizzy code is #{ @magic_link.code }"
  end
end
```

**用户邮件：**

```ruby
class UserMailer < ApplicationMailer
  def email_change_confirmation(email_address:, token:, user:)
    @token = token
    @user = user
    mail to: email_address, subject: "Confirm your new email address"
  end
end
```

**关键点：**
- 使用关键字参数提高可读性
- 在邮件中设置实例变量供视图使用
- 使用 `default_url_options` 处理多租户 URL

### 13. 测试策略

#### 13.1 测试配置

**test_helper.rb 配置：**

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "mocha/minitest"
require "turbo/broadcastable/test_helper"

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

**关键点：**
- 使用并行测试（`parallelize`）
- 使用 Fixtures 准备测试数据
- 包含测试辅助模块
- 在 setup/teardown 中管理 Current 对象

#### 13.2 UUID Fixtures 支持

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
      # ...
    end
  end
end
```

#### 13.3 测试示例

**模型测试：**

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
end
```

**控制器测试：**

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
        # ...
      }
    }
    assert_response :success
  end
end
```

**关键点：**
- 使用 `assert_difference` 测试副作用
- 使用 `sign_in_as` 辅助方法进行认证
- 测试 Turbo Stream 响应（`as: :turbo_stream`）

### 14. 高级特性

#### 14.1 Action Cable

**连接管理：**

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if session = find_session_by_cookie
          account = Account.find_by(external_account_id: request.env["fizzy.external_account_id"])
          Current.account = account
          self.current_user = session.identity.users.find_by!(account: account) if account
        end
      end

      def find_session_by_cookie
        Session.find_signed(cookies.signed[:session_token])
      end
  end
end
```

**关键点：**
- 使用 `identified_by` 标识连接
- 通过 Cookie 查找会话
- 设置 Current 对象

#### 14.2 自定义库（lib）

**Fizzy 模块：**

```ruby
module Fizzy
  class << self
    def saas?
      return @saas if defined?(@saas)
      @saas = !!(((ENV["SAAS"] || File.exist?(File.expand_path("../tmp/saas.txt", __dir__))) && ENV["SAAS"] != "false"))
    end

    def db_adapter
      @db_adapter ||= DbAdapter.new ENV.fetch("DATABASE_ADAPTER", saas? ? "mysql" : "sqlite")
    end
  end

  class DbAdapter
    def initialize(name)
      @name = name.to_s
    end

    def sqlite?
      @name == "sqlite"
    end
  end
end
```

**关键点：**
- 使用模块组织应用级配置
- 使用单例方法提供全局访问
- 延迟初始化（`||=`）

#### 14.3 Rails 扩展（rails_ext）

**Action Text 扩展：**

```ruby
module ActionText
  module Extensions
    module RichText
      extend ActiveSupport::Concern

      included do
        # 覆盖默认的 :embeds 关联
        has_many_attached :embeds do |attachable|
          ::Attachments::VARIANTS.each do |variant_name, variant_options|
            attachable.variant variant_name, variant_options.merge(preprocessed: true)
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_text_rich_text) do
  include ActionText::Extensions::RichText
end
```

**关键点：**
- 使用 `ActiveSupport.on_load` 扩展 Rails 组件
- 使用 Concerns 组织扩展
- 覆盖默认行为

#### 14.4 初始化器

**内容安全策略（CSP）：**

```ruby
Rails.application.configure do
  # 使用环境变量配置，回退到 config.x 值
  report_uri = ENV.fetch("CSP_REPORT_URI") { config.x.content_security_policy.report_uri }
  report_only = ENV.key?("CSP_REPORT_ONLY") ? ENV["CSP_REPORT_ONLY"] == "true" : config.x.content_security_policy.report_only

  # 为 importmap 和内联脚本生成 nonces
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src ]

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self, "https://challenges.cloudflare.com"
    policy.connect_src :self, "https://storage.basecamp.com"
    # ...
  end

  config.content_security_policy_report_only = report_only
end unless ENV["DISABLE_CSP"]
```

**关键点：**
- 使用环境变量配置
- 支持报告模式（`report_only`）
- 使用 nonces 增强安全性

## 可以应用到 BuildX 的实践

### 1. 代码风格

- ✅ **条件返回**：优先使用展开的条件语句
- ✅ **方法排序**：按调用顺序组织方法
- ✅ **可见性修饰符**：不使用换行符，内容缩进
- ✅ **CRUD 控制器**：使用资源而不是自定义动作
- ✅ **异步操作命名**：使用 `_later` 和 `_now` 后缀

### 2. 模型设计

- ✅ **使用 Concerns**：通过 Concerns 模块化功能
- ✅ **作用域链**：使用链式作用域封装查询
- ✅ **业务逻辑封装**：在模型中封装业务逻辑
- ✅ **默认值**：使用 `default: -> { }` 提供动态默认值

### 3. 控制器设计

- ✅ **薄控制器**：保持控制器简洁
- ✅ **使用 Concerns**：组织共享逻辑
- ✅ **参数处理**：使用 `params.expect`
- ✅ **权限检查**：封装在私有方法中

### 4. Hotwire 使用

- ✅ **Turbo Streams**：实现实时更新
- ✅ **Turbo Frames**：实现局部更新
- ✅ **Stimulus**：处理交互逻辑
- ✅ **广播机制**：使用 `broadcast_prepend_to`、`broadcast_remove_to` 等

### 5. 路由设计

- ✅ **RESTful 资源**：使用资源而不是自定义动作
- ✅ **命名空间**：使用 `scope module:` 和 `namespace` 组织路由
- ✅ **路由解析器**：使用 `resolve` 和 `direct` 创建自定义路由

### 6. 视图组织

- ✅ **Partials**：使用 Partials 组织视图
- ✅ **缓存**：使用片段缓存
- ✅ **Content For**：使用 `content_for` 组织页面特定内容

### 7. 配置

- ✅ **UUID 主键**：考虑为新表使用 UUID 主键
- ✅ **自动加载**：配置 `autoload_lib` 包含自定义库
- ✅ **事件日志**：启用事件日志调试模式

### 8. 后台任务

- ✅ **薄任务类**：任务类保持简洁，逻辑在模型中
- ✅ **命名空间**：使用命名空间组织任务（如 `Mention::CreateJob`）
- ✅ **错误处理**：配置 `retry_on` 和 `discard_on`

### 9. 邮件系统

- ✅ **关键字参数**：使用关键字参数提高可读性
- ✅ **多租户 URL**：使用 `default_url_options` 处理多租户
- ✅ **辅助方法**：在 ApplicationMailer 中共享辅助方法

### 10. 测试策略

- ✅ **并行测试**：使用 `parallelize` 加速测试
- ✅ **测试辅助模块**：创建可复用的测试辅助模块
- ✅ **Current 对象管理**：在 setup/teardown 中管理 Current 对象
- ✅ **UUID Fixtures**：如果需要 UUID，实现自定义 Fixtures 支持

### 11. 高级特性

- ✅ **Action Cable**：使用 `identified_by` 标识连接
- ✅ **Rails 扩展**：使用 `ActiveSupport.on_load` 扩展 Rails 组件
- ✅ **内容安全策略**：配置 CSP 增强安全性
- ✅ **自定义库**：使用模块组织应用级配置

## 学习资源

- [Fizzy GitHub](https://github.com/basecamp/fizzy)
- [STYLE.md](https://github.com/basecamp/fizzy/blob/main/STYLE.md)
- [Hotwire 文档](https://hotwired.dev/)
- [Kamal 文档](https://kamal-deploy.org/)
- [Vanilla Rails](https://dev.37signals.com/vanilla-rails-is-plenty/)

## 下一步行动

1. **应用代码风格指南**：更新 BuildX 的代码风格，参考 Fizzy 的 STYLE.md
2. **优化模型设计**：使用 Concerns 更好地组织模型功能
3. **改进路由设计**：使用资源而不是自定义动作
4. **增强 Hotwire 使用**：更好地使用 Turbo Streams 和 Turbo Frames
5. **优化视图组织**：更好地使用 Partials 和缓存

## 更新记录

- **创建日期**：2025-01-XX
- **最后更新**：2025-01-XX

