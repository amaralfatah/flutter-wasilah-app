import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/backup/data/google_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('BearerTokenClient', () {
    test('adds the bearer token', () async {
      final client = BearerTokenClient(
        'token',
        inner: MockClient(
          (request) async =>
              http.Response(request.headers['Authorization'] ?? '', 200),
        ),
      );
      addTearDown(client.close);

      final response = await client.get(Uri.parse('https://example.com/'));

      expect(response.body, 'Bearer token');
    });

    test('times out when the server never answers', () async {
      final client = BearerTokenClient(
        'token',
        inner: MockClient.streaming(
          (request, _) => Completer<http.StreamedResponse>().future,
        ),
        responseTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(client.close);

      await expectLater(
        client.get(Uri.parse('https://example.com/')),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('times out when a response body stalls', () async {
      final stalled = StreamController<List<int>>();
      addTearDown(stalled.close);
      final client = BearerTokenClient(
        'token',
        inner: MockClient.streaming((request, _) async {
          stalled.add([1]);
          return http.StreamedResponse(stalled.stream, 200);
        }),
        idleTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(client.close);

      await expectLater(
        client.get(Uri.parse('https://example.com/')),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
