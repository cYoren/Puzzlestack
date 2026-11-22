// Chooses the one POST this app can make: `dart:io` on a device, nothing in the
// browser build. Kept apart from `posthog.dart` for that reason only.
export 'posthog_transport_stub.dart'
    if (dart.library.io) 'posthog_transport_io.dart'
    if (dart.library.js_interop) 'posthog_transport_web.dart';
