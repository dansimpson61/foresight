// A simple Stimulus controller to manage the accordion UI for the profile editor
class AccordionController extends Stimulus.Controller {

  toggle(event) {
    // Find the panel that is the next element after the clicked header
    const panel = event.currentTarget.nextElementSibling;
    panel.classList.toggle('hidden');
  }
}