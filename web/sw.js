const CACHE = 'doselab-v3';
const ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/data/zh_drug_map.json'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  clients.claim();
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (e.request.url.includes('api.fda.gov')) return;
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request).then(resp => {
        if (resp.ok) {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put('/index.html', clone));
        }
        return resp;
      }).catch(() => caches.match('/index.html'))
    );
    return;
  }
  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetched = fetch(e.request).then(resp => {
        if (resp.ok) {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => cached);
      return cached || fetched;
    })
  );
});

self.addEventListener('push', e => {
  const data = e.data?.json() || {};
  const title = data.title || 'DoseLab';
  const options = {
    body: data.body || '',
    icon: data.icon || '/icon-192.png',
    badge: data.badge,
    tag: data.tag || 'doselab-dose',
    renotify: true,
    requireInteraction: true,
    data: data.url ? { url: data.url } : {},
    vibrate: [200, 100, 200],
    actions: data.actions || []
  };
  e.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = e.notification.data?.url || '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(windows => {
      for (const w of windows) {
        if (w.url.includes(self.registration.scope)) {
          w.focus();
          w.postMessage({ action: 'navigate', url });
          return;
        }
      }
      return clients.openWindow(url);
    })
  );
});
