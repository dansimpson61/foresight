import { Controller } from '../vendor/stimulus.js';
import { Chart, registerables } from 'https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm';
Chart.register(...registerables);

export default class extends Controller {
  static targets = ["canvas"];

  connect() {
    this.render();
  }

  render() {
    // This is a placeholder for the tax bracket slider chart.
    // The actual implementation will require fetching tax bracket data
    // and dynamically rendering the chart based on that data.
    new Chart(this.canvasTarget, {
      type: 'bar',
      data: {
        labels: ['10%', '12%', '22%', '24%', '32%', '35%', '37%'],
        datasets: [{
          label: 'Tax Brackets',
          data: [11000, 44725, 95375, 182100, 231250, 578125, 578126],
          backgroundColor: [
            'rgba(255, 99, 132, 0.2)',
            'rgba(255, 159, 64, 0.2)',
            'rgba(255, 205, 86, 0.2)',
            'rgba(75, 192, 192, 0.2)',
            'rgba(54, 162, 235, 0.2)',
            'rgba(153, 102, 255, 0.2)',
            'rgba(201, 203, 207, 0.2)'
          ],
          borderColor: [
            'rgb(255, 99, 132)',
            'rgb(255, 159, 64)',
            'rgb(255, 205, 86)',
            'rgb(75, 192, 192)',
            'rgb(54, 162, 235)',
            'rgb(153, 102, 255)',
            'rgb(201, 203, 207)'
          ],
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }
}
