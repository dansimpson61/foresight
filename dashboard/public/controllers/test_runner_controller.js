import { Controller } from '/stimulus.js';

export default class extends Controller {
  static values = { file: String }

  static targets = [ "results" ]

  run(event) {
    event.preventDefault();

    this.resultsTarget.innerHTML = 'Running test...';

    const formData = new FormData();
    formData.append('file', this.fileValue);

    fetch('/run_test', {
      method: 'POST',
      headers: {
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData,
    })
    .then(response => response.text())
    .then(html => {
      this.resultsTarget.innerHTML = html;
    })
    .catch(error => {
      this.resultsTarget.innerHTML = `<pre>Error: ${error}</pre>`;
      console.error('Error:', error)
    });
  }
}
