import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _signIn.initialize(serverClientId: _serverClientId);
    } on Object {
      // Boleh dicoba lagi pada panggilan berikutnya.
      _initialization = null;
      rethrow;
    }
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

    return BearerTokenClient(authorization.accessToken);
  }
}

/// Klien HTTP yang menyisipkan token Drive dan membatasi waktu tunggu.
///
/// Tanpa batas waktu, koneksi yang menggantung membuat backup/restore tidak
/// pernah selesai (`isBackingUp` tertahan true). [TimeoutException] yang
/// dilempar di sini dianggap gangguan jaringan sesaat oleh
/// `isTransientNetworkError`, jadi tetap dicoba ulang sekali.
class BearerTokenClient extends http.BaseClient {
  BearerTokenClient(
    this._accessToken, {
    http.Client? inner,
    this.responseTimeout = const Duration(seconds: 30),
    this.uploadResponseTimeout = const Duration(minutes: 2),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _inner = inner ?? _defaultClient();

  static const Duration _connectionTimeout = Duration(seconds: 30);

  final String _accessToken;
  final http.Client _inner;

  /// Batas menunggu header respons untuk request biasa.
  final Duration responseTimeout;

  /// Batas menunggu header respons untuk upload: isi file dikirim dulu
  /// sebelum respons datang, jadi butuh rentang lebih panjang.
  final Duration uploadResponseTimeout;

  /// Batas jeda antar potongan data saat body respons (mis. download backup)
  /// dialirkan. Berbasis jeda, bukan total, supaya file besar di koneksi
  /// lambat tetap bisa selesai selama datanya terus mengalir.
  final Duration idleTimeout;

  static http.Client _defaultClient() =>
      IOClient(HttpClient()..connectionTimeout = _connectionTimeout);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    final isUpload = request.url.path.startsWith('/upload/');
    final response = await _inner
        .send(request)
        .timeout(isUpload ? uploadResponseTimeout : responseTimeout);
    return http.StreamedResponse(
      response.stream.timeout(idleTimeout),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
