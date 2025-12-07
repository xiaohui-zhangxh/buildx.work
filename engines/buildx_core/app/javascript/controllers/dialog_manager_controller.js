import { Controller } from "@hotwired/stimulus"

// Dialog Manager Controller - 管理对话框的打开、关闭和内容加载
// 学习自 Basecamp Fizzy 项目的 dialog + turbo frame 交互方式
export default class extends Controller {
  static values = { url: String }
  static targets = ["frame", "dialog"]

  connect() {
    // 绑定事件处理函数
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)
    this.boundHandleClose = this.handleClose.bind(this)
    this.boundHandleKeyDown = this.handleKeyDown.bind(this)

    // 监听 Turbo Frame 加载完成事件
    if (this.hasFrameTarget) {
      this.boundHandleFrameLoadError = this.handleFrameLoadError.bind(this)
      this.frameTarget.addEventListener("turbo:frame-load", this.boundHandleFrameLoad)
      this.frameTarget.addEventListener("turbo:frame-load-error", this.boundHandleFrameLoadError)
    }

    // 监听对话框关闭事件
    if (this.hasDialogTarget) {
      this.dialogTarget.addEventListener("close", this.boundHandleClose)
      // 监听 ESC 键（虽然原生 dialog 已经支持，但我们可以添加额外逻辑）
      this.dialogTarget.addEventListener("keydown", this.boundHandleKeyDown)
    }
  }

  disconnect() {
    // 清理事件监听器
    if (this.hasFrameTarget) {
      this.frameTarget.removeEventListener("turbo:frame-load", this.boundHandleFrameLoad)
      if (this.boundHandleFrameLoadError) {
        this.frameTarget.removeEventListener("turbo:frame-load-error", this.boundHandleFrameLoadError)
      }
    }

    if (this.hasDialogTarget) {
      this.dialogTarget.removeEventListener("close", this.boundHandleClose)
      this.dialogTarget.removeEventListener("keydown", this.boundHandleKeyDown)
    }
  }

  // 打开对话框
  open(event) {
    event?.preventDefault()

    if (!this.hasDialogTarget) return

    // 如果提供了 URL，设置 Turbo Frame 的 src 来加载内容
    if (this.hasUrlValue && this.hasFrameTarget) {
      this.frameTarget.src = this.urlValue
    }

    // 显示对话框（模态对话框）
    this.dialogTarget.showModal()

    // 聚焦第一个可交互元素（提升可访问性）
    this.focusFirstElement()
  }

  // 关闭对话框
  close(event) {
    event?.preventDefault()

    if (this.hasDialogTarget) {
      this.dialogTarget.close()
    }
  }

  // 处理 Turbo Frame 加载完成
  handleFrameLoad(event) {
    // Frame 加载完成后的处理
    // 可以在这里添加加载成功后的逻辑，例如：
    // - 聚焦第一个输入框
    // - 滚动到特定位置
    // - 更新 UI 状态
  }

  // 处理 Turbo Frame 加载错误
  handleFrameLoadError(event) {
    // Frame 加载失败时的处理
    // 可以显示错误消息或重试按钮
    console.error("Dialog frame load error:", event)
  }

  // 处理对话框关闭事件
  handleClose(event) {
    // 对话框关闭时的清理工作
    if (this.hasFrameTarget) {
      // 清空 Frame 内容，以便下次打开时重新加载
      this.frameTarget.src = ""
    }
  }

  // 处理键盘事件
  handleKeyDown(event) {
    // ESC 键关闭对话框（原生 dialog 已经支持，这里可以添加额外逻辑）
    if (event.key === "Escape" && this.hasDialogTarget) {
      // 可以在这里添加关闭前的确认逻辑
      // 例如：如果有未保存的更改，提示用户
    }
  }

  // 聚焦第一个可交互元素
  focusFirstElement() {
    if (!this.hasDialogTarget) return

    // 查找第一个可交互元素
    const firstFocusable = this.dialogTarget.querySelector(
      'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )

    if (firstFocusable) {
      // 延迟聚焦，确保对话框已完全显示
      setTimeout(() => {
        firstFocusable.focus()
      }, 100)
    }
  }
}

