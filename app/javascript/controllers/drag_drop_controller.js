import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "position"]
  static values = { 
    moveUrl: String,
    csrfToken: String 
  }

  connect() {
    console.log("Drag and drop controller connected")
  }

  dragStart(event) {
    this.draggedElement = event.target
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/html", event.target.outerHTML)
    
    // Add visual feedback
    event.target.style.opacity = "0.5"
  }

  dragEnd(event) {
    // Remove visual feedback
    event.target.style.opacity = "1"
    this.draggedElement = null
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    
    // Add visual feedback for drop zone
    if (event.currentTarget.classList.contains('section-drop-zone')) {
      event.currentTarget.classList.add('bg-blue-50', 'border-blue-200')
    }
  }

  dragLeave(event) {
    // Remove visual feedback
    if (event.currentTarget.classList.contains('section-drop-zone')) {
      event.currentTarget.classList.remove('bg-blue-50', 'border-blue-200')
    }
  }

  drop(event) {
    event.preventDefault()
    
    // Remove visual feedback
    if (event.currentTarget.classList.contains('section-drop-zone')) {
      event.currentTarget.classList.remove('bg-blue-50', 'border-blue-200')
    }

    const positionId = this.draggedElement.dataset.positionId
    const sectionId = event.currentTarget.dataset.sectionId || null

    if (positionId && sectionId !== undefined) {
      this.movePositionToSection(positionId, sectionId)
    }
  }

  async movePositionToSection(positionId, sectionId) {
    try {
      const response = await fetch(this.moveUrlValue.replace(':id', positionId), {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfTokenValue,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          section_id: sectionId
        })
      })

      if (response.ok) {
        // Reload the page to show updated positions
        window.location.reload()
      } else {
        const error = await response.json()
        console.error('Error moving position:', error)
        this.showError('Failed to move position')
      }
    } catch (error) {
      console.error('Network error:', error)
      this.showError('Network error occurred')
    }
  }

  showError(message) {
    // Simple error notification - can be enhanced with a proper notification system
    alert(message)
  }
}
