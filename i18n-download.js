(() => {
  'use strict';
  const node = document.getElementById('download-locales');
  if (!node) return;
  const table = JSON.parse(node.textContent);
  let lang = null;
  try {
    const ref = new URL(document.referrer);
    if (ref.origin === location.origin) {
      const first = ref.pathname.split('/')[1];
      lang = Object.prototype.hasOwnProperty.call(table, first) ? first : 'en';
    }
  } catch (_) {}
  if (!lang) {
    try { lang = localStorage.getItem('bitterapple.site.language.v1'); } catch (_) {}
  }
  if (!Object.prototype.hasOwnProperty.call(table, lang)) {
    for (const raw of (navigator.languages || [navigator.language])) {
      const tag = String(raw).toLowerCase();
      const primary = tag.split('-')[0];
      const code = primary === 'zh' ? (/(?:^|-)(hant|tw|hk|mo)(?:-|$)/.test(tag) ? 'zh-Hant' : 'zh-Hans') : primary;
      if (Object.prototype.hasOwnProperty.call(table, code)) { lang = code; break; }
    }
  }
  if (!Object.prototype.hasOwnProperty.call(table, lang)) lang = 'en';
  const t = table[lang];
  document.documentElement.lang = lang;
  document.querySelectorAll('[data-download-text]').forEach(el => {
    const value = t[el.dataset.downloadText];
    if (typeof value === 'string') el.textContent = value;
  });
})();
