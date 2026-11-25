(function initializeLanguage(doc, loc, nav, storage, session, parseURL) {
  'use strict';
  const key = 'bitterapple.site.language.v1';
  const links = [...doc.querySelectorAll('.languageOptions a[data-language]')];
  if (!links.length) return;
  const supported = new Map(links.map(a => [a.dataset.language, a]));
  const read = store => { try { return store && store.getItem(key); } catch (_) { return null; } };
  const write = (store, code) => { try { if (!store) return false; store.setItem(key, code); return true; } catch (_) { return false; } };
  const save = code => { const persistent = write(storage, code); const temporary = write(session, code); return persistent || temporary; };
  links.forEach(a => a.addEventListener('click', () => {
    if (!save(a.dataset.language) && a.dataset.language === 'en') {
      const target = parseURL(a.href);
      target.searchParams.set('lang', 'en');
      a.href = target.href;
    }
  }));
  // Explicit localized URLs are authoritative. Redirect only known English
  // equivalents, not download, invitation or other functional routes.
  const normalize = path => path.replace(/\/index\.html$/, '/');
  if (doc.documentElement.lang !== 'en' || !supported.has('en')) return;
  if (normalize(loc.pathname) !== normalize(parseURL(supported.get('en').href).pathname)) return;
  if (parseURL(loc.href).searchParams.get('lang') === 'en') return;
  const preference = read(session) || read(storage);
  if (supported.has(preference) && preference === 'en') return;
  // English documentation links from translated pages must remain usable
  // even if the English fallback is the only complete version of a page.
  try {
    const from = parseURL(doc.referrer);
    if (from.origin === loc.origin && links.some(a => {
      if (a.dataset.language === 'en') return false;
      const english = parseURL(supported.get('en').href).pathname;
      const localized = parseURL(a.href).pathname;
      const prefix = localized.slice(0, localized.length - english.length + 1);
      return from.pathname.startsWith(prefix);
    })) return;
  } catch (_) {}
  function resolve(tag) {
    const value = String(tag || '').toLowerCase().replace(/_/g, '-');
    if (/^zh(?:-|$)/.test(value)) return /(?:^|-)hant(?:-|$)/.test(value) ? 'zh-Hant' : /(?:^|-)hans(?:-|$)/.test(value) ? 'zh-Hans' : /(?:^|-)(tw|hk|mo)(?:-|$)/.test(value) ? 'zh-Hant' : 'zh-Hans';
    const primary = value.split('-')[0];
    return supported.has(primary) ? primary : null;
  }
  const code = supported.has(preference) ? preference :
    (nav.languages?.length ? nav.languages : [nav.language]).map(resolve).find(Boolean) || 'en';
  if (code !== 'en') {
    const target = parseURL(supported.get(code).href);
    target.search = loc.search;
    target.hash = loc.hash;
    loc.replace(target.href);
  }
})(document, location, navigator, (() => { try { return localStorage; } catch (_) { return null; } })(), (() => { try { return sessionStorage; } catch (_) { return null; } })(), value => new URL(value));
