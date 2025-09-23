class GitController extends Stimulus.Controller {
  static targets = [ "message" ]

  add(event) {
    event.preventDefault();

    const file = event.params.file;
    const formData = new FormData();
    formData.append('file', file);

    fetch('/git/add', {
      method: 'POST',
      body: formData,
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.refreshStatus();
      } else {
        alert('Error adding file.');
      }
    })
    .catch(error => console.error('Error:', error));
  }

  commit(event) {
    event.preventDefault();

    const formData = new FormData();
    formData.append('message', this.messageTarget.value);

    fetch('/git/commit', {
      method: 'POST',
      body: formData,
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.refreshStatus();
      } else {
        alert('Error committing changes.');
      }
    })
    .catch(error => console.error('Error:', error));
  }

  refreshStatus() {
    fetch('/git/status_panel')
      .then(response => response.text())
      .then(html => {
        this.element.innerHTML = html;
      });
  }
}
