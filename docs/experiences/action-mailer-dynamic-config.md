---
date: 2025-12-02
problem_type: 后端逻辑 / 配置问题
status: 已解决
---

# ActionMailer 动态配置从数据库读取

## 问题描述

在开发邮件功能时，遇到以下问题：

1. **配置在启动时读取失效**：在 `config/initializers/200_action_mailer.rb` 中使用 `after_initialize` 设置邮件配置时，发现配置可能失效，因为 ActionMailer 的默认配置在 `after_initialize` 之前就已经加载了。

2. **配置更新需要重启服务器**：如果邮件服务器配置（SMTP 设置、发件人地址、站点域名等）存储在数据库中，在管理后台更新配置后，需要重启 Rails 服务器才能生效，这很不方便。

3. **localhost 问题**：在生产环境发送邮件时，邮件中的链接显示为 `localhost`，而不是配置的站点域名。

## 问题原因分析

### ActionMailer 配置加载机制

1. **配置加载顺序**：
   - `config/environments/*.rb` 中的配置首先加载
   - `ActiveSupport.on_load(:action_mailer)` 回调执行，将 `Rails.application.config.action_mailer` 的配置复制到 `ActionMailer::Base`
   - `after_initialize` 回调执行（此时可以读取数据库）

2. **为什么 `after_initialize` 中设置可能失效**：
   - 如果设置到 `Rails.application.config.action_mailer`，配置可能已经被 `on_load` 回调处理过了
   - 需要直接设置到 `ActionMailer::Base` 类上，而不是 `Rails.application.config.action_mailer`

3. **动态更新的需求**：
   - 配置存储在数据库中，可能在应用运行期间更新
   - 需要在不重启服务器的情况下应用新配置
   - 每次发送邮件时都应该使用最新的配置

## 解决方案

### 1. 定义共享的配置读取方法

在 `ApplicationMailer` 中定义类方法，从数据库读取配置：

```ruby
class ApplicationMailer < ActionMailer::Base
  # Get SMTP settings from database
  def self.smtp_settings_from_db
    return nil unless Rails.env.production?
    return nil unless ActiveRecord::Base.connection.table_exists?("system_configs")

    smtp_address = SystemConfig.get("smtp_address")
    return nil unless smtp_address.present?

    # ... 读取其他 SMTP 配置项
    {
      address: smtp_address,
      port: smtp_port&.to_i || 465,
      # ...
    }.compact
  end

  # Get default_url_options from database
  def self.default_url_options_from_db
    # ... 从数据库读取 site_domain 配置
  end

  # Get default from address from database
  def self.default_from_address
    # ... 从数据库读取 mail_from_address 和 mail_from_name
  end
end
```

### 2. 在 `after_initialize` 中设置初始配置

在 `config/initializers/200_action_mailer.rb` 中，直接设置到 `ActionMailer::Base`：

```ruby
Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # 使用共享方法获取配置
  if Rails.env.production?
    smtp_settings = ApplicationMailer.smtp_settings_from_db
    if smtp_settings
      # 直接设置到 ActionMailer::Base，而不是 Rails.application.config.action_mailer
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = smtp_settings
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true
    end
  end

  # 设置 default_url_options
  url_options = ApplicationMailer.default_url_options_from_db
  if url_options
    ActionMailer::Base.default_url_options = url_options
  end

  # 设置 from 地址
  from_address = ApplicationMailer.default_from_address
  ActionMailer::Base.default from: from_address
end
```

### 3. 在 `before_action` 中动态更新配置

在 `ApplicationMailer` 中添加 `before_action`，每次发送邮件时更新配置：

```ruby
class ApplicationMailer < ActionMailer::Base
  before_action :update_mailer_settings

  # 使用 proc 动态读取 from 地址
  default from: -> { ApplicationMailer.default_from_address }

  private

    def update_mailer_settings
      return unless ActiveRecord::Base.connection.table_exists?("system_configs")

      # 更新 SMTP 设置
      if Rails.env.production?
        smtp_settings = self.class.smtp_settings_from_db
        if smtp_settings
          ActionMailer::Base.delivery_method = :smtp
          ActionMailer::Base.smtp_settings = smtp_settings
          ActionMailer::Base.perform_deliveries = true
          ActionMailer::Base.raise_delivery_errors = true
        end
      end

      # 更新 default_url_options
      url_options = self.class.default_url_options_from_db
      if url_options
        ActionMailer::Base.default_url_options = url_options
      end
    end
end
```

## 关键经验总结

### 1. 配置设置位置

**重要**：在 `after_initialize` 中设置配置时，必须直接设置到 `ActionMailer::Base`，而不是 `Rails.application.config.action_mailer`。

**原因**：
- `Rails.application.config.action_mailer` 的配置在 `ActiveSupport.on_load(:action_mailer)` 时已经被复制到 `ActionMailer::Base`
- 在 `after_initialize` 中修改 `Rails.application.config.action_mailer` 不会影响已经加载的 `ActionMailer::Base` 配置
- 必须直接设置到 `ActionMailer::Base` 才能覆盖初始配置

### 2. 共享配置读取方法

**最佳实践**：将配置读取逻辑提取为共享的类方法，在启动时和发送邮件时都调用。

**优势**：
- 代码复用：启动时和发送邮件时使用相同的逻辑
- 一致性：确保配置读取逻辑统一
- 维护性：配置读取逻辑集中在一个地方，易于维护

### 3. 动态更新机制

**实现方式**：在 `before_action` 中从数据库读取最新配置并更新到 `ActionMailer::Base`。

**工作原理**：
- 启动时：`after_initialize` 从数据库读取配置并设置初始值
- 发送邮件时：`before_action` 从数据库读取最新配置并更新
- 配置更新：在管理后台更新配置后，下次发送邮件时自动使用新配置，无需重启服务器

### 4. `from` 地址的动态读取

**使用 proc**：`default from: -> { ApplicationMailer.default_from_address }` 确保每次创建邮件对象时都从数据库读取最新的 `from` 地址。

**注意**：`default from` 的 proc 在邮件对象创建时执行，而不是在发送时执行，所以可以确保使用最新配置。

### 5. SMTP 配置的更新

**全局配置更新**：在 `before_action` 中更新 `ActionMailer::Base.smtp_settings`，这会影响所有后续的邮件发送。

**注意**：虽然这是全局配置，但由于每次发送邮件时都会更新，所以总是使用最新的配置。

## 注意事项

1. **数据库表检查**：在读取配置前，需要检查 `system_configs` 表是否存在，避免在数据库迁移时出错。

2. **环境判断**：SMTP 配置只在生产环境使用，开发环境使用 `letter_opener`。

3. **配置缓存**：如果使用 `SystemConfig::Current.values` 缓存，需要在测试中清除缓存，确保测试隔离。

4. **性能考虑**：每次发送邮件时都从数据库读取配置，如果配置更新不频繁，可以考虑添加缓存机制。

## 相关文件

- `app/mailers/application_mailer.rb` - 定义配置读取方法和 `before_action`
- `config/initializers/200_action_mailer.rb` - 在启动时设置初始配置
- `app/models/system_config.rb` - 系统配置模型
- `test/mailers/application_mailer_test.rb` - 测试文件

## 参考资料

- [Rails ActionMailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html)
- [ActionMailer Configuration](https://guides.rubyonrails.org/configuring.html#action-mailer-configuration)
- [Rails Initializers](https://guides.rubyonrails.org/configuring.html#using-initializer-files)

