# frozen_string_literal: true

# Concern for rendering Markdown content to HTML
# Provides methods for processing Markdown files with front matter removal,
# list formatting fixes, and HTML conversion with syntax highlighting support.
module MarkdownRenderable
  extend ActiveSupport::Concern

  private

  # 去掉 markdown 文件顶部的 YAML front matter（配置信息）
  # 格式：以 --- 开头和结尾的 YAML 配置块
  # 例如：
  #   ---
  #   description: 描述
  #   alwaysApply: true
  #   ---
  #
  #   # Markdown 内容
  def remove_front_matter(content)
    # 检查是否以 --- 开头
    return content unless content.strip.start_with?("---")

    # 找到第二个 --- 的位置（必须在行首）
    # 使用正则表达式匹配：开头的 ---，中间的内容，结尾的 ---，然后是 markdown
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
    return content unless match

    # 返回去掉 front matter 后的内容，去掉前导和尾随空白
    match[2].strip
  end

  # 修复列表格式，确保列表项前有空行
  # Redcarpet 要求列表项前有空行才能正确识别为列表
  def fix_list_formatting(content)
    lines = content.lines
    result = []
    in_list = false

    lines.each_with_index do |line, index|
      is_list_item = line.match?(/^\s*[-*+]\s/)
      prev_line_empty = index > 0 && lines[index - 1].strip.empty?

      # 如果当前行是列表项，且上一行不是空行也不是列表项，在列表项前添加空行
      if is_list_item && !prev_line_empty && !in_list
        result << "\n" unless result.empty? || result.last.end_with?("\n\n")
        in_list = true
      elsif !is_list_item && !line.strip.empty?
        in_list = false
      end

      result << line
    end

    result.join
  end

  # 将 Markdown 内容转换为 HTML
  # 使用自定义 renderer 确保代码块有正确的 language-xxx 类名，以便 highlight.js 正确识别
  # 注意：内容来自受控的文件（不是用户输入），已经过验证和转义
  def markdown_to_html(markdown)
    # 自定义 renderer，确保代码块有正确的 language-xxx 类名
    renderer = Class.new(Redcarpet::Render::HTML) do
      def block_code(code, language)
        language_class = language ? "language-#{language}" : ""
        %(<pre><code class="#{language_class}">#{ERB::Util.html_escape(code)}</code></pre>\n)
      end
    end.new(
      filter_html: false,  # 允许 HTML（内容来自受控文件，已验证参数）
      no_images: false,
      no_links: false,
      no_styles: false,
      safe_links_only: true,  # 只允许安全的链接，防止 XSS
      with_toc_data: true,
      hard_wrap: false,
      link_attributes: { target: "_blank", rel: "noopener noreferrer" }
    )

    markdown_engine = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true,
      disable_indented_code_blocks: false,
      no_intra_emphasis: true
    )

    markdown_engine.render(markdown)
  end
end
