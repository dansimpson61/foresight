class TestCardController extends Stimulus.Controller {
  static targets = [ "details" ]

  toggleDetails() {
    this.detailsTarget.classList.toggle('open');
  }

  runTest(event) {
    event.stopPropagation(); // Don't toggle the card when the button is clicked
    event.preventDefault();

    const file = event.params.file;
    const cardBody = this.detailsTarget;
    cardBody.innerHTML = 'Running test...';
    cardBody.classList.add('open');

    const formData = new FormData();
    formData.append('file', file);

    fetch(`/tests/${file}`, {
      method: 'POST',
      body: formData,
    })
    .then(response => response.text())
    .then(html => {
      cardBody.innerHTML = html;
    })
    .catch(error => {
      cardBody.innerHTML = `<pre>Error: ${error}</pre>`;
      console.error('Error:', error)
    });
  }
}
