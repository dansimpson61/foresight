import { Controller } from "/vendor/stimulus.js";

// Renders a tiny sparkline of ending Roth balance across years
export default class extends Controller {
  static targets = ["svg"];

  connect() {
    // Ensure an SVG exists even if not provided
    if (!this.hasSvgTarget) {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('width', '140');
      svg.setAttribute('height', '28');
      svg.setAttribute('viewBox', '0 0 140 28');
      svg.setAttribute('preserveAspectRatio', 'none');
      this.element.appendChild(svg);
      this.svgTarget = svg;
    } else {
      this.svgTarget.setAttribute('preserveAspectRatio', 'none');
    }
  }

  // Listen to document-level custom event: plan-form:results
  update(event) {
    const bundle = event?.detail;
    if (!bundle || !Array.isArray(bundle.yearly)) return;
    const yearly = bundle.yearly;
    const series = (this.element?.dataset?.series || 'roth').toLowerCase();
    let values;
    if (series === 'tax') {
      values = yearly.map(r => Number(r.all_in_tax || 0));
    } else if (series === 'networth') {
      values = yearly.map(r => Number(r.ending_taxable_balance||0) + Number(r.ending_traditional_balance||0) + Number(r.ending_roth_balance||0));
    } else {
      values = yearly.map(r => Number(r.ending_roth_balance || 0));
    }
    this.render(values, series);
  }

  render(values, series='roth') {
    const svg = this.svgTarget; if (!svg) return;
    const W = 140, H = 28, pad = 2;
    while (svg.lastChild) svg.removeChild(svg.lastChild);
    const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    bg.setAttribute('x', '0'); bg.setAttribute('y', '0');
    bg.setAttribute('width', String(W)); bg.setAttribute('height', String(H));
    bg.setAttribute('fill', '#ffffff');
    svg.appendChild(bg);

    if (!values || values.length === 0) return;
    const n = values.length;
    const minV = Math.min(...values);
    const maxV = Math.max(...values);
    const span = Math.max(1, maxV - minV);
    const x = (i) => pad + (n <= 1 ? 0 : (i * ((W - 2 * pad) / (n - 1))));
    const y = (v) => pad + (H - 2 * pad) - ((v - minV) / span) * (H - 2 * pad);

    const palette = {
      roth: { area:'#66BB6A', line:'#2e7d32' },
      tax: { area:'#EF5350', line:'#B71C1C' },
      networth: { area:'#90A4AE', line:'#37474F' },
    };
    const colors = palette[series] || palette.roth;

    // Area fill (light green)
    let d = `M ${x(0)} ${y(values[0])}`;
    for (let i = 1; i < n; i++) d += ` L ${x(i)} ${y(values[i])}`;
    d += ` L ${x(n - 1)} ${H - pad} L ${x(0)} ${H - pad} Z`;
    const area = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    area.setAttribute('d', d);
    area.setAttribute('fill', colors.area);
    area.setAttribute('fill-opacity', '0.25');
    svg.appendChild(area);

    // Line (solid green)
    let d2 = `M ${x(0)} ${y(values[0])}`;
    for (let i = 1; i < n; i++) d2 += ` L ${x(i)} ${y(values[i])}`;
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    line.setAttribute('d', d2);
    line.setAttribute('stroke', colors.line);
    line.setAttribute('stroke-width', '1.5');
    line.setAttribute('fill', 'none');
    svg.appendChild(line);
  }
}
