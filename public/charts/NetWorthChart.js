// public/charts/NetWorthChart.js
import { Chart, registerables } from 'https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm';
Chart.register(...registerables);

export class NetWorthChart {
  constructor(canvasTarget, chartData) {
    this.canvasTarget = canvasTarget;
    this.chartData = chartData;
    this.chart = null;
  }

  render() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.chart = new Chart(this.canvasTarget, this.chartData);
  }
}