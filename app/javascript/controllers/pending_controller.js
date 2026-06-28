import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.attempts = 0
    this.schedule()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  schedule() {
    this.timer = setTimeout(() => this.check(), 500)
  }

  async check() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const { fetched } = await response.json()
      if (fetched) {
        window.location.reload()
      } else if (this.attempts++ < 30) {
        this.schedule()
      }
    } catch {
      // network error or controller disconnected — stop polling
    }
  }
}
