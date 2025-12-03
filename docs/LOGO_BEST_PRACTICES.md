# Logo 使用最佳实践

> 本文档说明如何在 BuildX.work 项目中使用 Logo，包括文件存放、响应式显示、向后兼容性等最佳实践。

## 📋 核心原则

### 1. Logo 文件存放位置

**必须存放在 `app/assets/images/` 目录**，符合 Rails Asset Pipeline 规范。

```
app/assets/images/
├── logo.svg              # 主 Logo（可选，用于首页等大尺寸展示）
├── logo-icon.svg         # 图标版本（必须，用于导航栏）
├── logo-horizontal.svg   # 横向版本（可选，用于导航栏桌面端）
├── icon.svg             # Favicon (SVG)（必须）
└── icon.png             # Favicon (PNG)（必须，用于兼容性）
```

**为什么放在 `app/assets/images/`**：
- 符合 Rails Asset Pipeline 规范
- 通过 `image_tag` 或 `asset_path` 自动引用
- 支持资源预编译和优化
- 便于版本控制和缓存管理

### 2. Logo 文件要求

#### 必须文件

- **`logo-icon.svg`** - 图标版本
  - 尺寸：建议 64x64px 或更大（SVG 可缩放）
  - 用途：导航栏、小尺寸显示、移动端
  - 要求：简洁、清晰、易于识别

- **`icon.svg`** - Favicon (SVG)
  - 尺寸：建议 64x64px 或更大
  - 用途：浏览器标签页图标
  - 要求：与 `logo-icon.svg` 相同或简化版本

- **`icon.png`** - Favicon (PNG)
  - 尺寸：建议 32x32px、64x64px、128x128px 等多尺寸
  - 用途：浏览器标签页图标（兼容性）
  - 要求：与 `icon.svg` 相同

#### 可选文件

- **`logo.svg`** - 主 Logo
  - 尺寸：建议 200x200px 或更大
  - 用途：首页、关于页面、品牌展示
  - 要求：完整设计，包含装饰元素

- **`logo-horizontal.svg`** - 横向版本
  - 尺寸：建议 300x80px 或更大
  - 用途：导航栏桌面端、页眉
  - 要求：包含图标 + 文字，适合横向布局

## 🎨 导航栏 Logo 显示最佳实践

### 基础实现（推荐）

**适用于**：所有项目，向后兼容

```erb
<!-- Brand Logo and Name -->
<%= link_to root_path, class: "btn btn-ghost px-3 hover:bg-base-200 flex items-center gap-2 rounded-full" do %>
  <!-- Mobile: Icon only -->
  <%= image_tag "logo-icon.svg", alt: site_name, class: "h-7 w-7 sm:hidden" %>

  <!-- Desktop: Icon + text -->
  <%= image_tag "logo-icon.svg", alt: site_name, class: "h-7 w-7 hidden sm:block" %>

  <span class="text-lg font-bold hidden sm:inline text-base-content">
    <%= site_name %>
  </span>
<% end %>
```

**特点**：
- ✅ 移动端：只显示图标，节省空间
- ✅ 桌面端：显示图标 + 文字，品牌清晰
- ✅ 向后兼容：不依赖可选文件
- ✅ 简单可靠：所有项目都可以使用

### 高级实现（可选）

**适用于**：有横向 Logo 的项目

```erb
<!-- Brand Logo and Name -->
<%= link_to root_path, class: "btn btn-ghost px-3 hover:bg-base-200 flex items-center gap-2 rounded-full" do %>
  <!-- Mobile: Icon only -->
  <%= image_tag "logo-icon.svg", alt: site_name, class: "h-7 w-7 sm:hidden" %>

  <!-- Desktop: Horizontal logo -->
  <%= image_tag "logo-horizontal.svg", alt: site_name, class: "h-8 hidden sm:block" %>
<% end %>
```

**注意**：使用此实现时，项目必须确保 `logo-horizontal.svg` 文件存在。如果文件不存在，Rails 会在开发环境报错。

**特点**：
- ✅ 移动端：只显示图标
- ✅ 桌面端：显示横向 Logo
- ⚠️ 依赖可选文件：需要项目有 `logo-horizontal.svg`

## 📐 响应式设计规范

### 断点使用

- **移动端**（`< 640px`）：只显示图标
  - 使用 `sm:hidden` 类
  - 图标尺寸：`h-7 w-7`（28px）

- **桌面端**（`>= 640px`）：显示图标 + 文字 或 横向 Logo
  - 使用 `hidden sm:block` 类
  - 图标尺寸：`h-7 w-7`（28px）或 `h-8`（32px，横向 Logo）

### 尺寸建议

| 使用场景 | 文件 | 建议尺寸 | CSS 类 |
|---------|------|---------|--------|
| 导航栏移动端 | `logo-icon.svg` | 64x64px | `h-7 w-7` |
| 导航栏桌面端 | `logo-icon.svg` + 文字 | 64x64px | `h-7 w-7` |
| 导航栏桌面端（横向） | `logo-horizontal.svg` | 300x80px | `h-8` |
| 首页展示 | `logo.svg` | 200x200px | `h-24 w-24 md:h-32 md:w-32` |
| Favicon | `icon.svg` / `icon.png` | 64x64px | - |

## 🔄 向后兼容性

### 原则

1. **基础实现必须工作**：即使项目只有 `logo-icon.svg`，导航栏也必须正常显示
2. **可选功能优雅降级**：如果项目没有横向 Logo，自动回退到图标+文字
3. **不强制要求**：不要求所有项目都有完整的 Logo 文件集

### 实现建议

**推荐方式**：使用基础实现（图标+文字），简单可靠，所有项目都可以使用。

**高级方式**：如果项目有横向 Logo，可以在业务项目中覆盖导航栏，使用高级实现。

## 💡 使用场景示例

### 场景 1：基础项目（只有图标）

**文件**：
- `logo-icon.svg` ✅
- `icon.svg` ✅
- `icon.png` ✅

**导航栏实现**：
```erb
<!-- 使用基础实现 -->
<%= image_tag "logo-icon.svg", alt: site_name, class: "h-7 w-7 sm:hidden" %>
<%= image_tag "logo-icon.svg", alt: site_name, class: "h-7 w-7 hidden sm:block" %>
<span class="text-lg font-bold hidden sm:inline text-base-content">
  <%= site_name %>
</span>
```

### 场景 2：完整品牌项目（有横向 Logo）

**文件**：
- `logo-icon.svg` ✅
- `logo-horizontal.svg` ✅
- `logo.svg` ✅
- `icon.svg` ✅
- `icon.png` ✅

**导航栏实现**：
- 基础平台：使用基础实现（图标+文字）
- 业务项目：可以覆盖导航栏，使用高级实现（横向 Logo）

### 场景 3：首页 Logo 展示

**实现**：
```erb
<div class="mb-4">
  <%= image_tag "logo.svg", alt: site_name, class: "h-24 w-24 md:h-32 md:w-32 drop-shadow-2xl" %>
</div>
```

## 🛠️ 实现建议

### 1. 基础平台实现

**文件**：`engines/buildx_core/app/views/shared/_navbar.html.erb`

**使用基础实现**（图标+文字）：
- 简单可靠
- 向后兼容
- 不依赖可选文件
- 所有项目都可以使用

### 2. 业务项目覆盖

如果业务项目有横向 Logo，可以在业务项目中覆盖导航栏：

**文件**：`app/views/shared/_navbar.html.erb`

**使用高级实现**（横向 Logo）：
- 覆盖 Engine 中的导航栏
- 使用横向 Logo 显示
- 如果没有横向 Logo，可以回退到基础实现

### 3. 业务项目覆盖实现

如果业务项目有横向 Logo，可以直接在业务项目中覆盖导航栏，使用横向 Logo：

**文件**：`app/views/shared/_navbar.html.erb`

**实现**：直接使用横向 Logo，确保文件存在即可。

## 📝 检查清单

### 创建新项目时

- [ ] 创建 `logo-icon.svg`（必须）
- [ ] 创建 `icon.svg`（必须）
- [ ] 创建 `icon.png`（必须）
- [ ] 创建 `logo.svg`（可选，用于首页）
- [ ] 创建 `logo-horizontal.svg`（可选，用于导航栏桌面端）

### 在导航栏中使用

- [ ] 移动端显示图标（`sm:hidden`）
- [ ] 桌面端显示图标+文字或横向 Logo（`hidden sm:block`）
- [ ] 使用 `image_tag` 引用 Logo 文件
- [ ] 添加 `alt` 属性（使用 `site_name`）
- [ ] 确保向后兼容（不依赖可选文件）

### 在布局文件中使用

- [ ] 使用 `asset_path` 引用 Favicon
- [ ] 同时提供 SVG 和 PNG 格式
- [ ] 添加 Apple Touch Icon（如需要）

## 🔗 相关文档

- [资源管理规范](../.cursor/rules/assets-management.mdc) - Logo 文件存放规范
- [开发者指南](DEVELOPER_GUIDE.md) - 技术决策和架构设计

---

**创建时间**：2025-12-03  
**状态**：✅ 已完成  
**版本**：v1.0

