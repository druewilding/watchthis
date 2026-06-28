import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => window.location.reload(), 2000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
