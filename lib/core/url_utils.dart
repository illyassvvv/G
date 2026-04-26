class UrlUtils {
  const UrlUtils._();

  static Uri? tryParseNetworkUrl(
    String raw, {
    bool allowHttp = true,
    bool allowHttps = true,
  }) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    final allowed = (allowHttp && scheme == 'http') ||
        (allowHttps && scheme == 'https');
    return allowed ? uri : null;
  }

  static bool isSafeNetworkUrl(
    String raw, {
    bool allowHttp = true,
    bool allowHttps = true,
  }) =>
      tryParseNetworkUrl(
        raw,
        allowHttp: allowHttp,
        allowHttps: allowHttps,
      ) != null;
}
