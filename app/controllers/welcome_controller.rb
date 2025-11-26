class WelcomeController < ApplicationController
  allow_unauthenticated_access

  def index
    # 首页标题使用 "站点名 | 核心价值描述" 格式，参考飞书等大型网站的最佳实践
    # 格式：品牌名 | 核心价值描述（类似 "飞书 | AI 时代先进生产力平台"）
    site_name = if SystemConfig.installation_completed?
      SystemConfig.get("site_name").presence || "BuildX.work"
    else
      "BuildX.work"
    end

    tagline = SystemConfig.installation_completed? && SystemConfig.get("site_tagline").presence ||
              "企业级 Ruby on Rails 应用脚手架"

    # 同时设置 site 和 title，覆盖默认值，确保格式为 "站点名 | tagline"
    # 注意：设置 reverse: false 确保格式是 site | title，而不是 title | site
    set_meta_tags(
      site: site_name + " - 官网",
      title: tagline,
      reverse: false
      # description 和 keywords 使用默认值（已在 ApplicationController 中设置）
    )
  end
end
