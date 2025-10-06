(function() {
  const root = document.getElementById('content');
  const errorBanner = document.getElementById('error');
  const mdScript = document.getElementById('md-data');
  let md = '';
  if (mdScript) {
    const raw = mdScript.textContent || '';
    // If content is JSON (we embed via markdown.to_json), parse it to restore newlines
    const looksJsonString = raw.trim().startsWith('"') && raw.trim().endsWith('"');
    try {
      md = looksJsonString ? JSON.parse(raw) : raw;
    } catch (_) {
      md = raw; // fallback gracefully
    }
  }

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = src;
      s.async = true;
      s.onload = () => resolve();
      s.onerror = () => reject(new Error('Failed to load ' + src));
      document.head.appendChild(s);
    });
  }

  async function ensureLibraries() {
    const markedUrls = [
      'https://cdn.jsdelivr.net/npm/marked/marked.min.js',
      'https://unpkg.com/marked/marked.min.js',
      'https://cdnjs.cloudflare.com/ajax/libs/marked/12.0.2/marked.min.js'
    ];
    const mermaidUrls = [
      'https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js',
      'https://unpkg.com/mermaid/dist/mermaid.min.js',
      'https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.9.1/mermaid.min.js'
    ];
    if (!window.marked) {
      for (const u of markedUrls) {
        try { await loadScript(u); if (window.marked) break; } catch (_) {}
      }
    }
    if (!window.mermaid) {
      for (const u of mermaidUrls) {
        try { await loadScript(u); if (window.mermaid) break; } catch (_) {}
      }
      if (window.mermaid && mermaid.initialize) {
        try { mermaid.initialize({ startOnLoad: false, theme: 'default', securityLevel: 'loose' }); } catch (_) {}
      }
    }
  }

  function getMarkedParser() {
    return (window.marked && (marked.parse || marked)) || null;
  }

  function renderMarkdown() {
    try {
      const parse = getMarkedParser();
      const html = parse ? (marked.parse ? marked.parse(md) : marked(md)) : md;
      root.innerHTML = html;
    } catch (e) {
      console.warn('Marked failed, falling back to raw markdown', e);
      root.textContent = md;
    }
  }

  function mountMermaidBlocks() {
    const decode = (s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
    const selectors = ['pre code.language-mermaid','pre code.lang-mermaid','pre code[class*="mermaid"]'];
    const codeBlocks = root.querySelectorAll(selectors.join(','));
    let mounted = 0;
    codeBlocks.forEach((code) => {
      const pre = code.closest('pre') || code.parentElement;
      const graph = decode(code.textContent || '');
      const container = document.createElement('div');
      container.className = 'mermaid';
      container.textContent = graph;
      pre.replaceWith(container);
      mounted++;
    });
    if (mounted === 0) {
      const re = /```mermaid\s*([\s\S]*?)```/g;
      let m;
      let added = 0;
      while ((m = re.exec(md)) !== null) {
        const container = document.createElement('div');
        container.className = 'mermaid';
        container.textContent = decode(m[1].trim());
        root.appendChild(container);
        added++;
      }
      if (added > 0) {
        console.debug(`Mounted ${added} mermaid blocks from raw markdown fences`);
      }
    }
  }

  function runMermaid() {
    if (!window.mermaid) {
      if (errorBanner) {
        errorBanner.style.display = 'block';
        errorBanner.textContent = 'Mermaid library did not load. Are you offline or is the CDN blocked?';
      }
      return;
    }
    try {
      if (errorBanner) errorBanner.style.display = 'none';
      const blocks = root.querySelectorAll('.mermaid');
      if (blocks.length === 0) {
        console.info('No mermaid code blocks found in markdown.');
      }
      if (typeof mermaid.run === 'function') {
        mermaid.run({ querySelector: '.mermaid' });
      } else if (typeof mermaid.init === 'function') {
        mermaid.init(undefined, document.querySelectorAll('.mermaid'));
      }
    } catch (e) {
      if (errorBanner) errorBanner.style.display = 'block';
      console.error('Mermaid render error:', e);
    }
  }

  function renderAll() {
    renderMarkdown();
    mountMermaidBlocks();
    runMermaid();
  }

  (async function init() {
    try {
      await new Promise(r => setTimeout(r, 100));
      if (!window.marked || !window.mermaid) {
        await ensureLibraries();
      }
    } finally {
      renderAll();
    }
  })();

  const btn = document.getElementById('rerender');
  if (btn) btn.addEventListener('click', renderAll);
})();
