// 猫事 · CatCare Service Worker
// 作用：离线可用 —— 预缓存 App Shell，导航请求走 network-first，静态资源走 stale-while-revalidate。
// 版本号：修改 App Shell 资源列表后，请同步递增 CACHE 版本以触发更新。

const CACHE = 'catcare-v1';

// App Shell 预缓存资源。使用 allSettled 容错：个别文件缺失不会导致安装失败。
const PRECACHE = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  './icon-192.png',
  './icon-512.png',
  './knowledge-data.js',
];

// 安装：预缓存 App Shell（容错），并立即接管等待中的客户端。
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.allSettled(PRECACHE.map((url) => cache.add(url)))
    )
  );
});

// 激活：清理旧版本缓存，并立即接管所有页面。
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))
      );
      await self.clients.claim();
    })()
  );
});

// 请求拦截：只处理同源 GET；跨域、非 http(s) 协议以及 POST 等一律放行。
self.addEventListener('fetch', (event) => {
  const req = event.request;

  // 只处理 GET 请求
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // 跳过非 http(s) 协议（如 chrome-extension:）
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return;

  // 只处理同源请求
  if (url.origin !== self.location.origin) return;

  // 导航请求：network-first，失败时回退到缓存的 index.html
  if (req.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          // 在线优先，拿到最新页面
          const fresh = await fetch(req);
          const cache = await caches.open(CACHE);
          cache.put('./index.html', fresh.clone());
          return fresh;
        } catch (err) {
          // 离线回退：优先匹配请求本身，再回退到缓存的 index.html
          const cache = await caches.open(CACHE);
          const cached = (await cache.match(req)) || (await cache.match('./index.html'));
          if (cached) return cached;
          throw err;
        }
      })()
    );
    return;
  }

  // 其它同源静态资源：stale-while-revalidate（先返回缓存，同时后台更新）
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(req);

      const network = fetch(req)
        .then((res) => {
          // 只缓存有效的同源响应
          if (res && res.status === 200 && res.type === 'basic') {
            cache.put(req, res.clone());
          }
          return res;
        })
        .catch(() => undefined);

      // 命中缓存则立即返回，否则等待网络
      return cached || (await network) || Response.error();
    })()
  );
});
