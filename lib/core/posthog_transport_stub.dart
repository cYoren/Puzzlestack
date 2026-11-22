/// Fallback when neither `dart:io` nor a browser is present (analysis only).
const bool isPostHogWebBuild = false;

Future<bool> postHogPost(Uri endpoint, String body) async => false;
