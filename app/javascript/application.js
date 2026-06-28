import "@hotwired/turbo-rails"
import "controllers"
import { toggleSidebar } from "klods-js"

document.addEventListener("click", (e) => {
  const toggle = e.target.closest(".klods-sidebar-toggle")
  if (toggle) toggleSidebar(toggle)
})
