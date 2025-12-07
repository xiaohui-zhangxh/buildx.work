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

  # 转换 Markdown 中的相对路径链接为绝对路径 URL
  # 将 [text](file.md) 转换为 [text](/base_path/file)
  # 将 [text](file.md#section) 转换为 [text](/base_path/file#section)
  # 只处理相对路径的 .md 文件链接，不处理外部链接、纯锚点链接等
  #
  # @param markdown [String] Markdown 内容
  # @param base_path [String] 基础路径，如 "/experiences" 或 "/tech-stack"
  # @return [String] 转换后的 Markdown 内容
  def convert_relative_links(markdown, base_path:)
    # 匹配 Markdown 链接格式：[text](path)
    # 只处理以 .md 结尾的相对路径链接（可能包含锚点）
    # 不处理：
    # - 外部链接（http://, https://, //）
    # - 纯锚点链接（#anchor，没有文件名）
    # - 绝对路径（/path）
    # - 其他相对路径（../path）
    markdown.gsub(/\[([^\]]+)\]\(([^)]+\.md(?:#[^)]*)?)\)/) do |match|
      link_text = Regexp.last_match[1]
      link_path = Regexp.last_match[2]

      # 分离文件名和锚点
      if link_path.include?("#")
        file_part, anchor_part = link_path.split("#", 2)
        anchor = "##{anchor_part}"
      else
        file_part = link_path
        anchor = ""
      end

      # 检查是否是相对路径的 .md 文件（不以 http://, https://, //, /, ../ 开头）
      # 只匹配简单的文件名格式：filename.md（允许字母、数字、点号、连字符、下划线）
      if file_part.match?(/\A[a-zA-Z0-9.\-_]+\.md\z/)
        # 提取文件名（不含扩展名）
        file_id = File.basename(file_part, ".md")
        # 转换为绝对路径 URL（保留锚点）
        "[#{link_text}](#{base_path}/#{file_id}#{anchor})"
      else
        # 保持原样（可能是外部链接或其他格式）
        match
      end
    end
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
