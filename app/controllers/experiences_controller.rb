class ExperiencesController < ApplicationController
  include MarkdownRenderable

  allow_unauthenticated_access

  EXPERIENCES_DIR = Rails.root.join("docs", "experiences").freeze

  def index
    @experiences = load_experiences
    # 优先按文档中的日期倒序排列（最新的在前）
    # 如果没有日期，则按标题排序（字母顺序）
    # 有日期的排在前面，没有日期的排在后面
    @experiences.sort_by! do |exp|
      if exp[:date]
        # 有日期的按日期倒序（最新的在前），使用负数实现倒序
        [ 0, -exp[:date].to_time.to_i, exp[:title] || "" ]
      else
        # 没有日期的按标题排序（字母顺序），排在后面
        [ 1, exp[:title] || "" ]
      end
    end
  end

  def show
    # before_action 已经处理了 format，将文件扩展名合并到 id 中
    # 例如：/experiences/highlight.js -> params[:id] = "highlight.js" (已处理)
    experience_id = params[:id]

    # 安全验证：确保 experience_id 不包含路径分隔符
    # 允许字母、数字、点号、连字符、下划线（用于文件名如 highlight.js）
    unless experience_id.match?(/\A[a-zA-Z0-9.\-_]+\z/)
      raise ActiveRecord::RecordNotFound, "经验记录不存在: #{params[:id]}"
    end

    @experience = load_experience(experience_id)

    unless @experience
      raise ActiveRecord::RecordNotFound, "经验记录不存在: #{params[:id]}"
    end

    # 设置 meta tags
    site_name = SystemConfig.installation_completed? ? (SystemConfig.get("site_name").presence || "BuildX.work") : "BuildX.work"

    # 构建 keywords：合并 problem_type 和 tags
    keywords = []
    keywords.concat(@experience[:problem_type].split(/[、,]/).map(&:strip)) if @experience[:problem_type]
    keywords.concat(@experience[:tags].split(/[、,]/).map(&:strip)) if @experience[:tags]
    keywords = keywords.uniq.join(", ").presence

    # 设置页面描述（优先使用 description，否则使用标题）
    page_description = @experience[:description] || "开发经验记录：#{@experience[:title]}"

    # 构建 meta tags 参数
    meta_tags_params = {
      title: @experience[:title],
      description: page_description,
      og: {
        title: @experience[:title],
        description: page_description,
        type: "article",
        site_name: site_name
      },
      twitter: {
        card: "summary",
        title: @experience[:title],
        description: page_description
      }
    }

    # 只有当 keywords 存在时才添加（避免空字符串）
    meta_tags_params[:keywords] = keywords if keywords

    set_meta_tags(meta_tags_params)

    # 使用 File.basename 防止路径遍历攻击
    safe_filename = File.basename("#{experience_id}.md")
    experience_file = EXPERIENCES_DIR.join(safe_filename)

    unless File.exist?(experience_file)
      raise ActiveRecord::RecordNotFound, "经验文件不存在: #{experience_file}"
    end

    # 获取文件修改时间用于缓存版本控制
    file_mtime = File.mtime(experience_file)
    file_mtime_int = file_mtime.to_i
    cache_key = "experience:#{experience_id}:#{file_mtime_int}"

    # 使用 stale? 检查请求是否过期
    if stale?(
      last_modified: file_mtime,
      etag: cache_key,
      public: true
    )
      @html_content = Rails.cache.fetch(cache_key) do
        markdown_content = File.read(experience_file)
        # 去掉 markdown 顶部的 YAML front matter（如果有）
        markdown_content = remove_front_matter(markdown_content)
        # 移除第一个标题行（因为页面顶部已经显示了标题）
        markdown_content = remove_first_heading(markdown_content)
        # 修复列表格式
        markdown_content = fix_list_formatting(markdown_content)
        # 转换相对路径链接为绝对路径 URL
        markdown_content = convert_relative_links(markdown_content, base_path: "/experiences")
        markdown_to_html(markdown_content)
      end
    end
  end

  private

  def load_experiences
    experiences = []

    Dir.glob(EXPERIENCES_DIR.join("*.md")).each do |file_path|
      next if File.basename(file_path) == "README.md"

      # 获取完整的文件名（不含扩展名）
      # 例如：highlight.js.md -> highlight.js
      id = File.basename(file_path, ".md")
      experience = load_experience(id)
      experiences << experience if experience
    end

    experiences
  end

  def load_experience(id)
    # 安全验证：确保 id 不包含路径分隔符
    unless id.match?(/\A[a-zA-Z0-9.\-_]+\z/)
      return nil
    end

    # 使用 File.basename 防止路径遍历攻击
    safe_filename = File.basename("#{id}.md")
    file_path = EXPERIENCES_DIR.join(safe_filename)
    return nil unless File.exist?(file_path)

    content = File.read(file_path)

    # 解析元数据
    metadata = parse_metadata(content)

    {
      id: id,
      title: metadata[:title] || id.humanize,
      date: metadata[:date],
      problem_type: metadata[:problem_type],
      description: metadata[:description],
      tags: metadata[:tags],
      file_path: file_path,
      created_at: File.ctime(file_path)
    }
  end

  def parse_metadata(content)
    metadata = {}

    # 从 YAML frontmatter 中提取元数据
    if content.strip.start_with?("---")
      frontmatter_match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
      if frontmatter_match
        frontmatter_content = frontmatter_match[1]
        markdown_content = frontmatter_match[2]

        # 解析 YAML frontmatter
        begin
          yaml_data = YAML.safe_load(frontmatter_content, permitted_classes: [ Date ], aliases: true)
          if yaml_data.is_a?(Hash)
            # 提取日期
            if yaml_data["date"]
              begin
                metadata[:date] = Date.parse(yaml_data["date"].to_s)
              rescue Date::Error
                # 忽略日期解析错误
              end
            end

            # 提取问题类型
            metadata[:problem_type] = yaml_data["problem_type"]&.to_s

            # 提取状态（如果需要）
            metadata[:status] = yaml_data["status"]&.to_s

            # 提取描述
            metadata[:description] = yaml_data["description"]&.to_s

            # 提取标签
            metadata[:tags] = yaml_data["tags"]&.to_s
          end
        rescue Psych::SyntaxError, Psych::DisallowedClass => e
          # YAML 解析失败，记录警告
          Rails.logger.warn("Failed to parse YAML frontmatter: #{e.message}")
        end

        # 从 Markdown 内容中提取标题（跳过 frontmatter）
        title_match = markdown_content.match(/^#\s+(.+)$/)
        metadata[:title] = title_match[1].strip if title_match
      end
    end

    # 如果没有 frontmatter 或 frontmatter 中没有标题，尝试从整个内容中提取标题
    unless metadata[:title]
      title_match = content.match(/^#\s+(.+)$/)
      metadata[:title] = title_match[1].strip if title_match
    end

    metadata
  end

  def remove_first_heading(content)
    # 移除第一个 # 开头的标题行（一级标题）
    # 匹配：行首的 # + 空白 + 标题内容 + 换行
    lines = content.lines
    # 找到第一个以 # 开头的行（一级标题）
    first_heading_index = lines.index { |line| line.match?(/^#\s+/) }
    return content unless first_heading_index

    # 移除该行，如果下一行是空行也一起移除
    result = lines.dup
    result.delete_at(first_heading_index)
    # 如果移除后第一行是空行，也移除它
    result.shift if result.first&.strip&.empty?
    result.join
  end
end
