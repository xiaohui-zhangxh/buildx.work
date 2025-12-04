import { Controller } from "@hotwired/stimulus"

// Navbar auto-hide controller - hides navbar on scroll down, shows on scroll up
// Usage:
//   <div data-controller="navbar">
//     <nav class="navbar ...">...</nav>
//   </div>
//
// Optional data attributes:
//   data-navbar-threshold-value="10" (default: 10) - scroll threshold in pixels
//   data-navbar-offset-value="0" (default: 0) - offset from top when hidden
export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 10 },
    offset: { type: Number, default: 0 }
  }

  connect() {
    this.lastScrollY = window.scrollY
    this.isVisible = true
    this.isScrolling = false

    // Initialize visible state
    this.element.classList.add("navbar-visible")
    this.element.classList.remove("navbar-hidden")

    // Throttle scroll events for better performance
    this.boundHandleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.boundHandleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundHandleScroll)
  }

  handleScroll() {
    if (this.isScrolling) return

    this.isScrolling = true
    requestAnimationFrame(() => {
      const currentScrollY = window.scrollY
      const scrollDifference = Math.abs(currentScrollY - this.lastScrollY)

      // Only update if scroll difference is significant
      if (scrollDifference > this.thresholdValue) {
        // Always show navbar at the top of the page
        if (currentScrollY <= 50) {
          this.show()
        } else if (currentScrollY > this.lastScrollY) {
          // Scrolling down - hide navbar
          this.hide()
        } else if (currentScrollY < this.lastScrollY) {
          // Scrolling up - show navbar
          this.show()
        }

        this.lastScrollY = currentScrollY
      }

      this.isScrolling = false
    })
  }

  show() {
    if (!this.isVisible) {
      this.element.classList.remove("navbar-hidden")
      this.element.classList.add("navbar-visible")
      this.isVisible = true
    }
  }

  hide() {
    if (this.isVisible) {
      this.element.classList.remove("navbar-visible")
      this.element.classList.add("navbar-hidden")
      this.isVisible = false
    }
  }
}

