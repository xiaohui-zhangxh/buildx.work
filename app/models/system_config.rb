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

    # Ensure config exists with default value, but don't update if it already exists
    def ensure_config(key, default_value:, description: nil, category: nil)
      config = find_by(key: key)

      if config.nil?
        attrs = {
          key: key,
          value: default_value.to_s.strip
        }
        attrs[:description] = description.to_s.strip if description
        attrs[:category] = category.to_s.strip if category
        create!(attrs)
      else
        config
      end
    end

    def installation_completed?
      get("installation_completed") == "1"
    end
  end
end
