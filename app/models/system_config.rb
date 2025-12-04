class SystemConfig < ApplicationRecord
  validates :key, presence: true
  validates :key, format: { with: /\A[a-z_][a-z0-9_]*\z/, message: "must be lowercase letters, numbers, and underscores only" }

  after_save_commit -> { Current.values[key.to_sym] = value }
  after_destroy_commit -> { Current.values.delete(key.to_sym) }

  # 把数据集合缓存在当前请求中，减少多次数据查询
  class Current < ActiveSupport::CurrentAttributes
    attribute :values, default: -> { {} }

    def get(key)
      key = key.to_sym
      if values.key?(key)
        values[key]
      else
        values[key] = SystemConfig.find_by(key: key)&.value
      end
    end
  end

  class << self
    def get(key)
      Current.get(key)
    end

    def set(key, value, description: nil, category: nil)
      config = create_or_find_by!(key: key) do |c|
        c.value = value.to_s.strip
        c.description = description.to_s.strip if description
        c.category = category.to_s.strip if category
      end

      # Update attributes if values changed
      needs_update = config.value != value.to_s.strip ||
                     (description && config.description != description.to_s.strip) ||
                     (category && config.category != category.to_s.strip)

      if needs_update
        config.value = value.to_s.strip
        config.description = description.to_s.strip if description
        config.category = category.to_s.strip if category
        config.save!
      end

      config
    end

    # 确保配置存在，但不覆盖已存在的值
    # 只更新 description 和 category（如果提供）
    # 如果配置不存在，使用默认值创建
    def ensure_config(key, default_value: "", description: nil, category: nil)
      config = find_or_initialize_by(key: key)

      # 如果配置不存在，设置默认值
      if config.new_record?
        config.value = default_value.to_s.strip
      end
      # 如果配置已存在，保留原有 value，不覆盖

      # 更新 description 和 category（如果提供且不同）
      needs_update = false
      if description && config.description != description.to_s.strip
        config.description = description.to_s.strip
        needs_update = true
      end
      if category && config.category != category.to_s.strip
        config.category = category.to_s.strip
        needs_update = true
      end

      config.save! if needs_update || config.new_record?

      config
    end

    def installation_completed?
      get("installation_completed") == "1"
    end
  end
end
