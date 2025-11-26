class TechStackController < ApplicationController
  include MarkdownRenderable

  allow_unauthenticated_access

  # 技术栈规则文件映射
  TECH_STACK_RULES = {
    "action-policy" => {
      name: "Action Policy",
      icon: nil,  # 使用 SVG 图标
      description: "授权框架"
    },
    "authentication" => {
      name: "认证系统",
      icon: nil,  # 使用 SVG 图标
      description: "Warden + Rails 8 Authentication"
    },
    "daisy-ui" => {
      name: "DaisyUI",
      icon: "daisyui-logo.svg",
      description: "Tailwind CSS 组件库"
    }
  }.freeze

  def show
    @tech_stack = params[:id]
    @rule_config = TECH_STACK_RULES[@tech_stack]

    unless @rule_config
      raise ActiveRecord::RecordNotFound, "技术栈规则不存在: #{@tech_stack}"
    end

    rule_file = Rails.root.join(".cursor", "rules", "#{@tech_stack}.mdc")

    unless File.exist?(rule_file)
      raise ActiveRecord::RecordNotFound, "规则文件不存在: #{rule_file}"
    end

    # 获取文件修改时间用于缓存版本控制
    file_mtime = File.mtime(rule_file)
    file_mtime_int = file_mtime.to_i
    cache_key = "tech_stack_rule:#{@tech_stack}:#{file_mtime_int}"

    # 使用 stale? 检查请求是否过期
    # 只有在请求过期时才执行代码块，避免不必要的文件读取和渲染
    if stale?(
      last_modified: file_mtime,
      etag: cache_key,
      public: true
    )
      # 这些代码只在请求过期时执行（文件已更新或首次请求）
      # 如果请求是新鲜的（返回 304），不会执行这里的代码
      @html_content = Rails.cache.fetch(cache_key) do
        markdown_content = File.read(rule_file)
        # 去掉 markdown 顶部的 YAML front matter（配置信息）
        markdown_content = remove_front_matter(markdown_content)
        # 修复列表格式，确保列表项前有空行
        markdown_content = fix_list_formatting(markdown_content)
        markdown_to_html(markdown_content)
      end
    end
    # 如果请求是新鲜的，自动返回 304，上面的代码不会执行
  end

  private
end
