import { Controller } from "@hotwired/stimulus"

// Detects browser timezone and sets it in the timezone select field
export default class extends Controller {
  connect() {
    // Get browser timezone (e.g., "Asia/Shanghai", "America/New_York")
    const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

    if (browserTimezone) {
      // Map IANA timezone names to Rails timezone names
      // Rails uses friendly names like "Beijing" instead of "Asia/Shanghai"
      const timezoneMap = {
        "Asia/Shanghai": "Beijing",
        "Asia/Hong_Kong": "Hong Kong",
        "Asia/Tokyo": "Tokyo",
        "Asia/Seoul": "Seoul",
        "Asia/Singapore": "Singapore",
        "Asia/Dubai": "Dubai",
        "Asia/Kolkata": "Kolkata",
        "America/New_York": "Eastern Time (US & Canada)",
        "America/Chicago": "Central Time (US & Canada)",
        "America/Denver": "Mountain Time (US & Canada)",
        "America/Los_Angeles": "Pacific Time (US & Canada)",
        "America/Toronto": "Eastern Time (US & Canada)",
        "America/Vancouver": "Pacific Time (US & Canada)",
        "Europe/London": "London",
        "Europe/Paris": "Paris",
        "Europe/Berlin": "Berlin",
        "Europe/Madrid": "Madrid",
        "Europe/Rome": "Rome",
        "Europe/Moscow": "Moscow",
        "Australia/Sydney": "Sydney",
        "Australia/Melbourne": "Melbourne"
      }
      
      const railsTimezoneName = timezoneMap[browserTimezone]
      
      if (railsTimezoneName) {
        // Try to find matching timezone in the select options
        const options = this.element.options
        for (let i = 0; i < options.length; i++) {
          const option = options[i]
          // Match by Rails timezone name (e.g., "Beijing")
          if (option.value === railsTimezoneName) {
            // Set browser timezone if found, even if there's already a value
            // This ensures browser timezone takes precedence over server default
            this.element.value = railsTimezoneName
            break
          }
        }
      } else {
        // If no mapping found, try direct match (in case Rails uses IANA names)
        const options = this.element.options
        for (let i = 0; i < options.length; i++) {
          const option = options[i]
          if (option.value === browserTimezone) {
            this.element.value = browserTimezone
            break
          }
        }
      }
    }
  }
}

