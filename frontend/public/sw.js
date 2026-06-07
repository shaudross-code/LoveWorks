/* ClockWork Service Worker — receives Web Push for task reminders & admin events */

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = { title: 'ClockWork', body: '', link: '/' };
  try {
    if (event.data) {
      data = { ...data, ...event.data.json() };
    }
  } catch (_) {
    if (event.data) data.body = event.data.text();
  }

  const options = {
    body: data.body || '',
    icon: '/clockwork-icon.png',
    badge: '/clockwork-badge.png',
    tag: (data.meta && data.meta.task_id) ? `task-${data.meta.task_id}` : undefined,
    renotify: true,
    data: { link: data.link || '/', meta: data.meta || {} },
    vibrate: [120, 60, 120],
  };

  event.waitUntil(self.registration.showNotification(data.title || 'ClockWork', options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.link) || '/';
  event.waitUntil((async () => {
    const allClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of allClients) {
      try {
        const u = new URL(c.url);
        if (u.pathname.startsWith(targetUrl) || c.url.includes(targetUrl)) {
          await c.focus();
          return;
        }
      } catch (_) { /* noop */ }
    }
    if (clients.openWindow) {
      await clients.openWindow(targetUrl);
    }
  })());
});
