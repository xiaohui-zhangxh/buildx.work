import { Controller } from "@hotwired/stimulus"

// Password strength indicator controller
export default class extends Controller {
  static targets = ["input", "indicator", "feedback", "indicatorContainer"]

  connect() {
    this.updateStrength()
  }

  updateStrength() {
    const password = this.inputTarget.value
    const strength = this.calculateStrength(password)
    
    this.updateIndicator(strength)
    this.updateFeedback(strength, password)
  }

  calculateStrength(password) {
    if (!password || password.length === 0) {
      return { level: 0, label: "", color: "" }
    }

    let score = 0
    const checks = {
      length: password.length >= 8,
      hasLetter: /[a-zA-Z]/.test(password),
      hasNumber: /\d/.test(password),
      hasSpecial: /[!@#$%^&*(),.?":{}|<>]/.test(password),
      hasUpper: /[A-Z]/.test(password),
      hasLower: /[a-z]/.test(password)
    }

    if (checks.length) score += 1
    if (checks.hasLetter) score += 1
    if (checks.hasNumber) score += 1
    if (checks.hasSpecial) score += 1
    if (checks.hasUpper && checks.hasLower) score += 1

    if (score <= 2) {
      return { level: 1, label: "弱", color: "error" }
    } else if (score <= 3) {
      return { level: 2, label: "中", color: "warning" }
    } else if (score <= 4) {
      return { level: 3, label: "强", color: "info" }
    } else {
      return { level: 4, label: "很强", color: "success" }
    }
  }

  updateIndicator(strength) {
    if (!this.hasIndicatorTarget) return

    const container = this.hasIndicatorContainerTarget
      ? this.indicatorContainerTarget
      : this.indicatorTarget.parentElement

    // Remove all strength classes
    this.indicatorTarget.classList.remove(
      "bg-error", "bg-warning", "bg-info", "bg-success"
    )

    if (strength.level > 0) {
      this.indicatorTarget.classList.add(`bg-${strength.color}`)
      this.indicatorTarget.style.width = `${(strength.level / 4) * 100}%`
      this.indicatorTarget.style.display = "block"
      container.style.display = "block"
    } else {
      this.indicatorTarget.style.display = "none"
      container.style.display = "none"
    }
  }

  updateFeedback(strength, password) {
    if (!this.hasFeedbackTarget) return

    if (password.length === 0) {
      this.feedbackTarget.textContent = ""
      return
    }

    const messages = []
    if (password.length < 8) {
      messages.push("至少 8 个字符")
    }
    if (!/[a-zA-Z]/.test(password)) {
      messages.push("包含字母")
    }
    if (!/\d/.test(password)) {
      messages.push("包含数字")
    }

    if (messages.length > 0) {
      this.feedbackTarget.textContent = `需要：${messages.join("、")}`
      this.feedbackTarget.className = "label-text-alt text-error"
    } else {
      this.feedbackTarget.textContent = `密码强度：${strength.label}`
      this.feedbackTarget.className = `label-text-alt text-${strength.color}`
    }
  }
}

