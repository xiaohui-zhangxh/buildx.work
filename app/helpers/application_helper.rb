module ApplicationHelper
  # Format time for display with automatic format selection based on time distance
  # - Today: shows time only (e.g., "14:30")
  # - This week: shows weekday and time (e.g., "Monday 14:30" or "周一 14:30")
  # - This month: shows date and time (e.g., "Dec 15 14:30" or "12月15日 14:30")
  # - Longer: shows full date (e.g., "2024-12-15 14:30")
  def format_time(time)
    return "" if time.nil?

    now = Time.current
    today = now.beginning_of_day
    this_week = now.beginning_of_week
    this_month = now.beginning_of_month

    if time >= today
      # Today: show time only
      time.strftime("%H:%M")
    elsif time >= this_week
      # This week: show weekday and time
      # Use I18n for weekday name, fallback to strftime if not available
      begin
        weekday = I18n.t("date.day_names")[time.wday]
        "#{weekday} #{time.strftime("%H:%M")}"
      rescue StandardError
        time.strftime("%A %H:%M")
      end
    elsif time >= this_month
      # This month: show date and time
      # Use I18n for date format, fallback to strftime
      begin
        I18n.l(time, format: :short)
      rescue I18n::MissingTranslationData
        # Fallback format based on locale
        if I18n.locale.to_s.start_with?("zh")
          time.strftime("%m月%d日 %H:%M")
        else
          time.strftime("%b %d %H:%M")
        end
      end
    else
      # Longer: show full date and time
      begin
        I18n.l(time, format: :long)
      rescue I18n::MissingTranslationData
        time.strftime("%Y-%m-%d %H:%M")
      end
    end
  end
end
