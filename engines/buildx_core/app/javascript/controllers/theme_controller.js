import { Controller } from "@hotwired/stimulus"

// Theme toggle controller - handles theme switching and persistence
// Works with Turbo navigation by listening to turbo:load events
// Supports customizable theme names via data attributes:
//   data-theme-light-value="light" (default: "light")
//   data-theme-dark-value="dark" (default: "dark")
export default class extends Controller {
  static targets = ["icon"]
  static values = {
    light: { type: String, default: "light" },
    dark: { type: String, default: "dark" }
  }

  connect() {
    // Initialize theme on connect (works for both initial load and Turbo navigation)
    this.initializeTheme()

    // Listen for Turbo load events to ensure theme is applied after navigation
    this.boundHandleTurboLoad = this.handleTurboLoad.bind(this)
    document.addEventListener("turbo:load", this.boundHandleTurboLoad)
    document.addEventListener("turbo:frame-load", this.boundHandleTurboLoad)
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener("turbo:load", this.boundHandleTurboLoad)
    document.removeEventListener("turbo:frame-load", this.boundHandleTurboLoad)
  }

  handleTurboLoad() {
    // Re-initialize theme after Turbo navigation
    this.initializeTheme()
  }

  toggle() {
    const html = document.documentElement
    const currentTheme = html.getAttribute("data-theme")
    const lightTheme = this.lightValue
    const darkTheme = this.darkValue

    // Determine new theme based on current theme
    const newTheme = currentTheme === darkTheme ? lightTheme : darkTheme

    // Update theme
    html.setAttribute("data-theme", newTheme)
    localStorage.setItem("theme", newTheme)

    // Update icon
    this.updateIcon(newTheme)
  }

  initializeTheme() {
    // Get saved theme or use default (light theme)
    const savedTheme = localStorage.getItem("theme") || this.lightValue
    const html = document.documentElement

    // Apply theme
    html.setAttribute("data-theme", savedTheme)

    // Update icon to match current theme
    this.updateIcon(savedTheme)
  }

  updateIcon(theme) {
    // Update all theme icons on the page (there might be multiple instances)
    const icons = document.querySelectorAll("[data-theme-target='icon']")
    const darkTheme = this.darkValue

    icons.forEach((icon) => {
      if (theme === darkTheme) {
        // Moon icon for dark mode
        icon.innerHTML =
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />'
      } else {
        // Sun icon for light mode
        icon.innerHTML =
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />'
      }
    })
  }
}
