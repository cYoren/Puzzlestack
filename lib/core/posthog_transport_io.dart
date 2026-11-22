import 'dart:io';

/// True only in the browser build, where this module sends nothing.
const bool isPostHogWebBuild = false;

/// One plain HTTPS POST. Never throws: a failed send is not the player's
/// problem, and analytics is not worth a retry.
Future<bool> postHogPost(Uri endpoint, String body) async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);
  try {
    final HttpClientRequest request =
        await client.postUrl(endpoint).timeout(const Duration(seconds: 4));
    request.headers.contentType = ContentType.json;
    request.write(body);
    final HttpClientResponse response = await request.close().timeout(
          const Duration(seconds: 5),
        );
    await response.drain<void>();
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
