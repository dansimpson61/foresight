// global toast helper for reuse
window.showToast = (msg, kind = 'info', ms = 1800) => {
  const el = document.getElementById('toast');
  if (!el) return;
  el.className = `toast ${kind}`;
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(window.showToast._t);
  window.showToast._t = setTimeout(() => el.classList.remove('show'), ms);
};

// Fallback render helpers (mirrors controllers) for offline/test environments
const fmtMoney = (n) => (n == null || isNaN(n)) ? '--' : new Intl.NumberFormat('en-US', {style: 'currency', currency: 'USD', maximumFractionDigits: 0}).format(Number(n));
const clamp = (v,min,max)=>Math.min(max,Math.max(min,v));
const seriesFromYearly = (yearly) => {
  const years = yearly.map(r=>r.year);
  const taxable = yearly.map(r=>Number(r.ending_taxable_balance||0));
  const tradi = yearly.map(r=>Number(r.ending_traditional_balance||0));
  const roth = yearly.map(r=>Number(r.ending_roth_balance||0));
  const taxAllIn = yearly.map(r=>Number(r.all_in_tax||0));
  return { years, taxable, tradi, roth, taxAllIn };
};
const renderTable = (yearly) => {
  const tbody = document.querySelector('#results-table tbody'); if(!tbody) return; tbody.innerHTML='';
  yearly.forEach(r=>{
    const tr=document.createElement('tr');
    [r.year, fmtMoney(r.actual_roth_conversion), fmtMoney(r.federal_tax), fmtMoney(r.state_tax), fmtMoney(r.capital_gains_tax), fmtMoney(r.all_in_tax), fmtMoney(r.magi), fmtMoney(r.irmaa_part_b), fmtMoney(r.ending_taxable_balance), fmtMoney(r.ending_traditional_balance), fmtMoney(r.ending_roth_balance), (r.events&&r.events.length)||0].forEach(v=>{ const td=document.createElement('td'); td.textContent=String(v); td.style.textAlign='right'; td.style.borderBottom='1px solid #eee'; td.style.padding='4px 6px'; tr.appendChild(td); });
    tbody.appendChild(tr);
  });
};
const renderSummary = (agg) => {
  document.getElementById('metric-lifetime-taxes').textContent = fmtMoney(agg.cumulative_all_in_tax ?? (agg.cumulative_federal_tax + agg.cumulative_capital_gains_tax));
  document.getElementById('metric-total-conv').textContent = fmtMoney(agg.cumulative_roth_conversions);
  const endNW = (agg.ending_taxable_balance||0) + (agg.ending_traditional_balance||0) + (agg.ending_roth_balance||0);
  document.getElementById('metric-end-nw').textContent = fmtMoney(endNW);
  const pct = endNW>0 ? (agg.ending_roth_balance||0)/endNW : 0;
  document.getElementById('metric-taxfree-pct').textContent = `${(pct*100).toFixed(1)}%`;
};
const renderAssetsChart = (yearly) => {
  const svg = document.getElementById('chart-assets'); if(!svg) return;
  const W=800,H=260,padL=46,padR=46,padT=10,padB=28; const innerW=W-padL-padR, innerH=H-padT-padB;
  const {years,taxable,tradi,roth,taxAllIn} = seriesFromYearly(yearly); const n=years.length;
  const sumMax = Math.max(1, ...years.map((_,i)=>taxable[i]+tradi[i]+roth[i])); const taxMax=Math.max(1,...taxAllIn);
  const x=(i)=> padL + (n<=1?0:(i*(innerW/(n-1)))); const yVal=(v)=> padT+innerH-(v/sumMax)*innerH; const yTax=(v)=> padT+innerH-(v/taxMax)*innerH;
  while(svg.lastChild) svg.removeChild(svg.lastChild);
  const bg=document.createElementNS('http://www.w3.org/2000/svg','rect'); bg.setAttribute('x','0'); bg.setAttribute('y','0'); bg.setAttribute('width',String(W)); bg.setAttribute('height',String(H)); bg.setAttribute('fill','#ffffff'); svg.appendChild(bg);
  const areaPath=(base,add,color)=>{ const top=add.map((v,i)=>base[i]+v); let d=''; d+=`M ${x(0)} ${yVal(top[0])}`; for(let i=1;i<n;i++) d+=` L ${x(i)} ${yVal(top[i])}`; for(let i=n-1;i>=0;i--) d+=` L ${x(i)} ${yVal(base[i])}`; d+=' Z'; const p=document.createElementNS('http://www.w3.org/2000/svg','path'); p.setAttribute('d',d); p.setAttribute('fill',color); p.setAttribute('fill-opacity','0.9'); svg.appendChild(p); return top; };
  const zeros=new Array(n).fill(0); const top1=areaPath(zeros,taxable,'#B0BEC5'); const top2=areaPath(top1,tradi,'#42A5F5'); areaPath(top2,roth,'#66BB6A');
  let d=`M ${x(0)} ${yTax(taxAllIn[0])}`; for(let i=1;i<n;i++) d+=` L ${x(i)} ${yTax(taxAllIn[i])}`; const line=document.createElementNS('http://www.w3.org/2000/svg','path'); line.setAttribute('d',d); line.setAttribute('stroke','#EF5350'); line.setAttribute('stroke-width','2'); line.setAttribute('fill','none'); svg.appendChild(line);
};
const renderIRMAA=(yearly)=>{ const svg=document.getElementById('timeline-irmaa'); if(!svg) return; const W=800,H=36,pad=2; while(svg.lastChild) svg.removeChild(svg.lastChild); const n=yearly.length, segW=W/Math.max(1,n); const colorFor=(annual)=>{ if(!annual||annual<=0) return '#A5D6A7'; if(annual<=69.90*12) return '#FFF176'; if(annual<=174.70*12) return '#FFB74D'; return '#E57373'; }; yearly.forEach((r,i)=>{ const rect=document.createElementNS('http://www.w3.org/2000/svg','rect'); rect.setAttribute('x',String(i*segW)); rect.setAttribute('y',String(pad)); rect.setAttribute('width',String(Math.max(0,segW-1))); rect.setAttribute('height',String(H-2*pad)); rect.setAttribute('fill',colorFor(Number(r.irmaa_part_b||0))); svg.appendChild(rect); }); };
const renderEfficiencyGauge=(yearly)=>{ const svg=document.getElementById('eff-gauge'); if(!svg) return; const W=800,H=40,pad=6; while(svg.lastChild) svg.removeChild(svg.lastChild); const bg=document.createElementNS('http://www.w3.org/2000/svg','rect'); bg.setAttribute('x','0'); bg.setAttribute('y','0'); bg.setAttribute('width',String(W)); bg.setAttribute('height',String(H)); bg.setAttribute('fill','#ffffff'); svg.appendChild(bg); if(!yearly||yearly.length===0) return; const last=yearly[yearly.length-1]; const tradi=Number(last.ending_traditional_balance||0), roth=Number(last.ending_roth_balance||0), taxbl=Number(last.ending_taxable_balance||0); const total=tradi+roth+taxbl; if(total<=0) return; const innerW=W-2*pad, x0=pad, y0=pad, h=H-2*pad; const seg=(w,color,opacity=0.9)=>{ const r=document.createElementNS('http://www.w3.org/2000/svg','rect'); r.setAttribute('y',String(y0)); r.setAttribute('height',String(h)); r.setAttribute('fill',color); r.setAttribute('fill-opacity',String(opacity)); r.setAttribute('x',String(seg._x)); r.setAttribute('width',String(w)); svg.appendChild(r); seg._x+=w; }; seg._x=x0; const wTrad=innerW*(tradi/total), wRoth=innerW*(roth/total), wTaxb=innerW*(taxbl/total); seg(wTaxb,'#B0BEC5',0.6); seg(wTrad,'#42A5F5',0.9); seg(wRoth,'#66BB6A',0.9); };

function setState(state){ const el=document.getElementById('ui-state'); if(el) el.setAttribute('data-state', state); }

async function loadExampleVanilla(evt){ try{ if(evt){ evt.preventDefault(); evt.stopImmediatePropagation(); } window.showToast('Loading example…','info',900); const r=await fetch('/plan/example',{headers:{Accept:'application/json'}}); if(!r.ok) throw new Error(`HTTP ${r.status}`); const j=await r.json(); const input=document.getElementById('input'); input.value=JSON.stringify(j,null,2); setState('example-loaded'); window.showToast('Loaded example ✓','success'); } catch(err){ const input=document.getElementById('input'); if(input) input.value=`// Failed to load example: ${err}`; window.showToast('Failed to load example','error'); console.error('Load example failed',err);} }

async function runPlanVanilla(evt){ try{ if(evt){ evt.preventDefault(); evt.stopImmediatePropagation(); } const input=document.getElementById('input'); const body=JSON.parse(input.value); const r=await fetch('/plan',{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)}); const t=await r.text(); const model=JSON.parse(t); const keys=Object.keys(model.data.results); const bundle=model.data.results[keys[0]]; // Render
  renderSummary(bundle.aggregate||{}); renderTable(bundle.yearly||[]); renderAssetsChart(bundle.yearly||[]); renderIRMAA(bundle.yearly||[]); renderEfficiencyGauge(bundle.yearly||[]);
  setState('plan-ready'); window.showToast('Plan calculated ✓','success'); } catch(e){ window.showToast('Plan failed — check JSON','error'); console.error('Run plan failed',e);} }

// Sync JSON from minimal controls
function syncJsonFromControlsVanilla(){
  const input = document.getElementById('input'); if(!input) return;
  let current={}; try{ current = input.value.trim() ? JSON.parse(input.value) : {}; }catch(_e){ current = {}; }
  const startYearEl=document.getElementById('start_year'); const yearsEl=document.getElementById('years'); const inflEl=document.getElementById('inflation'); const growthEl=document.getElementById('growth'); const bracketEl=document.getElementById('bracket');
  // Round growth to nearest 0.5 for display and calculation (false precision)
  const growthVal = growthEl ? Math.round(Number(growthEl.value) * 2) / 2 : (current.assumed_growth_rate ? current.assumed_growth_rate * 100 : 5.0);
  if (growthEl) growthEl.value = String(growthVal);
  const out = document.getElementById('growth_value'); if (out) out.textContent = `${growthVal.toFixed(1)}%`;
  const inflOut = document.getElementById('inflation_value'); if (inflOut && inflEl) inflOut.textContent = `${Number(inflEl.value||0).toFixed(1)}%`;
  const bracketOut = document.getElementById('bracket_value'); if (bracketOut && bracketEl) {
    const n = Number(bracketEl.value||0);
    bracketOut.textContent = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);
  }

  const next = Object.assign({}, current, {
    start_year: startYearEl ? Number(startYearEl.value) : current.start_year,
    years: yearsEl ? Number(yearsEl.value) : current.years,
    inflation_rate: inflEl ? Number(inflEl.value)/100.0 : (current.inflation_rate ?? 0.0),
    desired_tax_bracket_ceiling: bracketEl ? Number(bracketEl.value) : (current.desired_tax_bracket_ceiling ?? 0),
    assumed_growth_rate: growthEl ? (growthVal/100.0) : (current.assumed_growth_rate ?? 0.05)
  });
  input.value = JSON.stringify(next, null, 2);
}

let __autoRunDebounce;
function autoRunFromControlsVanilla(){
  syncJsonFromControlsVanilla();
  clearTimeout(__autoRunDebounce);
  __autoRunDebounce = setTimeout(() => runPlanVanilla(), 450);
}

function wireVanilla(){
  if(window.__foresightVanillaWired) return; window.__foresightVanillaWired = true;
  const btnLoad=document.getElementById('btn-load-example'); const btnRun=document.getElementById('btn-run-plan'); if(btnLoad) btnLoad.addEventListener('click', loadExampleVanilla); if(btnRun) btnRun.addEventListener('click', runPlanVanilla);
  // Auto-run for minimal controls in vanilla mode too
  ['start_year','years','inflation','growth','bracket'].forEach(id => {
    const el = document.getElementById(id); if(el) el.addEventListener('input', autoRunFromControlsVanilla);
  });
}

// Try to load Stimulus from CDN; fallback to vanilla wiring if it fails
(async () => {
  // Always ensure vanilla wiring is ready for tests/offline
  if (document.readyState === 'loading') {
    window.addEventListener('DOMContentLoaded', wireVanilla);
  } else {
    wireVanilla();
  }
  try {
    let Application;
    try {
      // Prefer local vendored Stimulus when available
      ({ Application } = await import('/vendor/stimulus.js'));
    } catch (localErr) {
      console.warn('Local Stimulus not found, falling back to CDN...', localErr);
      ({ Application } = await import('https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js'));
    }
    const PlanFormController = (await import('/controllers/plan_form_controller.js')).default;
    const ResultsTableController = (await import('/controllers/results_table_controller.js')).default;
  const SummaryController = (await import('/controllers/summary_controller.js')).default;
  const SparklineController = (await import('/controllers/sparkline_controller.js')).default;
    const ChartsController = (await import('/controllers/charts_controller.js')).default;
    window.Stimulus = Application.start();
    Stimulus.register('plan-form', PlanFormController);
    Stimulus.register('results-table', ResultsTableController);
    Stimulus.register('summary', SummaryController);
    Stimulus.register('charts', ChartsController);
  Stimulus.register('sparkline', SparklineController);
  } catch (e) {
    console.warn('Stimulus failed to load; vanilla wiring in effect.', e);
  }
})();
