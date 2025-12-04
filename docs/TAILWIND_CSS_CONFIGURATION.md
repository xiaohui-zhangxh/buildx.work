# Tailwind CSS 配置管理规范

> 本文档说明如何管理基础平台和业务项目的 Tailwind CSS 配置，确保在合并代码时不会产生冲突。

## 📋 问题背景

在 BuildX.work 架构中：
- **基础平台**（`engines/buildx_core`）：提供基础设施功能
- **业务项目**（fork 项目）：基于基础平台开发的具体业务

当基础平台和业务项目都需要配置 Tailwind CSS 时，需要确保：
1. 配置不会冲突
2. 基础平台的更新不会覆盖业务项目的自定义配置
3. 业务项目的配置可以覆盖或扩展基础平台的配置

## 🎯 推荐方案：分离配置文件 + 项目特定的 Theme 名称

**核心思想**：使用项目特定的 theme 名称，完全避免与 upstream 的配置冲突。

### 文件结构

```
app/assets/tailwind/
├── application.css    # 主配置文件（导入 Tailwind、插件、主题、自定义样式）
├── plugins/           # 插件配置目录
│   ├── index.css      # 插件入口文件
│   ├── daisyui.css    # DaisyUI 插件配置
│   └── typography.css  # Typography 插件配置
├── themes/            # 主题配置目录
│   ├── index.css      # 主题入口文件
│   ├── lofi.css       # 浅色主题（light）
│   └── dracula.css    # 深色主题（dark）
└── customs/           # 自定义样式目录
    └── index.css      # 自定义样式
```

### 实现方式

**1. 主配置文件**（`app/assets/tailwind/application.css`）

```css
@import "tailwindcss";
@import "./plugins";
@import "./themes";
@import "./customs";
```

**2. 插件配置**（`app/assets/tailwind/plugins/index.css`）

```css
@import "./daisyui";
@import "./typography";
```

**3. 主题配置**（`app/assets/tailwind/themes/index.css`）

```css
@import "./lofi.css";   /* light */
@import "./dracula.css"; /* dark */
```

**4. 主题文件示例**（`app/assets/tailwind/themes/lofi.css`）

```css
@plugin "daisyui/theme" {
    name: "lofi"; /* 项目特定的 theme 名称 */
    default: true;
    prefersdark: false;
    color-scheme: "light";
    /* ... 自定义配置 ... */
}
```

**5. Theme Controller**（`app/javascript/controllers/theme_controller.js`）

使用项目特定的 theme 名称：

```javascript
// 使用项目特定的 theme 名称
const savedTheme = localStorage.getItem("theme") || "lofi"
html.setAttribute("data-theme", savedTheme)
```

### 优点

- ✅ **完全避免冲突**：
  - 使用项目特定的 theme 名称（如 `lofi`, `dracula`）
  - 即使 upstream 添加了 `light` 和 `dark` theme，也不会冲突
- ✅ **完全隔离配置**：
  - 主题配置在独立的 `themes/` 目录中
  - 自定义样式在独立的 `customs/` 目录中
  - 即使 upstream 更新了 `application.css`，也不会影响项目特定的配置
- ✅ **自由自定义**：可以完全自定义主题，无需担心覆盖问题
- ✅ **易于维护**：配置职责清晰，易于理解和维护
- ✅ **未来兼容**：如果 upstream 添加了默认 theme，可以选择使用或忽略

### 当前实现（基础平台）

基础平台已采用此方案：
- **文件结构**：
  - `application.css` - 主配置文件
  - `plugins/` - 插件配置（DaisyUI、Typography）
  - `themes/` - 主题配置（lofi、dracula）
  - `customs/` - 自定义样式
- **Theme 名称**：`lofi`（默认）、`dracula`

**优势**：
- ✅ 即使 upstream 更新了 `application.css`，也不会影响主题配置
- ✅ 配置职责清晰，易于维护
- ✅ 可以独立更新主题和自定义样式

## 📝 配置管理规范

### 基础平台配置规范

**文件位置**：`app/assets/tailwind/`

**应该包含**：
- ✅ Tailwind CSS 导入
- ✅ DaisyUI 插件配置
- ✅ Tailwind Typography 插件配置
- ✅ 基础主题配置（使用项目特定的名称）
- ✅ 通用样式（如 prose 样式）

**不应该包含**：
- ❌ 业务特定的主题配置
- ❌ 业务特定的自定义样式
- ❌ 业务特定的颜色方案

### 业务项目配置规范

**文件位置**：`app/assets/tailwind/application.css`

**应该包含**：
- ✅ 导入基础平台配置（如果存在）
- ✅ 业务项目的自定义主题配置（使用项目特定的 theme 名称）
- ✅ 业务项目的自定义样式
- ✅ 业务特定的扩展样式

**配置优先级**：
1. 业务项目的配置（最高优先级）
2. 基础平台的配置（较低优先级）

## 🔄 合并冲突处理

### 场景 1：基础平台更新主题配置

**问题**：基础平台更新了默认主题，但业务项目有自己的主题配置。

**解决方案**：
- 业务项目的配置会覆盖基础平台的配置
- 如果需要使用基础平台的新配置，业务项目需要手动更新

### 场景 2：基础平台添加新的通用样式

**问题**：基础平台添加了新的通用样式（如 `.prose` 样式），业务项目也有自己的样式。

**解决方案**：
- 如果样式类名不同，不会冲突
- 如果样式类名相同，业务项目的样式会覆盖基础平台的样式
- 建议：基础平台使用命名空间（如 `.buildx-prose`），业务项目使用自己的命名空间（如 `.project-prose`）

### 场景 3：基础平台和业务项目都定义了相同的主题名称

**问题**：基础平台定义了 `lofi` 主题，业务项目也定义了 `lofi` 主题。

**解决方案**：
- **推荐**：业务项目使用不同的主题名称（如 `project-light`），完全避免冲突
- 如果使用相同名称，后定义的主题会覆盖先定义的主题
- 业务项目的主题配置在基础配置之后，会自动覆盖

## ✅ 最佳实践

### 1. 使用命名空间

**基础平台**：
```css
/* 使用 .buildx- 前缀 */
.buildx-prose {
  /* ... */
}
```

**业务项目**：
```css
/* 使用项目特定的前缀 */
.project-custom {
  /* ... */
}
```

### 2. 文档化配置

在配置文件中添加注释，说明：
- 配置的来源（基础平台或业务项目）
- 配置的用途
- 配置的依赖关系

```css
/* ============================================
   基础平台配置（来自 engines/buildx_core）
   ============================================ */
@import "../../../engines/buildx_core/app/assets/tailwind/base.css";

/* ============================================
   业务项目配置（项目特定）
   ============================================ */
@plugin "daisyui/theme" {
    name: "project-light"; /* 项目特定的 theme 名称 */
    /* 业务项目的自定义主题 */
}
```

### 3. 使用项目特定的 Theme 名称

**推荐做法**：
- 业务项目使用项目特定的 theme 名称（如 `project-light`, `project-dark`）
- 完全避免与 upstream 的配置冲突
- 即使 upstream 添加了默认 theme，也不会影响业务项目

**示例**：
```css
/* 业务项目使用项目特定的名称 */
@plugin "daisyui/theme" {
    name: "project-light"; /* 而不是 "light" */
    /* ... */
}
```

### 4. 版本控制

- 基础平台的配置变更应该在 CHANGELOG 中记录
- 业务项目的配置变更应该在项目文档中记录
- 重大配置变更应该提供迁移指南

## 🔗 相关文档

- [Tailwind CSS 4 文档](https://tailwindcss.com/docs)
- [DaisyUI 5 文档](https://daisyui.com/docs)
- [Rails 资源管理](https://guides.rubyonrails.org/asset_pipeline.html)

---

**创建时间**：2025-12-03  
**最后更新**：2025-12-04  
**状态**：✅ 方案已确定并实施
