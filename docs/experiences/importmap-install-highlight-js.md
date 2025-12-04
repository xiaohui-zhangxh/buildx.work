---
date: 2025-11-25
problem_type: 前端集成、Importmap、第三方库管理
status: 已解决
---

# Highlight.js 集成问题与解决方案

## 问题描述

在 Rails 8 项目中使用 `highlight.js` 为 Markdown 渲染的代码块添加语法高亮功能时，遇到了以下问题：

### 根源问题

**`bin/importmap pin highlight.js` 的局限性**：
- `bin/importmap pin` 命令只会下载一个入口文件（通常是包的 `index.js` 或主文件）
- 但 `highlight.js` 是一个模块化库，主文件会引用其他内部模块（如 `lib/core.js`、`lib/languages/*.js` 等）
- 这些被引用的模块文件不会被自动下载，导致运行时出现 "模块找不到" 的错误

**结论**：对于像 `highlight.js` 这样具有复杂依赖关系的模块化库，**必须手动集成**，不能依赖 `bin/importmap pin` 自动下载。

### 具体表现

1. **模块加载失败**：`highlight.js/lib/core.js` 返回 404 错误
2. **Importmap 路径配置问题**：无法正确解析本地文件路径
3. **CommonJS vs ES Module 兼容性**：从 npm 下载的文件是 CommonJS 格式，需要转换为 ES Module
4. **初始化时机问题**：代码高亮在页面加载时未正确执行

## 问题原因分析

### 1. Importmap pin 命令的局限性（根本原因）

**问题**：`bin/importmap pin highlight.js` 只会下载包的入口文件，不会下载该文件引用的其他模块。

**示例**：

```bash
# 执行命令
bin/importmap pin highlight.js

# 结果：只下载了 highlight.js 的主文件
# 但 highlight.js 主文件会 import 其他模块：
# - lib/core.js
# - lib/languages/ruby.js
# - lib/languages/javascript.js
# 等等...
```

**为什么会出现这个问题**：
- Importmap 的设计理念是"按需加载"，只下载直接引用的文件
- 它不会递归分析依赖关系并下载所有相关文件
- 对于模块化程度高的库（如 highlight.js），需要手动下载所有依赖文件

**解决方案**：必须手动集成，下载所有需要的模块文件。

### 2. Importmap 路径配置错误

**错误配置**：

```ruby
# config/importmap.rb
pin "highlight.js/lib/core", to: "highlight.js/lib/core.js"
```

**问题**：Importmap 无法正确解析 `vendor/javascript/` 目录下的嵌套路径。

### 3. 文件格式不兼容

从 npm 包下载的 `lib/core.js` 和 `lib/index.js` 是 CommonJS 格式（使用 `module.exports`），而浏览器需要 ES Module 格式（使用 `export`）。

### 4. 初始化方式不当

最初尝试在独立的 JavaScript 文件中初始化，但存在以下问题：
- Turbo 导航时未重新初始化
- DOM 加载时机不确定
- 代码块选择器不准确

## 解决方案

### 1. 使用 JSPM CDN 下载 ES Module 版本

使用 `jspm.io` CDN 下载 ES Module 格式的文件，而不是从 npm 包下载 CommonJS 版本：

```bash
# 创建目录结构
mkdir -p vendor/javascript/highlight.js/lib/languages

# 下载 core.js（ES Module 格式）
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/core.js" -o vendor/javascript/highlight.js/lib/core.js

# 下载语言文件（ES Module 格式）
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/ruby.js" -o vendor/javascript/highlight.js/lib/languages/ruby.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/javascript.js" -o vendor/javascript/highlight.js/lib/languages/javascript.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/bash.js" -o vendor/javascript/highlight.js/lib/languages/bash.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/yaml.js" -o vendor/javascript/highlight.js/lib/languages/yaml.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/json.js" -o vendor/javascript/highlight.js/lib/languages/json.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/xml.js" -o vendor/javascript/highlight.js/lib/languages/xml.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/css.js" -o vendor/javascript/highlight.js/lib/languages/css.js
curl -L "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/sql.js" -o vendor/javascript/highlight.js/lib/languages/sql.js
```

### 2. 配置 Importmap

在 `config/importmap.rb` 中配置本地文件路径：

```ruby
# Highlight.js for syntax highlighting (本地文件，存放在 vendor/javascript/highlight.js)
pin "highlight.js/lib/core", to: "highlight.js/lib/core.js"
pin "highlight.js/lib/languages/ruby", to: "highlight.js/lib/languages/ruby.js"
pin "highlight.js/lib/languages/javascript", to: "highlight.js/lib/languages/javascript.js"
pin "highlight.js/lib/languages/bash", to: "highlight.js/lib/languages/bash.js"
pin "highlight.js/lib/languages/yaml", to: "highlight.js/lib/languages/yaml.js"
pin "highlight.js/lib/languages/json", to: "highlight.js/lib/languages/json.js"
pin "highlight.js/lib/languages/xml", to: "highlight.js/lib/languages/xml.js"
pin "highlight.js/lib/languages/css", to: "highlight.js/lib/languages/css.js"
pin "highlight.js/lib/languages/sql", to: "highlight.js/lib/languages/sql.js"
```

### 3. 使用 Stimulus Controller 初始化

创建 `app/javascript/controllers/highlight_controller.js`：

```javascript
import { Controller } from "@hotwired/stimulus"
// Highlight.js syntax highlighting
import hljs from "highlight.js/lib/core"
import ruby from "highlight.js/lib/languages/ruby"
import javascript from "highlight.js/lib/languages/javascript"
import bash from "highlight.js/lib/languages/bash"
import yaml from "highlight.js/lib/languages/yaml"
import json from "highlight.js/lib/languages/json"
import xml from "highlight.js/lib/languages/xml"
import css from "highlight.js/lib/languages/css"
import sql from "highlight.js/lib/languages/sql"

// Register languages
hljs.registerLanguage("ruby", ruby)
hljs.registerLanguage("javascript", javascript)
hljs.registerLanguage("bash", bash)
hljs.registerLanguage("yaml", yaml)
hljs.registerLanguage("json", json)
hljs.registerLanguage("xml", xml)
hljs.registerLanguage("css", css)
hljs.registerLanguage("sql", sql)

// Connects to data-controller="highlight"
export default class extends Controller {
  static values = {
    selector: {
      type: String,
      default: "pre code",
    }
  }

  connect() {
    const selector = this.selectorValue;
    const elements = this.element.querySelectorAll(selector);
    elements.forEach((element) => hljs.highlightElement(element));
  }
}
```

### 4. 在视图中使用

在 `app/views/tech_stack/show.html.erb` 中：

```erb
<div class="markdown-body" data-controller="highlight">
  <%= raw @html_content %>
</div>
```

**关键点**：
- 使用 `data-controller="highlight"` 绑定 Stimulus controller
- Controller 会在元素连接时自动执行 `connect()` 方法
- 自动处理 Turbo 导航（Stimulus 会自动重新连接）

### 5. 样式文件配置

样式文件存放在 `vendor/stylesheets/highlight/`，包装文件在 `app/assets/stylesheets/highlight.css`：

```css
/*
 * This is a wrapper file for highlight.js styles.
 * The original highlight.js style files are located in `vendor/stylesheets/highlight/`.
 *
 * Light theme: vendor/stylesheets/highlight/github.css
 * Dark theme: vendor/stylesheets/highlight/github-dark.css
 */
```

## 最终文件结构

```
vendor/
├── javascript/
│   └── highlight.js/
│       └── lib/
│           ├── core.js
│           └── languages/
│               ├── ruby.js
│               ├── javascript.js
│               ├── bash.js
│               ├── yaml.js
│               ├── json.js
│               ├── xml.js
│               ├── css.js
│               └── sql.js
└── stylesheets/
    └── highlight/
        ├── github.css
        └── github-dark.css

app/
├── assets/
│   └── stylesheets/
│       └── highlight.css  # 包装文件，合并 light/dark 主题
└── javascript/
    └── controllers/
        └── highlight_controller.js  # Stimulus controller
```

## 关键经验总结

### 1. Importmap pin 命令的局限性 ⚠️

**核心问题**：`bin/importmap pin` 只会下载入口文件，不会递归下载依赖模块。

**判断标准**：如果遇到以下情况，需要手动集成：
- 库文件引用了其他内部模块（如 `import ... from './lib/core.js'`）
- 运行时出现 "模块找不到" 或 404 错误
- 库采用模块化设计，有多个子模块文件

**解决方案**：
1. 分析库的依赖关系，确定需要哪些文件
2. 手动下载所有需要的模块文件到 `vendor/javascript/`
3. 在 `config/importmap.rb` 中为每个模块配置 pin

**适用场景**：
- ✅ 简单的单文件库：可以使用 `bin/importmap pin`
- ❌ 复杂的模块化库（如 highlight.js、lodash-es）：必须手动集成

### 2. Importmap 路径配置

- Importmap 会自动查找 `vendor/javascript/` 目录
- 路径配置时不需要包含 `vendor/javascript/` 前缀
- 使用相对路径，如 `"highlight.js/lib/core.js"`

### 3. ES Module vs CommonJS

- **浏览器环境**：必须使用 ES Module 格式（`export`/`import`）
- **npm 包**：通常提供 CommonJS 格式（`module.exports`/`require`）
- **解决方案**：使用 `jspm.io` CDN 获取 ES Module 版本，或手动转换

### 4. Stimulus Controller 的优势

- **自动生命周期管理**：`connect()` 在元素插入 DOM 时自动调用
- **Turbo 兼容**：自动处理 Turbo 导航，无需手动监听事件
- **作用域隔离**：只在绑定的元素内查找代码块，避免冲突

### 5. 第三方库文件管理

根据项目规范（`docs/DEVELOPER_GUIDE.md`）：
- **原始文件**：存放在 `vendor/` 目录
- **包装文件**：存放在 `app/assets/` 目录，并注明原始文件位置

## 相关文件

- `config/importmap.rb` - Importmap 配置
- `app/javascript/controllers/highlight_controller.js` - Stimulus controller
- `app/views/tech_stack/show.html.erb` - 视图文件
- `app/assets/stylesheets/highlight.css` - 样式包装文件
- `vendor/javascript/highlight.js/` - 原始 JavaScript 文件
- `vendor/stylesheets/highlight/` - 原始样式文件

## 参考资料

- [Highlight.js 官方文档](https://highlightjs.org/)
- [Rails Importmap 文档](https://github.com/rails/importmap-rails)
- [Stimulus 文档](https://stimulus.hotwired.dev/)
- [JSPM CDN](https://jspm.org/)

