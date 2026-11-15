/* LoveWorks Service Worker — Web Push + offline PWA caching */

const CACHE_NAME = 'iloveworks-v3';
const PRECACHE = ['/', '/manifest.json', '/icon-192.png', '/icon-512.png', '/apple-touch-icon.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith('/api')) return;

  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((c) => c.put('/', copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match('/'))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((c) => c.put(req, copy)).catch(() => {});
          }
          return res;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});

self.addEventListener('push', (event) => {
  let data = { title: 'iLoveWorks', body: '', link: '/' };
  try {
    if (event.data) {
      data = { ...data, ...event.data.json() };
    }
  } catch (_) {
    if (event.data) data.body = event.data.text();
  }

  const meta = data.meta || {};
  const isAlarm = meta.kind === 'alarm';
  const options = {
    body: data.body || '',
    icon: '/icon-192.png',
    badge: '/badge-96.png',
    tag: isAlarm ? `alarm-${meta.alarm_id}` : (meta.task_id ? `task-${meta.task_id}` : undefined),
    renotify: true,
    requireInteraction: isAlarm,
    data: { link: data.link || '/', meta },
    vibrate: isAlarm ? [400, 150, 400, 150, 400] : [120, 60, 120],
  };

  event.waitUntil(self.registration.showNotification(data.title || 'iLoveWorks', options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.link) || '/';
  event.waitUntil((async () => {
    const allClients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    // Reuse an open app window and let React route there (keeps the session, no reload)
    for (const c of allClients) {
      try {
        if (new URL(c.url).origin !== self.location.origin) continue;
        await c.focus();
        c.postMessage({ type: 'navigate', link: targetUrl });
        return;
      } catch (_) { /* noop */ }
    }
    if (self.clients.openWindow) {
      await self.clients.openWindow(targetUrl);
    }
  })());
});
