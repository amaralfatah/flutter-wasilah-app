import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _initialization;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _signIn.authenticationEvents;

  Future<void> ensureInitialized() {
    return _initialization ??= _signIn.initialize().catchError((error) {
      _initialization = null;
      throw error;
    });
  }

  Future<GoogleSignInAccount?> attemptSilentSignIn() async {
    await ensureInitialized();
    return _signIn.attemptLightweightAuthentication();
  }

  Future<GoogleSignInAccount> signIn() async {
    await ensureInitialized();
    return _signIn.authenticate(scopeHint: scopes);
  }

  Future<void> disconnect() async {
    await ensureInitialized();
    await _signIn.disconnect();
  }

  Future<http.Client?> authenticatedHttpClient(
    GoogleSignInAccount account, {
    bool promptIfNecessary = false,
  }) async {
    final authorization = promptIfNecessary
        ? await account.authorizationClient.authorizeScopes(scopes)
        : await account.authorizationClient.authorizationForScopes(scopes);

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
