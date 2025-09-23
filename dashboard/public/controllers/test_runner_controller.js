class TestRunnerController extends Stimulus.Controller {
  static targets = [ "results" ]

  run(event) {
    event.preventDefault();

    const file = event.params.file;
    this.resultsTarget.innerHTML = `Running test: ${file}...`;

    const formData = new FormData();
    formData.append('file', file);

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
