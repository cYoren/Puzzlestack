/// The browser build: the app sends nothing from here. The site's own pages
/// carry `docs/js/analytics.js`, which is where web play is counted.
const bool isPostHogWebBuild = true;

Future<bool> postHogPost(Uri endpoint, String body) async => false;
