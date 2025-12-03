import { Controller } from "@hotwired/stimulus"

// Form controller - handle loading state and prevent double submission
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    // Store original submit button state
    if (this.hasSubmitTarget) {
      this.originalSubmitContent = this.submitTarget.innerHTML
      this.originalSubmitDisabled = this.submitTarget.disabled
    }

    // Listen for Turbo events to handle form submission lifecycle
    this.boundHandleSubmitStart = this.handleSubmitStart.bind(this)
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this)
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)

    this.element.addEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    this.element.addEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
    this.element.addEventListener("turbo:frame-load", this.boundHandleFrameLoad)
  }

  disconnect() {
    // Clean up event listeners
    this.element.removeEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    this.element.removeEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
    this.element.removeEventListener("turbo:frame-load", this.boundHandleFrameLoad)

    // Restore button state if still in loading state
    this.restoreButton()
  }

  handleSubmitStart(event) {
    // Form submission started
    if (this.hasSubmitTarget) {
      this.setLoadingState()
    }
  }

  handleSubmitEnd(event) {
    // Form submission ended (success or failure)
    // event.detail.success indicates if the request was successful
    this.restoreButton()
  }

  handleFrameLoad(event) {
    // Turbo frame loaded (for frame-based forms)
    this.restoreButton()
  }

  submit(event) {
    // Manual submit handler (for non-Turbo forms or as fallback)
    if (this.hasSubmitTarget) {
      this.setLoadingState()
    }
  }

  setLoadingState() {
    if (!this.hasSubmitTarget) return

    const submit = this.submitTarget

    // Store original content if not already stored
    if (!this.originalSubmitContent) {
      this.originalSubmitContent = submit.innerHTML.trim()
    }

    // Disable the button
    submit.disabled = true

    // Add DaisyUI loading spinner icon before the text
    const loadingIcon = '<span class="loading loading-spinner loading-sm"></span>'
    
    // Get the original text content (strip any existing HTML)
    const originalText = submit.textContent.trim()
    
    // Set new content with loading icon
    submit.innerHTML = `${loadingIcon} ${originalText}`
  }

  restoreButton() {
    if (!this.hasSubmitTarget) return

    const submit = this.submitTarget

    // Re-enable the button
    submit.disabled = this.originalSubmitDisabled || false

    // Restore original content (including any icons that were there)
    if (this.originalSubmitContent) {
      submit.innerHTML = this.originalSubmitContent
    }
  }
}
