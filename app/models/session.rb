class Session < ApplicationRecord
  belongs_to :user

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Check if session is active
  def active?
    active
  end

  # Check if session is current (matches Warden session)
  def current?
    Current.session&.id == id
  end

  # Terminate session (mark as inactive, don't delete for audit purposes)
  def terminate!
    update!(active: false, remember_token: nil, remember_created_at: nil)
  end

  # Get device/browser info from user_agent using UserAgent gem
  def device_info
    return "Unknown" if user_agent.blank?

    begin
      ua = UserAgent.parse(user_agent)
      # Check if mobile device (UserAgent gem's mobile? method or OS indicates mobile)
      if ua.mobile? || user_agent.match?(/Mobile|Android|iPhone|iPad|iPod/i)
        "Mobile"
      else
        # Return OS name for desktop devices
        os = ua.os.to_s
        case os
        when /Windows/i
          "Windows"
        when /Mac|OS X/i
          "Mac"
        when /Linux/i
          "Linux"
        else
          os.present? ? os : "Unknown"
        end
      end
    rescue StandardError
      # Fallback to simple detection if parsing fails
      case user_agent
      when /Mobile|Android|iPhone|iPad/
        "Mobile"
      when /Windows/
        "Windows"
      when /Mac/
        "Mac"
      when /Linux/
        "Linux"
      else
        "Unknown"
      end
    end
  end

  # Get detailed device info from user agent using UserAgent gem
  def device_info_detailed
    return "未知设备" if user_agent.blank?

    begin
      ua = UserAgent.parse(user_agent)
      browser = ua.browser || "未知浏览器"
      os = ua.os || "未知系统"

      # Determine device type
      device = if ua.mobile?
                 "移动设备"
      else
                 "桌面设备"
      end

      "#{browser} on #{os} (#{device})"
    rescue StandardError
      # Fallback to simple detection if parsing fails
      device = user_agent.match?(/Mobile|Android|iPhone|iPad/i) ? "移动设备" : "桌面设备"
      "未知浏览器 on 未知系统 (#{device})"
    end
  end

  # Check if session is recent (within last 30 days)
  def recent?
    created_at > 30.days.ago
  end

  # Remember me methods
  # Each session can have its own remember_token
  def remember_me!
    # Generate a unique remember_token
    # Retry if token already exists (very unlikely but possible)
    loop do
      self.remember_token = SecureRandom.urlsafe_base64
      break unless Session.exists?(remember_token: self.remember_token)
    end

    self.remember_created_at = Time.current
    save!(validate: false)
  end

  def remember_token_valid?(token)
    remember_token.present? && remember_token == token && remember_created_at.present? && remember_created_at > 2.weeks.ago
  end

  def remembered?
    remember_token.present? && remember_created_at.present? && remember_created_at > 2.weeks.ago
  end
end
