---
date: 2025-12-03
problem_type: 后端逻辑、分页功能
status: 已解决
tags: Pagy、分页、升级、Pagy 43、API 迁移
description: 从 Pagy 9 升级到 Pagy 43 的完整指南，包括新特性、配置迁移、代码更新步骤和最佳实践
---

# Pagy 43 升级和使用经验

## 问题描述

项目当前使用的是 Pagy 9.3.4，但 Pagy 43 是经过全面重构的最新版本，提供了更简洁的 API、更强大的功能和更高的性能。为了使用最好的工具，应该升级到 Pagy 43。

## 为什么使用 Pagy 43

### 主要优势

1. **全面重构**：Pagy 43 是对旧版本代码的完全重新设计，代码更简洁、更易维护。
2. **更简洁的 API**：新的 API 设计更加直观和易用。
3. **集成核心功能**：许多旧版本的 extras 已经集成到核心代码中，无需额外配置。
4. **更好的性能**：重构后的代码性能更优。
5. **更强大的功能**：提供了更多开箱即用的功能。

### 版本对比

- **Pagy 9.x**：旧版本，使用 `Pagy::DEFAULT` 配置，需要 require extras
- **Pagy 43.x**：新版本，使用 `Pagy.options` 配置，extras 集成到核心

## 升级步骤

### 1. 更新 Gemfile

```ruby
# 旧版本
gem "pagy", "~> 9.3", ">= 9.3.4"

# 新版本
gem "pagy", "~> 43.0"
```

然后运行：

```bash
bundle update pagy
```

### 2. 替换配置文件

#### 2.1 备份旧配置

将 `config/initializers/pagy.rb` 重命名为 `pagy-old.rb`：

```bash
mv config/initializers/pagy.rb config/initializers/pagy-old.rb
```

#### 2.2 创建新配置

创建新的 `config/initializers/pagy.rb`：

```ruby
# Pagy 43 配置
Pagy::DEFAULT[:items] = 50

# 如果需要自定义选项，使用 Pagy.options
# Pagy.options[:items] = 50
```

#### 2.3 迁移配置项

从 `pagy-old.rb` 中查找所有 `Pagy::DEFAULT[...]` 的使用，并替换为 `Pagy.options[...]`：

```ruby
# 旧版本
Pagy::DEFAULT[:items] = 50
Pagy::DEFAULT[:overflow] = :empty_page

# 新版本
Pagy.options[:items] = 50
# overflow 行为现在是默认的，无需配置
```

### 3. 更新控制器

#### 3.1 替换 include 语句

```ruby
# 旧版本
class ApplicationController < ActionController::Base
  include Pagy::Backend
end

# 新版本
class ApplicationController < ActionController::Base
  include Pagy::Method
end
```

#### 3.2 更新分页方法调用

```ruby
# 旧版本
@pagy, @records = pagy(User.all)

# 新版本（基本用法相同）
@pagy, @records = pagy(User.all)
```

### 4. 更新视图辅助方法

#### 4.1 移除 Pagy::Frontend

```ruby
# 旧版本
module ApplicationHelper
  include Pagy::Frontend
end

# 新版本（无需 include，已集成）
module ApplicationHelper
  # Pagy::Frontend 已集成到核心，无需单独 include
end
```

#### 4.2 更新分页导航方法

```ruby
# 旧版本
<%= pagy_nav(@pagy) %>

# 新版本
<%= @pagy.series_nav %>
```

#### 4.3 其他辅助方法更新

| 旧版本 | 新版本 |
|--------|--------|
| `pagy_nav(@pagy)` | `@pagy.series_nav` |
| `pagy_nav_js(@pagy)` | `@pagy.series_nav_js` |
| `pagy_combo_nav_js(@pagy)` | `@pagy.input_nav_js` |
| `pagy_info(@pagy)` | `@pagy.info_tag` |
| `pagy_prev_url(@pagy)` | `@pagy.page_url(:previous)` |
| `pagy_next_url(@pagy)` | `@pagy.page_url(:next)` |
| `pagy_prev_a(@pagy)` | `@pagy.previous_tag` |
| `pagy_next_a(@pagy)` | `@pagy.next_tag` |

### 5. 处理 Extras

#### 5.1 overflow extra

```ruby
# 旧版本
require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :empty_page

# 新版本
# overflow 行为现在是默认的，无需配置
# 如果之前没有使用 overflow extra（即 Pagy 会抛出错误），
# 现在需要设置 raise_range_error: true
Pagy.options[:raise_range_error] = true
```

#### 5.2 其他 extras

大多数 extras 已经集成到核心，使用方法有所变化：

- **array**：`pagy_array(...)` → `pagy(:offset, ...)`
- **countless**：`pagy_countless(...)` → `pagy(:countless, ...)`
- **calendar**：`pagy_calendar(...)` → `pagy(:calendar, ...)`

### 6. 更新参数名称

```ruby
# 旧版本（符号键）
page_param: :page

# 新版本（字符串键）
page_key: 'page'
```

### 7. 清理旧配置

完成迁移后，删除 `pagy-old.rb` 文件：

```bash
rm config/initializers/pagy-old.rb
```

## 快速开始（Pagy 43）

### 基本用法

#### 控制器

```ruby
class UsersController < ApplicationController
  include Pagy::Method

  def index
    @pagy, @users = pagy(User.all)
  end
end
```

#### 视图

```erb
<!-- 基本分页导航 -->
<%= @pagy.series_nav %>

<!-- 带 JavaScript 的分页导航 -->
<%= @pagy.series_nav_js %>

<!-- 输入框导航 -->
<%= @pagy.input_nav_js %>

<!-- 分页信息 -->
<%= @pagy.info_tag %>
```

### 自定义配置

```ruby
# config/initializers/pagy.rb
Pagy.options[:items] = 20  # 每页显示 20 条记录
Pagy.options[:page_key] = 'page'  # 页面参数名称
```

### 使用 CSS 框架

Pagy 43 支持多种 CSS 框架，无需额外配置：

```erb
<!-- Bootstrap -->
<%= @pagy.series_nav(:bootstrap) %>

<!-- Bulma -->
<%= @pagy.series_nav(:bulma) %>
```

## 关键经验总结

### 升级建议

1. **优先升级**：Pagy 43 是经过全面重构的版本，建议所有新项目直接使用 Pagy 43。
2. **逐步迁移**：对于现有项目，可以按照升级指南逐步迁移。
3. **测试覆盖**：升级后务必运行测试，确保分页功能正常工作。

### 主要变化

1. **配置方式**：`Pagy::DEFAULT` → `Pagy.options`
2. **include 语句**：`Pagy::Backend` → `Pagy::Method`
3. **辅助方法**：所有辅助方法现在是 `@pagy` 的实例方法
4. **参数格式**：符号键 → 字符串键（如 `page_key: 'page'`）
5. **Extras 集成**：大多数 extras 已集成到核心，无需单独 require

### 注意事项

1. **向后兼容性**：Pagy 43 与旧版本不兼容，需要按照升级指南进行迁移。
2. **CSS 样式**：CSS 选择器和变量有变化，需要更新自定义 CSS。
3. **JavaScript**：JavaScript API 有变化，需要更新相关代码。
4. **测试**：升级后需要更新测试代码中的方法调用。

### 最佳实践

1. **使用最新版本**：始终使用 Pagy 43 或更高版本。
2. **统一配置**：在 `config/initializers/pagy.rb` 中统一配置分页选项。
3. **使用实例方法**：使用 `@pagy.series_nav` 而不是 `pagy_nav(@pagy)`。
4. **测试覆盖**：为分页功能编写测试，确保升级后功能正常。

## 相关文件

- `config/initializers/pagy.rb` - Pagy 配置文件
- `app/controllers/application_controller.rb` - 控制器基类，包含 `Pagy::Method`
- `app/helpers/application_helper.rb` - 视图辅助方法（无需 include Pagy::Frontend）
- `Gemfile` - 依赖管理文件

## 参考资料

- [Pagy 43 升级指南](https://ddnexus.github.io/pagy/guides/upgrade-guide/) - 官方升级文档
- [Pagy 43 快速开始](https://ddnexus.github.io/pagy/guides/quick-start/) - 官方使用文档
- [Pagy GitHub](https://github.com/ddnexus/pagy) - Pagy 源代码仓库
- [Pagy 文档](https://ddnexus.github.io/pagy/) - 完整文档

