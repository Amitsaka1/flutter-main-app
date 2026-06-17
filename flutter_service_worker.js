'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/gifts/16.png": "c20870b1490205d380c114227bc2f521",
"assets/assets/gifts/4.png": "56cdc127566a79978c15b564d5959e3d",
"assets/assets/gifts/27.png": "ef47aad21f870675147bfd29ae46c45c",
"assets/assets/gifts/10.png": "175bc43a6c83612db1a904cdc2028290",
"assets/assets/gifts/11.png": "176deaeab4e3929129d37cd24bd3ccbd",
"assets/assets/gifts/21.png": "7849b3794a30e99cce0fb218b854d6cf",
"assets/assets/gifts/14.png": "23e3cc0d74bfa2ea4e022e7795b80a96",
"assets/assets/gifts/2.png": "b9d8b72ab21faf0d6879a530fdc0e5c9",
"assets/assets/gifts/1.png": "ecc8c615a50642d135c5da203416de99",
"assets/assets/gifts/7.png": "cfe9dbaac8c25b3898d9967e6be5ca82",
"assets/assets/gifts/20.png": "b3ed994ef9e568cbd91cc3376f4045c1",
"assets/assets/gifts/24.png": "8c346616013c0f1120dde7c8863be50c",
"assets/assets/gifts/29.png": "ffdbde88261af1f0a1fcac8b490ff935",
"assets/assets/gifts/8.png": "18f8d0a58945193dcd855b382fed3a9c",
"assets/assets/gifts/23.png": "feda2535e28924bb0ac343773df5829d",
"assets/assets/gifts/5.png": "85bbf72143ccbcb5a94a15eb5645a650",
"assets/assets/gifts/3.png": "db2d45a2c72ecbc9f8baa0a122fa16fd",
"assets/assets/gifts/17.png": "c92e637700c551050cd04faa35ff0f29",
"assets/assets/gifts/9.png": "a5f89d73685402200740b95853b173f1",
"assets/assets/gifts/26.png": "19166ee6bd23ea49d662768790ec7cf3",
"assets/assets/gifts/22.png": "bb3b94c8df8f456cec365a31a19b8b65",
"assets/assets/gifts/19.png": "a5a8c269efbc3c0f37e4362306f23992",
"assets/assets/gifts/12.png": "7bf2eb7e8f6e77f10b8f7e79a6e127b1",
"assets/assets/gifts/25.png": "021d8e8c4a71ba57fee90b1d8d8bc0d7",
"assets/assets/gifts/13.png": "50e122eb73d384ccd78dcfdec422bb49",
"assets/assets/gifts/28.png": "2a96617ba8ebdbbe2293b2b4678380b0",
"assets/assets/gifts/6.png": "8285ab1b88b1c88d6cebe944550c88bd",
"assets/assets/gifts/18.png": "ba08b1d3e7b8873e26656922fcaf426c",
"assets/assets/gifts/15.png": "d348a6bce7df334f1960e048d10e4357",
"assets/AssetManifest.bin.json": "27bf08376a65ab509fb6f8a6dae7e95f",
"assets/fonts/MaterialIcons-Regular.otf": "77600f8a73fac1e630977b0d18f5a422",
"assets/AssetManifest.bin": "72f9589a436d970aacba66d95fa451ae",
"assets/NOTICES": "331de69b56c9e9dc23e1e7164a22df33",
"assets/AssetManifest.json": "4705ce01fde1ef581672c54d96212723",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"flutter_bootstrap.js": "a8fc2fa61f1ad1998912c0ff4e3f5bf2",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"index.html": "6d9d719be7076063779bf86289bb55b4",
"/": "6d9d719be7076063779bf86289bb55b4",
"main.dart.js": "0b875cfd702c3eb1d700cb6f191ce92c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"manifest.json": "2e4318cd8ca245e5bcad2abf20cb7471",
"version.json": "aa37f325b37fb07fe74eeaaf7a39c425"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
