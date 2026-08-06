import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  // OAuth client ID tipe "Web application" dari Google Cloud Console.
  // Wajib di Android (google_sign_in v7) sebagai serverClientId.
  static const String _serverClientId =
      '407290386438-du0aleupabs17sup5hf3prldjkjer988'
      '.apps.googleusercontent.com';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _signIn.authenticationEvents;

  Future<void> ensureInitialized() {
    return _initialization ??= _signIn
        .initialize(serverClientId: _serverClientId)
        .catchError((Object error) {
          _initialization = null;
          throw error;
        });
  }

  Future<GoogleSignInAccount> signIn() async {
    await ensureInitialized();
    return _signIn.authenticate(scopeHint: scopes);
  }

  Future<void> disconnect() async {
    await ensureInitialized();
    await _signIn.disconnect();
  }

  /// Klien HTTP ber-token untuk Drive.
  ///
  /// Otorisasi terpisah dari autentikasi: token scope diambil dari grant yang
  /// sudah di-cache platform, jadi tidak perlu `GoogleSignInAccount` hasil
  /// sign-in ulang dan tidak memunculkan UI Credential Manager. [account]
  /// hanya dipakai bila kebetulan tersedia (tepat setelah sign-in interaktif);
  /// selebihnya jatuh ke authorization client tingkat instance.
  Future<http.Client?> authenticatedHttpClient({
    GoogleSignInAccount? account,
    bool promptIfNecessary = false,
  }) async {
    await ensureInitialized();
    final authorizationClient =
        account?.authorizationClient ?? _signIn.authorizationClient;

    var authorization = await authorizationClient.authorizationForScopes(
      scopes,
    );
    if (authorization == null && promptIfNecessary) {
      authorization = await authorizationClient.authorizeScopes(scopes);
    }

    if (authorization == null) {
      return null;
    }

    return _BearerTokenClient(authorization.accessToken);
  }
}

class _BearerTokenClient extends http.BaseClient {
  _BearerTokenClient(this._accessToken);

  final String _accessToken;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
