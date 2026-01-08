// pwa_service_worker.js – offline‑first 캐시 전략
const CACHE_NAME = 'vibe-note-pwa-v1';
const ASSETS = [
    '/',
    '/index.html',
    '/manifest.json',
    '/favicon.png',
    '/icons/vibe-note192.png',
    '/icons/vibe-note512.png',
    '/flutter_bootstrap.js',
    // Flutter‑generated files will be added during build (e.g., main.dart.js, flutter.js)
];

// 설치 단계: 정적 파일을 캐시
self.addEventListener('install', (e) => {
    e.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
    );
    self.skipWaiting();
});

// 활성화 단계: 오래된 캐시 정리
self.addEventListener('activate', (e) => {
    e.waitUntil(
        caches.keys().then((keys) =>
            Promise.all(
                keys.filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            )
        )
    );
    self.clients.claim();
});

// 네트워크 요청 가로채기: 캐시 우선, 네트워크 fallback
self.addEventListener('fetch', (e) => {
    if (e.request.method !== 'GET') return;
    e.respondWith(
        caches.match(e.request).then((cached) => {
            return (
                cached ||
                fetch(e.request)
                    .then((resp) => {
                        // 동적 파일도 캐시 (예: Flutter WASM)
                        const clone = resp.clone();
                        caches.open(CACHE_NAME).then((cache) => cache.put(e.request, clone));
                        return resp;
                    })
                    .catch(() => caches.match('/offline.html')) // 필요 시 offline 페이지 추가
            );
        })
    );
});
