// Minimal shared utilities for the Simple app
// Expose as a conservative global to avoid module tooling
(function initFSUtils() {
  if (window.FSUtils) return; // idempotent

  const formatCurrency = (number) => {
    try {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(number);
    } catch (_) {
      // Fallback: naive formatting
      const n = Number(number) || 0;
      return '$' + Math.round(n).toLocaleString('en-US');
    }
  };

  const toggleExpanded = (targetEl, invokerEl) => {
    if (!targetEl) return false;
    targetEl.classList.toggle('hidden');
    if (invokerEl) {
      const expanded = !targetEl.classList.contains('hidden');
      invokerEl.setAttribute('aria-expanded', String(expanded));
    }
    return !targetEl.classList.contains('hidden');
  };

  const fetchJson = async (url, bodyObj) => {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(bodyObj || {}),
    });
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      const err = new Error(`HTTP ${res.status} ${res.statusText}`);
      err.responseText = text;
      throw err;
    }
    return res.json();
  };

  const storage = {
    loadJSON(key, fallback = null) {
      try {
        const raw = localStorage.getItem(key);
        return raw ? JSON.parse(raw) : fallback;
      } catch (e) {
        console.warn('[FSUtils.storage] loadJSON failed', e);
        return fallback;
      }
    },
    saveJSON(key, value) {
      try {
        localStorage.setItem(key, JSON.stringify(value));
        return true;
      } catch (e) {
        console.warn('[FSUtils.storage] saveJSON failed', e);
        return false;
      }
    },
    remove(keys) {
      try {
        (Array.isArray(keys) ? keys : [keys]).forEach(k => localStorage.removeItem(k));
        return true;
      } catch (e) {
        console.warn('[FSUtils.storage] remove failed', e);
        return false;
      }
    }
  };

  // Media/animation helpers
  const reducedMotion = () => {
    try { return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches; }
    catch (_) { return false; }
  };

  // Common chart helpers
  const safeDestroy = (chart) => {
    try { if (chart && typeof chart.destroy === 'function') chart.destroy(); }
    catch (e) { console.warn('[FSUtils] chart.destroy failed', e); }
  };

  const pickYearly = (results, strategy) => {
    const s = strategy || 'fill_to_bracket';
    if (!results) return [];
    if (s === 'do_nothing') return (results.do_nothing_results && results.do_nothing_results.yearly) || [];
    return (results.fill_bracket_results && results.fill_bracket_results.yearly) || [];
  };

  // Chart.js options factory with pluggable callbacks
  const createChartOptions = ({ tooltipLabel, tooltipFooter, legend, yTick, xMaxTicksLimit } = {}) => {
    const motion = (typeof reducedMotion === 'function' && reducedMotion()) ? false : { duration: 400 };
    return {
      animation: motion,
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: legend || { display: true, position: 'bottom' },
        tooltip: {
          mode: 'index',
          callbacks: {
            ...(tooltipLabel ? { label: tooltipLabel } : {}),
            ...(tooltipFooter ? { footer: tooltipFooter } : {}),
          }
        }
      },
      scales: {
        x: { grid: { display: false }, ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: xMaxTicksLimit || 10 } },
        y: {
          stacked: true,
          beginAtZero: true,
          grid: { color: '#e5e7eb', drawBorder: false, lineWidth: 1 },
          ticks: { callback: yTick || ((v) => v) }
        }
      }
    };
  };

  window.FSUtils = { formatCurrency, toggleExpanded, fetchJson, storage, reducedMotion, safeDestroy, pickYearly, createChartOptions };
})();
