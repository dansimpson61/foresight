// A simple Stimulus controller to manage the accordion UI for the profile editor
class AccordionController extends Stimulus.Controller {
  toggle(event) {
    const header = event.currentTarget;
    const panel = header.nextElementSibling;
    if (!panel) return;
    if (window.FSUtils && FSUtils.toggleExpanded) {
      FSUtils.toggleExpanded(panel, header);
    } else {
      const isHidden = panel.classList.toggle('hidden');
      header.setAttribute('aria-expanded', String(!isHidden));
    }
  }
}