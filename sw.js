/**
 * LilyJoe Textiles ERP - Service Worker
 * Enables offline functionality, caching, and background sync
 */

const CACHE_NAME = "lilyjoe-textiles-v1.0.0"
const STATIC_CACHE = "lilyjoe-static-v1.0.0"
const DYNAMIC_CACHE = "lilyjoe-dynamic-v1.0.0"

// Static assets to cache - relative paths support any XAMPP folder name
const STATIC_ASSETS = [
  "./",
  "./login.html",
  "./erp-hub.html",
  "./pos.html",
  "./inventory.html",
  "./config.js",
  "./manifest.json",
  "./offline.html",
  "https://cdn.tailwindcss.com",
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css",
  "https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js",
]

// Install event - cache static assets
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(STATIC_CACHE)
      .then((cache) => {
        console.log("[SW] Caching static assets")
        return cache.addAll(STATIC_ASSETS.filter((url) => !url.startsWith("http")))
      })
      .then(() => self.skipWaiting()),
  )
})

// Activate event - clean old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== STATIC_CACHE && name !== DYNAMIC_CACHE)
            .map((name) => {
              console.log("[SW] Deleting old cache:", name)
              return caches.delete(name)
            }),
        )
      })
      .then(() => self.clients.claim()),
  )
})

// Fetch event - network first for API, cache first for static
self.addEventListener("fetch", (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Skip non-GET requests
  if (request.method !== "GET") {
    return
  }

  // API requests - network first, no cache
  if (url.pathname.includes("/api/")) {
    event.respondWith(
      fetch(request).catch(() => {
        return new Response(
          JSON.stringify({
            success: false,
            message: "You are offline. Please check your connection.",
            offline: true,
          }),
          {
            headers: { "Content-Type": "application/json" },
          },
        )
      }),
    )
    return
  }

  // Static assets - cache first, then network
  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached and update in background
        event.waitUntil(
          fetch(request)
            .then((networkResponse) => {
              if (networkResponse.ok) {
                caches.open(DYNAMIC_CACHE).then((cache) => cache.put(request, networkResponse))
              }
            })
            .catch(() => {}),
        )
        return cachedResponse
      }

      // Not in cache - fetch from network
      return fetch(request)
        .then((networkResponse) => {
          if (networkResponse.ok) {
            const responseClone = networkResponse.clone()
            caches.open(DYNAMIC_CACHE).then((cache) => cache.put(request, responseClone))
          }
          return networkResponse
        })
        .catch(() => {
          // Offline fallback for HTML pages
          if (request.headers.get("accept") && request.headers.get("accept").includes("text/html")) {
            return caches.match("./offline.html")
          }
        })
    }),
  )
})

// Background sync for offline sales
self.addEventListener("sync", (event) => {
  if (event.tag === "sync-sales") {
    event.waitUntil(syncPendingSales())
  }
  if (event.tag === "sync-inventory") {
    event.waitUntil(syncPendingInventory())
  }
})

async function syncPendingSales() {
  const db = await openIndexedDB()
  const pendingSales = await getAll(db, "pending_sales")

  for (const sale of pendingSales) {
    try {
      const response = await fetch("api/sales/index.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(sale.data),
      })

      if (response.ok) {
        await deleteItem(db, "pending_sales", sale.id)
        self.clients.matchAll().then((clients) => {
          clients.forEach((client) => {
            client.postMessage({ type: "SALE_SYNCED", id: sale.id })
          })
        })
      }
    } catch (error) {
      console.error("[SW] Failed to sync sale:", error)
    }
  }
}

async function syncPendingInventory() {
  const db = await openIndexedDB()
  const pendingUpdates = await getAll(db, "pending_inventory")

  for (const update of pendingUpdates) {
    try {
      const response = await fetch("api/products/index.php", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(update.data),
      })

      if (response.ok) {
        await deleteItem(db, "pending_inventory", update.id)
      }
    } catch (error) {
      console.error("[SW] Failed to sync inventory:", error)
    }
  }
}

// IndexedDB helpers
function openIndexedDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open("lilyjoe_offline", 1)
    request.onerror = () => reject(request.error)
    request.onsuccess = () => resolve(request.result)
    request.onupgradeneeded = (event) => {
      const db = event.target.result
      if (!db.objectStoreNames.contains("pending_sales")) {
        db.createObjectStore("pending_sales", { keyPath: "id", autoIncrement: true })
      }
      if (!db.objectStoreNames.contains("pending_inventory")) {
        db.createObjectStore("pending_inventory", { keyPath: "id", autoIncrement: true })
      }
    }
  })
}

function getAll(db, storeName) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, "readonly")
    const store = transaction.objectStore(storeName)
    const request = store.getAll()
    request.onerror = () => reject(request.error)
    request.onsuccess = () => resolve(request.result)
  })
}

function deleteItem(db, storeName, id) {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, "readwrite")
    const store = transaction.objectStore(storeName)
    const request = store.delete(id)
    request.onerror = () => reject(request.error)
    request.onsuccess = () => resolve()
  })
}

// Push notification handler
self.addEventListener("push", (event) => {
  const data = event.data?.json() || { title: "LilyJoe Textiles", body: "New notification" }

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: "./public/apple-icon.png",
      badge: "./public/icon-light-32x32.png",
      vibrate: [200, 100, 200],
      data: data.url || "./",
    }),
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  event.waitUntil(clients.openWindow(event.notification.data))
})
