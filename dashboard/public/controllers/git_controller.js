import { Controller } from '/stimulus.js';

export default class extends Controller {
  static targets = [ "message" ]

  add(event) {
    event.preventDefault();

    const formData = new FormData();
    formData.append('file', event.target.dataset.gitFileValue);

    fetch('/git/add', {
      method: 'POST',
      body: formData,
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.reload();
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
        window.location.reload();
      } else {
        alert('Error committing changes.');
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
