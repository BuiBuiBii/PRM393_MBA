Map<String, String> mergeOAuthCallbackParams(Uri uri) {

  final merged = <String, String>{};

  for (final e in Uri.splitQueryString(uri.fragment).entries) {

    merged[e.key] = e.value;

  }

  for (final e in uri.queryParameters.entries) {

    merged.putIfAbsent(e.key, () => e.value);

  }

  return merged;

}



String? oauthErrorFromUri(Uri uri) {

  final params = mergeOAuthCallbackParams(uri);

  final error = params['error'] ?? params['error_description'] ?? params['message'];

  if (error == null || error.isEmpty) return null;

  return error;

}



/// BE login: token nằm trong fragment `#accessToken=...` (không dùng query `?`).

String? appAccessTokenFromFragment(Uri uri) {

  final fragment = Uri.splitQueryString(uri.fragment);

  for (final key in ['accessToken', 'access_token', 'token']) {

    final value = fragment[key];

    if (value != null && value.isNotEmpty) return value;

  }

  return null;

}



String? appTokenFromCallbackUri(Uri uri) {

  final fromFragment = appAccessTokenFromFragment(uri);

  if (fromFragment != null) return fromFragment;



  final query = uri.queryParameters;

  return query['token'] ?? query['accessToken'] ?? query['access_token'];

}



String? extractOAuthAuthorizeUrl(dynamic payload) {

  if (payload is String && payload.startsWith('http')) return payload;

  if (payload is! Map) return null;



  final map = Map<String, dynamic>.from(payload);

  for (final key in ['authorizeUrl', 'authUrl', 'url', 'oauthUrl', 'authorizationUrl']) {

    final value = map[key]?.toString();

    if (value != null && value.isNotEmpty) return value;

  }



  final nested = map['data'];

  if (nested != null) return extractOAuthAuthorizeUrl(nested);



  return null;

}


