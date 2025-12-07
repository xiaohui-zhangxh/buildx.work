---
date: 2025-12-04
problem_type: 前端集成、UI 交互优化、性能优化
status: 已解决
tags: Stimulus、导航栏、滚动交互、性能优化、requestAnimationFrame
description: 导航栏滚动交互优化实现，使用 Stimulus 控制器实现自动隐藏/显示功能，包括性能优化技巧和用户体验优化
---

# 导航栏滚动交互优化

## 问题描述

需要实现导航栏的自动隐藏/显示功能：
- 当页面上滑时，导航栏从顶部滑出（隐藏）
- 当页面下滑时，导航栏从顶部滑入（显示）
- 在页面顶部时，导航栏始终显示

## 解决方案

### 步骤 1：创建 Stimulus 控制器

创建 `engines/buildx_core/app/javascript/controllers/navbar_controller.js`：

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 10 },
    offset: { type: Number, default: 0 }
  }

  connect() {
    this.lastScrollY = window.scrollY
    this.isVisible = true
    this.isScrolling = false

    // Initialize visible state
    this.element.classList.add("navbar-visible")
    this.element.classList.remove("navbar-hidden")

    // Throttle scroll events for better performance
    this.boundHandleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundHandleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundHandleScroll)
  }

  handleScroll() {
    if (this.isScrolling) return

    this.isScrolling = true
    requestAnimationFrame(() => {
      const currentScrollY = window.scrollY
      const scrollDifference = Math.abs(currentScrollY - this.lastScrollY)

      // Only update if scroll difference is significant
      if (scrollDifference > this.thresholdValue) {
        // Always show navbar at the top of the page
        if (currentScrollY <= 50) {
          this.show()
        } else if (currentScrollY > this.lastScrollY) {
          // Scrolling down - hide navbar
          this.hide()
        } else if (currentScrollY < this.lastScrollY) {
          // Scrolling up - show navbar
          this.show()
        }

        this.lastScrollY = currentScrollY
      }

      this.isScrolling = false
    })
  }

  show() {
    if (!this.isVisible) {
      this.element.classList.remove("navbar-hidden")
      this.element.classList.add("navbar-visible")
      this.isVisible = true
    }
  }

  hide() {
    if (this.isVisible) {
      this.element.classList.remove("navbar-visible")
      this.element.classList.add("navbar-hidden")
      this.isVisible = false
    }
  }
}
```

### 步骤 2：更新导航栏 HTML

在导航栏容器上添加 `data-controller="navbar"` 和初始类：

```erb
<div
  class="fixed top-4 left-0 right-0 z-50 flex justify-center px-4 navbar-visible"
  data-controller="navbar"
>
  <nav class="navbar ...">
    <!-- 导航栏内容 -->
  </nav>
</div>
```

### 步骤 3：添加 CSS 动画样式

创建独立的 CSS 文件 `engines/buildx_core/app/assets/stylesheets/navbar.css`：

```css
/* Navbar auto-hide animation */
.navbar-visible {
  transform: translateY(0);
  opacity: 1;
  pointer-events: auto;
}

.navbar-hidden {
  transform: translateY(calc(-100% - 1rem));
  opacity: 0;
  pointer-events: none;
}

/* Ensure smooth transitions for both transform and opacity */
[data-controller="navbar"] {
  transition: transform 0.3s ease-in-out, opacity 0.3s ease-in-out;
}
```

**注意**：将 CSS 单独存放在 `engines/buildx_core/app/assets/stylesheets/navbar.css` 中（Engine 的资产目录），Rails 的资产管道会自动加载该文件，无需手动导入。这样可以：
- 保持代码组织清晰，导航栏相关的样式与控制器、视图一起放在 Engine 中，便于统一管理
- 利用 Rails Engine 的资产自动加载机制，无需在 manifest 文件中手动引入
- 便于维护和查找相关样式，所有导航栏相关的代码都在同一个 Engine 中

## 关键经验总结

### 1. 性能优化技巧

- **使用 `requestAnimationFrame`**：将滚动事件处理放在 `requestAnimationFrame` 中，确保动画流畅
- **滚动阈值**：使用 `thresholdValue`（默认 10px）避免频繁更新，只在滚动距离足够大时才更新状态
- **防抖机制**：使用 `isScrolling` 标志防止重复处理，确保每次滚动只处理一次
- **被动事件监听**：使用 `{ passive: true }` 选项，告诉浏览器事件处理函数不会调用 `preventDefault()`，提高滚动性能

### 2. 用户体验优化

- **页面顶部始终显示**：当滚动位置 ≤ 50px 时，导航栏始终显示，方便用户访问导航
- **平滑过渡**：使用 CSS `transition` 实现平滑的显示/隐藏动画（300ms）
- **禁用交互**：隐藏时使用 `pointer-events: none`，防止用户点击隐藏的导航栏

### 3. Stimulus 控制器最佳实践

- **状态管理**：使用 `isVisible` 标志跟踪当前状态，避免重复添加/移除类
- **生命周期管理**：在 `connect()` 中初始化状态，在 `disconnect()` 中清理事件监听器
- **可配置参数**：使用 `static values` 定义可配置的参数（如 `threshold`、`offset`），提高复用性

### 4. CSS 动画最佳实践

- **组合动画**：同时使用 `transform` 和 `opacity` 实现更流畅的动画效果
- **硬件加速**：`transform` 属性会触发 GPU 加速，性能更好
- **统一过渡**：在控制器元素上统一设置过渡效果，而不是在多个类上分别设置
- **文件组织**：将组件相关的 CSS 单独存放在 Engine 的 `app/assets/stylesheets/` 目录下（如 `engines/buildx_core/app/assets/stylesheets/navbar.css`），与相关的控制器、视图放在一起，利用 Rails Engine 的资产自动加载机制，无需手动导入

### 5. 注意事项

- **固定定位**：导航栏必须使用 `fixed` 定位，才能实现向上滑出的效果
- **z-index 管理**：确保导航栏的 `z-index` 足够高，不会被其他元素遮挡
- **移动端适配**：在移动端测试时，注意触摸滚动的性能表现

## 相关文件

- `engines/buildx_core/app/javascript/controllers/navbar_controller.js`
- `engines/buildx_core/app/views/shared/_navbar.html.erb`
- `engines/buildx_core/app/assets/stylesheets/navbar.css`

## 参考资料

- [Stimulus 官方文档](https://stimulus.hotwired.dev/)
- [requestAnimationFrame MDN 文档](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)
- [CSS Transform MDN 文档](https://developer.mozilla.org/en-US/docs/Web/CSS/transform)

