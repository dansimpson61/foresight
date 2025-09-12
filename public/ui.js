// Minimal, intention-revealing UI logic extracted from views/ui.slim
// Philosophy: least JS, pure SVG, small helpers

const $ = (sel) => document.querySelector(sel);
const toastEl = () => document.getElementById('toast');
export const showToast = (msg, kind = 'info', ms = 1800) => {
  const el = toastEl();
  if (!el) return;
  el.className = `toast ${kind}`;
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => el.classList.remove('show'), ms);
};

const fmtMoney = (n) => {
  if (n == null || isNaN(n)) return '--';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(Number(n));
};
const fmtPct = (n) => (n == null || isNaN(n) ? '--' : `${(Number(n) * 100).toFixed(1)}%`);
const clamp = (v, min, max) => Math.min(max, Math.max(min, v));

const renderTable = (yearly) => {
  const tbody = $('#results-table tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  yearly.forEach((r) => {
    const tr = document.createElement('tr');
    const cells = [
      r.year,
      fmtMoney(r.actual_roth_conversion),
      fmtMoney(r.federal_tax),
      fmtMoney(r.state_tax),
      fmtMoney(r.capital_gains_tax),
      fmtMoney(r.all_in_tax),
      fmtMoney(r.magi),
      fmtMoney(r.irmaa_part_b),
      fmtMoney(r.ending_taxable_balance),
      fmtMoney(r.ending_traditional_balance),
      fmtMoney(r.ending_roth_balance),
      (r.events && r.events.length) || 0,
    ];
    cells.forEach((v) => {
      const td = document.createElement('td');
      td.textContent = v;
      td.style.textAlign = 'right';
      td.style.borderBottom = '1px solid #eee';
      td.style.padding = '4px 6px';
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  });
};

const renderSummary = (agg) => {
  $('#metric-lifetime-taxes').textContent = fmtMoney(
    agg.cumulative_all_in_tax ?? agg.cumulative_federal_tax + agg.cumulative_capital_gains_tax,
  );
  $('#metric-total-conv').textContent = fmtMoney(agg.cumulative_roth_conversions);
  const endNW = agg.ending_taxable_balance + agg.ending_traditional_balance + agg.ending_roth_balance;
  $('#metric-end-nw').textContent = fmtMoney(endNW);
  const taxFreePct = endNW > 0 ? agg.ending_roth_balance / endNW : 0;
  $('#metric-taxfree-pct').textContent = fmtPct(taxFreePct);
};

const seriesFromYearly = (yearly) => {
  const years = yearly.map((r) => r.year);
  const taxable = yearly.map((r) => Number(r.ending_taxable_balance || 0));
  const tradi = yearly.map((r) => Number(r.ending_traditional_balance || 0));
  const roth = yearly.map((r) => Number(r.ending_roth_balance || 0));
  const taxAllIn = yearly.map((r) => Number(r.all_in_tax || 0));
  return { years, taxable, tradi, roth, taxAllIn };
};

const renderAssetsChart = (yearly) => {
  const svg = document.getElementById('chart-assets');
  if (!svg) return;
  const W = 800,
    H = 260,
    padL = 46,
    padR = 46,
    padT = 10,
    padB = 28;
  const innerW = W - padL - padR;
  const innerH = H - padT - padB;
  const { years, taxable, tradi, roth, taxAllIn } = seriesFromYearly(yearly);
  const n = years.length;
  const sumMax = Math.max(1, ...years.map((_, i) => taxable[i] + tradi[i] + roth[i]));
  const taxMax = Math.max(1, ...taxAllIn);
  const x = (i) => padL + (n <= 1 ? 0 : i * (innerW / (n - 1)));
  const yVal = (v) => padT + innerH - (v / sumMax) * innerH;
  const yTax = (v) => padT + innerH - (v / taxMax) * innerH;
  // clear
  while (svg.lastChild) svg.removeChild(svg.lastChild);
  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  bg.setAttribute('x', '0');
  bg.setAttribute('y', '0');
  bg.setAttribute('width', String(W));
  bg.setAttribute('height', String(H));
  bg.setAttribute('fill', '#ffffff');
  svg.appendChild(bg);
  // stacked areas
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
  // overlay line for all-in tax
  let d = `M ${x(0)} ${yTax(taxAllIn[0])}`;
  for (let i = 1; i < n; i++) d += ` L ${x(i)} ${yTax(taxAllIn[i])}`;
  const line = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  line.setAttribute('d', d);
  line.setAttribute('stroke', '#EF5350');
  line.setAttribute('stroke-width', '2');
  line.setAttribute('fill', 'none');
  svg.appendChild(line);
  // event markers
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
  // axes and ticks
  const axis = (el, attrs) => {
    Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, String(v)));
    svg.appendChild(el);
  };
  // x-axis
  axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
    x1: padL,
    y1: padT + innerH,
    x2: padL + innerW,
    y2: padT + innerH,
    stroke: '#999',
    'stroke-width': 1,
    'stroke-opacity': 0.6,
  });
  // y-axis (left)
  axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
    x1: padL,
    y1: padT,
    x2: padL,
    y2: padT + innerH,
    stroke: '#999',
    'stroke-width': 1,
    'stroke-opacity': 0.6,
  });
  // y-axis (right) for tax
  axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
    x1: W - padR,
    y1: padT,
    x2: W - padR,
    y2: padT + innerH,
    stroke: '#ef5350',
    'stroke-width': 1,
    'stroke-opacity': 0.4,
  });
  const txt = (s, x0, y0, opts = {}) => {
    const t = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    t.textContent = String(s);
    t.setAttribute('x', String(x0));
    t.setAttribute('y', String(y0));
    Object.entries(opts).forEach(([k, v]) => t.setAttribute(k, String(v)));
    svg.appendChild(t);
  };
  // y ticks (balances)
  const yTicks = 4;
  for (let i = 0; i <= yTicks; i++) {
    const v = (sumMax * i) / yTicks;
    const yy = yVal(v);
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
      x1: padL - 4,
      y1: yy,
      x2: padL,
      y2: yy,
      stroke: '#666',
      'stroke-width': 1,
      'stroke-opacity': 0.6,
    });
    txt(fmtMoney(v), padL - 6, yy + 4, { 'font-size': 10, 'text-anchor': 'end', fill: '#666' });
  }
  // y ticks (tax line, right)
  const taxTicks = [0, taxMax / 2, taxMax];
  taxTicks.forEach((v) => {
    const yy = yTax(v);
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
      x1: W - padR,
      y1: yy,
      x2: W - padR + 4,
      y2: yy,
      stroke: '#ef5350',
      'stroke-width': 1,
      'stroke-opacity': 0.6,
    });
    txt(fmtMoney(v), W - padR + 6, yy + 4, { 'font-size': 10, 'text-anchor': 'start', fill: '#b91c1c' });
  });
  // x ticks (years)
  const shouldLabel = (i) => {
    if (i === 0 || i === n - 1) return true;
    if (n <= 10) return true;
    return years[i] % 5 === years[0] % 5; // every ~5 years
  };
  for (let i = 0; i < n; i++) {
    if (!shouldLabel(i)) continue;
    const xx = x(i);
    axis(document.createElementNS('http://www.w3.org/2000/svg', 'line'), {
      x1: xx,
      y1: padT + innerH,
      x2: xx,
      y2: padT + innerH + 4,
      stroke: '#666',
      'stroke-width': 1,
      'stroke-opacity': 0.6,
    });
    txt(years[i], xx, padT + innerH + 14, { 'font-size': 10, 'text-anchor': 'middle', fill: '#666' });
  }
  // guideline + tooltip
  const guide = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  guide.setAttribute('y1', String(padT));
  guide.setAttribute('y2', String(padT + innerH));
  guide.setAttribute('stroke', '#000');
  guide.setAttribute('stroke-opacity', '0.25');
  guide.setAttribute('stroke-dasharray', '3,3');
  guide.style.display = 'none';
  svg.appendChild(guide);
  const tooltip = document.getElementById('chart-tooltip');
  const onMove = (evt) => {
    const rect = svg.getBoundingClientRect();
    const px = evt.clientX - rect.left;
    const idx = clamp(Math.round(((px - padL) / innerW) * (n - 1)), 0, n - 1);
    guide.setAttribute('x1', String(x(idx)));
    guide.setAttribute('x2', String(x(idx)));
    guide.style.display = 'block';
    tooltip.style.display = 'block';
    tooltip.style.left = `${x(idx)}px`;
    tooltip.style.top = `${padT}px`;
    tooltip.innerHTML = `Year ${years[idx]} · ${fmtMoney(taxable[idx])} / ${fmtMoney(tradi[idx])} / ${fmtMoney(roth[idx])} · Tax ${fmtMoney(taxAllIn[idx])}`;
  };
  const onLeave = () => {
    guide.style.display = 'none';
    tooltip.style.display = 'none';
  };
  svg.addEventListener('mousemove', onMove);
  svg.addEventListener('mouseleave', onLeave);
};

const renderIRMAA = (yearly) => {
  const svg = document.getElementById('timeline-irmaa');
  if (!svg) return;
  const W = 800,
    H = 36,
    pad = 2;
  while (svg.lastChild) svg.removeChild(svg.lastChild);
  const n = yearly.length;
  const segW = W / Math.max(1, n);
  const colorFor = (annual) => {
    if (!annual || annual <= 0) return '#A5D6A7'; // green
    if (annual <= 69.9 * 12) return '#FFF176'; // yellow
    if (annual <= 174.7 * 12) return '#FFB74D'; // orange
    return '#E57373'; // red
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
};

const renderEfficiencyGauge = (yearly) => {
  const svg = document.getElementById('eff-gauge');
  if (!svg) return;
  const W = 800,
    H = 40,
    pad = 6;
  while (svg.lastChild) svg.removeChild(svg.lastChild);
  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  bg.setAttribute('x', '0');
  bg.setAttribute('y', '0');
  bg.setAttribute('width', String(W));
  bg.setAttribute('height', String(H));
  bg.setAttribute('fill', '#ffffff');
  svg.appendChild(bg);
  if (!yearly || yearly.length === 0) return;
  const last = yearly[yearly.length - 1];
  const tradi = Number(last.ending_traditional_balance || 0);
  const roth = Number(last.ending_roth_balance || 0);
  const taxbl = Number(last.ending_taxable_balance || 0);
  const total = tradi + roth + taxbl;
  if (total <= 0) return;
  const innerW = W - 2 * pad;
  const x0 = pad;
  const y0 = pad;
  const h = H - 2 * pad;
  const seg = (w, color, opacity = 0.9) => {
    const r = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    r.setAttribute('y', String(y0));
    r.setAttribute('height', String(h));
    r.setAttribute('fill', color);
    r.setAttribute('fill-opacity', String(opacity));
    r.setAttribute('x', String(seg._x));
    r.setAttribute('width', String(w));
    svg.appendChild(r);
    seg._x += w;
  };
  seg._x = x0;
  const wTrad = innerW * (tradi / total);
  const wRoth = innerW * (roth / total);
  const wTaxb = innerW * (taxbl / total);
  // Order: taxable (muted), traditional (blue), roth (green)
  seg(wTaxb, '#B0BEC5', 0.6);
  seg(wTrad, '#42A5F5', 0.9);
  seg(wRoth, '#66BB6A', 0.9);
  const txt = (s, x, y, opts = {}) => {
    const t = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    t.textContent = s;
    t.setAttribute('x', String(x));
    t.setAttribute('y', String(y));
    Object.entries(opts).forEach(([k, v]) => t.setAttribute(k, String(v)));
    svg.appendChild(t);
  };
  const pct = (v) => ((v / total) * 100).toFixed(0) + '%';
  if (wTrad > 40) txt(`Deferred ${pct(tradi)}`, x0 + wTaxb + wTrad / 2, y0 + h / 2 + 4, { 'font-size': 11, 'text-anchor': 'middle', fill: '#0b3a68' });
  if (wRoth > 40) txt(`Tax-free ${pct(roth)}`, x0 + wTaxb + wTrad + wRoth / 2, y0 + h / 2 + 4, { 'font-size': 11, 'text-anchor': 'middle', fill: '#0b5e2d' });
};

let lastJsonText = null;
let model = null;
const updateView = (strategyKey) => {
  if (!model) return;
  const bundle = model.data.results[strategyKey];
  renderSummary(bundle.aggregate);
  renderTable(bundle.yearly);
  renderAssetsChart(bundle.yearly);
  renderIRMAA(bundle.yearly);
  renderEfficiencyGauge(bundle.yearly);
};

const wire = () => {
  const input = document.getElementById('input');
  const btnLoad = document.getElementById('btn-load-example');
  if (btnLoad)
    btnLoad.addEventListener('click', async () => {
      try {
        showToast('Loading example…', 'info', 900);
        const r = await fetch('/plan/example', { headers: { Accept: 'application/json' } });
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        const j = await r.json();
        input.value = JSON.stringify(j, null, 2);
        showToast('Loaded example ✓', 'success');
      } catch (err) {
        if (input) input.value = `// Failed to load example: ${err}`;
        showToast('Failed to load example', 'error');
        console.error('Load example failed', err);
      }
    });
  const btnRun = document.getElementById('btn-run-plan');
  if (btnRun)
    btnRun.addEventListener('click', async () => {
      try {
        const body = JSON.parse(input.value);
        const r = await fetch('/plan', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        });
        const t = await r.text();
        lastJsonText = t;
        setDownload(t);
        model = JSON.parse(t);
        const keys = Object.keys(model.data.results);
        populateStrategySelector(keys);
        const sel = document.getElementById('strategy');
        sel.onchange = () => updateView(sel.value);
        sel.value = keys[0];
        updateView(keys[0]);
        showToast('Plan calculated ✓', 'success');
      } catch (e) {
        // keep alert for now but we could toast-only later
        alert('Invalid JSON in parameters.');
        showToast('Plan failed — check JSON', 'error');
        console.error('Run plan failed', e);
      }
    });
};
if (document.readyState === 'loading') {
  window.addEventListener('DOMContentLoaded', wire);
} else {
  wire();
}

const populateStrategySelector = (keys) => {
  const sel = $('#strategy');
  sel.innerHTML = '';
  keys.forEach((k) => {
    const opt = document.createElement('option');
    opt.value = k;
    opt.textContent = k;
    sel.appendChild(opt);
  });
  sel.disabled = keys.length === 0;
};
const setDownload = (jsonText) => {
  const btn = document.getElementById('download');
  if (!jsonText) {
    btn.disabled = true;
    btn.onclick = null;
    return;
  }
  btn.disabled = false;
  btn.onclick = () => {
    const blob = new Blob([jsonText], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'foresight_report.json';
    a.click();
    URL.revokeObjectURL(url);
  };
};
