import { Controller } from '/stimulus.js';

export default class extends Controller {
  static values = { file: String }

  run(event) {
    event.preventDefault();

    const formData = new FormData();
    formData.append('file', this.fileValue);

    fetch('/run_test', {
      method: 'POST',
      body: formData,
    })
    .then(response => response.text())
    .then(html => {
      const newDoc = new DOMParser().parseFromString(html, 'text/html');
      document.body.innerHTML = newDoc.body.innerHTML;
      document.body.className = newDoc.body.className; // Copy status class
    })
    .catch(error => console.error('Error:', error));
  }
}
