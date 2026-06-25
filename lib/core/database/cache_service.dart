// Platform ke hisaab se sahi implementation use hogi:
// Mobile (Android/iOS) → cache_service_impl.dart (SQLite)
// Web                  → cache_service_stub.dart  (empty)

export 'cache_service_stub.dart'
    if (dart.library.io) 'cache_service_impl.dart';
