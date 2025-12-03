import { Controller } from "@hotwired/stimulus"

// 处理 Flash 消息显示
// 当页面加载时，自动检测并显示 flash 消息
export default class extends Controller {
  connect() {
    // 记录开始时间
    this.startTime = Date.now()
    this.maxWaitTime = 3000 // 3 秒
    this.retryInterval = 50 // 每 50ms 重试一次

    // 开始等待并重试
    this.showFlashMessage()

    // 设置超时，3 秒后如果还没找到就使用回退方案
    this.timeoutId = setTimeout(() => {
      if (!window.globalNotificationController) {
        this.fallbackToCurrentDisplay()
      }
    }, this.maxWaitTime)
  }

  disconnect() {
    // 清理超时定时器
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  showFlashMessage() {
    // 检查是否超时
    const elapsed = Date.now() - this.startTime
    if (elapsed >= this.maxWaitTime) {
      // 已经超时，使用回退方案
      this.fallbackToCurrentDisplay()
      return
    }

    // 检查 globalNotificationController 是否已初始化
    if (!window.globalNotificationController) {
      // 如果还没初始化，等待一下再试
      setTimeout(() => this.showFlashMessage(), this.retryInterval)
      return
    }

    // 找到了 globalNotificationController，清理超时定时器
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    window.globalNotificationController.show({
      detail: { message: this.#message, type: this.#type }
    })

    // 移除 template 元素（如果是 TEMPLATE）
    if (this.element.tagName === "TEMPLATE") {
      this.element.remove()
    }
  }

  fallbackToCurrentDisplay() {
    // 清理超时定时器
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    // 如果没有 globalNotificationController，使用当前显示方式
    // 保持元素显示，但添加自动消失功能（5秒后）
    if (this.element.tagName !== "TEMPLATE") {
      const duration = parseInt(this.element.dataset.duration) || 5000
      setTimeout(() => {
        this.dismiss()
      }, duration)
    } else {
      // 如果是 TEMPLATE 且没有 globalNotificationController，使用 alert
      window.alert(this.#message)
      this.element.remove()
    }
  }

  dismiss() {
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  get #type() {
    // data-flash-type 在 dataset 中变成 flashType（驼峰命名）
    return this.element.dataset.flashType || (this.element.classList.contains("alert-success") ? "success" : (this.element.classList.contains("alert-error") ? "error" : "info"))
  }

  get #message() {
    if (this.element.tagName === "TEMPLATE") {
      return this.element.content.textContent.trim()
    } else {
      // 从 span 标签中提取文本，或者从整个元素中提取
      const span = this.element.querySelector("span")
      return span ? span.textContent.trim() : this.element.textContent.trim()
    }
  }
}

