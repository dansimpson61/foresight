import { Controller } from "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js";

export default class extends Controller {
  static targets = ["assets", "irmaa", "gauge"];

  connect() {
    this.element.addEventListener('plan-form:results', (e) => this.render(e.detail));
  }

  clamp(v, min, max) { return Math.min(max, Math.max(min, v)); }
  fmtMoney(n) {
    if (n == null || isNaN(n)) return '--';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(Number(n));
  }
  seriesFromYearly(yearly) {
    const years = yearly.map((r) => r.year);
    const taxable = yearly.map((r) => Number(r.ending_taxable_balance || 0));
    const tradi = yearly.map((r) => Number(r.ending_traditional_balance || 0));
    const roth = yearly.map((r) => Number(r.ending_roth_balance || 0));
    const taxAllIn = yearly.map((r) => Number(r.all_in_tax || 0));
    return { years, taxable, tradi, roth, taxAllIn };
  }

  render(bundle) {
    const yearly = bundle.yearly || [];
    this.renderAssetsChart(yearly);
    this.renderIRMAA(yearly);
    this.renderEfficiencyGauge(yearly);
  }

  renderAssetsChart(yearly) {
    const svg = this.assetsTarget;
    if (!svg) return;
    const W = 800, H = 260, padL = 46, padR = 46, padT = 10, padB = 28;
    const innerW = W - padL - padR;
    const innerH = H - padT - padB;
    const { years, taxable, tradi, roth, taxAllIn } = this.seriesFromYearly(yearly);
    const n = years.length;
    const sumMax = Math.max(1, ...years.map((_, i) => taxable[i] + tradi[i] + roth[i]));
    const taxMax = Math.max(1, ...taxAllIn);
    const x = (i) => padL + (n <= 1 ? 0 : i * (innerW / (n - 1)));
    const yVal = (v) => padT + innerH - (v / sumMax) * innerH;
    const yTax = (v) => padT + innerH - (v / taxMax) * innerH;
    while (svg.lastChild) svg.removeChild(svg.lastChild);
    const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    bg.setAttribute('x', '0'); bg.setAttribute('y', '0'); bg.setAttribute('width', String(W)); bg.setAttribute('height', String(H)); bg.setAttribute('fill', '#ffffff');
    svg.appendChild(bg);
    const areaPath = (base, add, color) => {
      const top = add.map((v, i) => base[i] + v);
      let d = '';
      d += `M ${x(0)} ${yVal(top[0])}`;
      for (let i = 1; i < n; i++) d += ` L ${x(i)} ${yVal(top[i])}`;
      for (let i = n - 1; i >= 0; i--) d += ` L ${x(i)} ${yVal(base[i])}`;
      d += ' Z';
      const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      p.setAttribute('d', d);
      p.setAttribute('fill', color);
      p.setAttribute('fill-opacity', '0.9');
      svg.appendChild(p);
      return top;
    };
    const zeros = new Array(n).fill(0);
    const top1 = areaPath(zeros, taxable, '#B0BEC5');
    const top2 = areaPath(top1, tradi, '#42A5F5');
    areaPath(top2, roth, '#66BB6A');
    let d = `M ${x(0)} ${yTax(taxAllIn[0])}`;
    for (let i = 1; i < n; i++) d += ` L ${x(i)} ${yTax(taxAllIn[i])}`;
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    line.setAttribute('d', d);
    line.setAttribute('stroke', '#EF5350');
    line.setAttribute('stroke-width', '2');
    line.setAttribute('fill', 'none');
    svg.appendChild(line);
    yearly.forEach((r, i) => {
      if (!r.events || r.events.length === 0) return;
      const vx = x(i);
      const tick = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      tick.setAttribute('x1', String(vx));
      tick.setAttribute('x2', String(vx));
      tick.setAttribute('y1', String(padT));
      tick.setAttribute('y2', String(padT + innerH));
      tick.setAttribute('stroke', '#222');
      tick.setAttribute('stroke-opacity', '0.15');
      tick.setAttribute('stroke-dasharray', '2,3');
      svg.appendChild(tick);
    });
    const axis = (el, attrs) => { Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, String(v))); svg.appendChild(el); };
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: padL, y1: padT + innerH, x2: padL + innerW, y2: padT + innerH, stroke: '#999', 'stroke-width': 1, 'stroke-opacity': 0.6 });
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: padL, y1: padT, x2: padL, y2: padT + innerH, stroke: '#999', 'stroke-width': 1, 'stroke-opacity': 0.6 });
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: W - padR, y1: padT, x2: W - padR, y2: padT + innerH, stroke: '#ef5350', 'stroke-width': 1, 'stroke-opacity': 0.4 });
    const txt = (s, x0, y0, opts = {}) => { const t = document.createElementNS('http://www.w3.org/2000/svg', 'text'); t.textContent = String(s); t.setAttribute('x', String(x0)); t.setAttribute('y', String(y0)); Object.entries(opts).forEach(([k, v]) => t.setAttribute(k, String(v))); svg.appendChild(t); };
    const yTicks = 4;
    for (let i = 0; i <= yTicks; i++) {
      const v = (sumMax * i) / yTicks;
      const yy = yVal(v);
      axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: padL - 4, y1: yy, x2: padL, y2: yy, stroke: '#666', 'stroke-width': 1, 'stroke-opacity': 0.6 });
      txt(this.fmtMoney(v), padL - 6, yy + 4, { 'font-size': 10, 'text-anchor': 'end', fill: '#666' });
    }
    const taxTicks = [0, taxMax / 2, taxMax];
    taxTicks.forEach((v) => {
      const yy = yTax(v);
      axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: W - padR, y1: yy, x2: W - padR + 4, y2: yy, stroke: '#ef5350', 'stroke-width': 1, 'stroke-opacity': 0.6 });
      txt(this.fmtMoney(v), W - padR + 6, yy + 4, { 'font-size': 10, 'text-anchor': 'start', fill: '#b91c1c' });
    });
    const shouldLabel = (i) => {
      if (i === 0 || i === n - 1) return true;
      if (n <= 10) return true;
      return years[i] % 5 === years[0] % 5;
    };
    for (let i = 0; i < n; i++) {
      if (!shouldLabel(i)) continue;
      const xx = x(i);
      axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), { x1: xx, y1: padT + innerH, x2: xx, y2: padT + innerH + 4, stroke: '#666', 'stroke-width': 1, 'stroke-opacity': 0.6 });
      txt(years[i], xx, padT + innerH + 14, { 'font-size': 10, 'text-anchor': 'middle', fill: '#666' });
    }
    const guide = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    guide.setAttribute('y1', String(padT)); guide.setAttribute('y2', String(padT + innerH));
    guide.setAttribute('stroke', '#000'); guide.setAttribute('stroke-opacity', '0.25'); guide.setAttribute('stroke-dasharray', '3,3');
    guide.style.display = 'none';
    svg.appendChild(guide);
    const tooltip = document.getElementById('chart-tooltip');
    const onMove = (evt) => {
      const rect = svg.getBoundingClientRect();
      const px = evt.clientX - rect.left;
      const idx = this.clamp(Math.round(((px - padL) / innerW) * (n - 1)), 0, n - 1);
      const xPos = x(idx);
      guide.setAttribute('x1', String(xPos));
      guide.setAttribute('x2', String(xPos));
      guide.style.display = 'block';
      tooltip.style.display = 'block';
      tooltip.style.left = `${xPos}px`;
      tooltip.style.top = `${padT}px`;
      tooltip.innerHTML = `Year ${years[idx]} · ${this.fmtMoney(taxable[idx])} / ${this.fmtMoney(tradi[idx])} / ${this.fmtMoney(roth[idx])} · Tax ${this.fmtMoney(taxAllIn[idx])}`;
    };
    const onLeave = () => { guide.style.display = 'none'; tooltip.style.display = 'none'; };
    svg.addEventListener('mousemove', onMove);
    svg.addEventListener('mouseleave', onLeave);
  }

  renderIRMAA(yearly) {
    const svg = this.irmaaTarget; if (!svg) return;
    const W = 800, H = 36, pad = 2;
    while (svg.lastChild) svg.removeChild(svg.lastChild);
    const n = yearly.length; const segW = W / Math.max(1, n);
    const colorFor = (annual) => {
      if (!annual || annual <= 0) return '#A5D6A7';
      if (annual <= 69.9 * 12) return '#FFF176';
      if (annual <= 174.7 * 12) return '#FFB74D';
      return '#E57373';
    };
    yearly.forEach((r, i) => {
      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      rect.setAttribute('x', String(i * segW));
      rect.setAttribute('y', String(pad));
      rect.setAttribute('width', String(Math.max(0, segW - 1)));
      rect.setAttribute('height', String(H - 2 * pad));
      rect.setAttribute('fill', colorFor(Number(r.irmaa_part_b || 0)));
      svg.appendChild(rect);
    });
  }

  renderEfficiencyGauge(yearly) {
    const svg = this.gaugeTarget; if (!svg) return;
    const W = 800, H = 40, pad = 6;
    while (svg.lastChild) svg.removeChild(svg.lastChild);
    const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    bg.setAttribute('x', '0'); bg.setAttribute('y', '0'); bg.setAttribute('width', String(W)); bg.setAttribute('height', String(H)); bg.setAttribute('fill', '#ffffff');
    svg.appendChild(bg);
    if (!yearly || yearly.length === 0) return;
    const last = yearly[yearly.length - 1];
    const tradi = Number(last.ending_traditional_balance || 0);
    const roth = Number(last.ending_roth_balance || 0);
    const taxbl = Number(last.ending_taxable_balance || 0);
    const total = tradi + roth + taxbl;
    if (total <= 0) return;
    const innerW = W - 2 * pad; const x0 = pad; const y0 = pad; const h = H - 2 * pad;
    const seg = (w, color, opacity = 0.9) => { const r = document.createElementNS('http://www.w3.org/2000/svg', 'rect'); r.setAttribute('y', String(y0)); r.setAttribute('height', String(h)); r.setAttribute('fill', color); r.setAttribute('fill-opacity', String(opacity)); r.setAttribute('x', String(seg._x)); r.setAttribute('width', String(w)); svg.appendChild(r); seg._x += w; }; seg._x = x0;
    const wTrad = innerW * (tradi / total);
    const wRoth = innerW * (roth / total);
    const wTaxb = innerW * (taxbl / total);
    seg(wTaxb, '#B0BEC5', 0.6); seg(wTrad, '#42A5F5', 0.9); seg(wRoth, '#66BB6A', 0.9);
    const txt = (s, x, y, opts = {}) => { const t = document.createElementNS('http://www.w3.org/2000/svg', 'text'); t.textContent = s; t.setAttribute('x', String(x)); t.setAttribute('y', String(y)); Object.entries(opts).forEach(([k, v]) => t.setAttribute(k, String(v))); svg.appendChild(t); };
    const pct = (v) => ((v / total) * 100).toFixed(0) + '%';
    if (wTrad > 40) txt(`Deferred ${pct(tradi)}`, x0 + wTaxb + wTrad / 2, y0 + h / 2 + 4, { 'font-size': 11, 'text-anchor': 'middle', fill: '#0b3a68' });
    if (wRoth > 40) txt(`Tax-free ${pct(roth)}`, x0 + wTaxb + wTrad + wRoth / 2, y0 + h / 2 + 4, { 'font-size': 11, 'text-anchor': 'middle', fill: '#0b5e2d' });
  }
}
