const CACHE_VERSION = 'doselab-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/flutter_bootstrap.js',
  '/sql-wasm.js',
  '/sql-wasm.wasm',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      return cache.addAll(STATIC_ASSETS).catch((err) => {
        console.warn('DoseLab SW: precache partial', err);
      });
    }),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((k) => k !== CACHE_VERSION)
          .map((k) => caches.delete(k)),
      );
    }),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Never cache openFDA or external analytics requests
  if (
    url.hostname !== self.location.hostname ||
    url.pathname.startsWith('/api/')
  ) {
    return;
  }

  // Cache-first for same-origin static assets
  event.respondWith(
    caches.match(event.request).then((cached) => {
      const fetchPromise = fetch(event.request).then((response) => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_VERSION).then((cache) => {
            cache.put(event.request, clone);
          });
        }
        return response;
      });
      return cached || fetchPromise;
    }),
  );
});
