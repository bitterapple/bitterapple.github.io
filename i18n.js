(() => {
  'use strict';
  const key = 'bitterapple.site.language.v1';
  const links = [...document.querySelectorAll('.languageOptions a[data-language]')];
  if (!links.length) return;
  const supported = new Map(links.map(a => [a.dataset.language, a]));
  const stored = () => { try { return localStorage.getItem(key); } catch (_) { return null; } };
  const save = code => { try { localStorage.setItem(key, code); return true; } catch (_) { return false; } };
  links.forEach(a => a.addEventListener('click', () => save(a.dataset.language)));
  const root = document.querySelector('script[data-site-root]')?.dataset.siteRoot;
  // Only the original landing URL participates in automatic selection.
  // Never redirect deep links, explicit language URLs, queries or fragments.
  if (!root || location.pathname !== root || location.search || location.hash) return;
  function resolve(tag) {
    const value = String(tag || '').toLowerCase().replace(/_/g, '-');
    if (/^zh(?:-|$)/.test(value)) return /(?:^|-)(hant|tw|hk|mo)(?:-|$)/.test(value) ? 'zh-Hant' : 'zh-Hans';
    const primary = value.split('-')[0];
    return supported.has(primary) ? primary : null;
  }
  const preference = stored();
  const code = supported.has(preference) ? preference :
    (navigator.languages || [navigator.language]).map(resolve).find(Boolean) || 'en';
  // If storage is blocked, keep explicit English navigation usable.
  if (!save(code)) return;
  if (code !== 'en') location.replace(supported.get(code).href);
})();
