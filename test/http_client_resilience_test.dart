import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenith/core/privacy_engine/api/zenith_api_contract.dart';

void main() {
  final request = AnalyzeImageRequest(
    imageBytes: Uint8List.fromList([1, 2, 3]),
  );

  test(
    'remote analysis reports missing production API configuration',
    () async {
      final client = ZenithHttpClient(
        baseUrl: '',
        client: MockClient((_) async => http.Response('', 200)),
      );
      await expectLater(
        client.analyzeImage(request),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'site owner must set the production API URL',
            ),
          ),
        ),
      );
    },
  );

  test('remote analysis reports structured server errors without raw response data', () async {
    final client = ZenithHttpClient(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (_) async => http.Response(
          '{"title":"Gemini Credentials Required","detail":"configure GEMINI_API_KEY on the backend"}',
          503,
        ),
      ),
    );
    await expectLater(
      client.analyzeImage(request),
      throwsA(
        predicate(
          (error) => error.toString().contains('contact the site owner'),
        ),
      ),
    );
  });

  test('remote analysis rejects malformed successful JSON', () async {
    final client = ZenithHttpClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(
      client.analyzeImage(request),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('server returned an invalid response'),
        ),
      ),
    );
  });

  test('remote analysis handles HTTP 429 rate limiting with clear message', () async {
    final client = ZenithHttpClient(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (_) async => http.Response(
          '{"title":"Too Many Requests","detail":"rate limit reached"}',
          429,
        ),
      ),
    );
    await expectLater(
      client.analyzeImage(request),
      throwsA(
        predicate(
          (error) => error.toString().contains('quota is exhausted'),
        ),
      ),
    );
  });

  test('remote analysis handles HTTP 422 unprocessable entity with validation detail', () async {
    final client = ZenithHttpClient(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (_) async => http.Response(
          '{"title":"Validation Failed","detail":"Image dimensions exceed maximum limits"}',
          422,
        ),
      ),
    );
    await expectLater(
      client.analyzeImage(request),
      throwsA(
        predicate(
          (error) => error.toString().contains('Image dimensions exceed maximum limits'),
        ),
      ),
    );
  });

  test('checkHealth successfully fetches and decodes health payload', () async {
    final client = ZenithHttpClient(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (req) async {
          expect(req.url.path, '/health');
          return http.Response(
            '{"status":"healthy","service":"zenith-privacy-intelligence-engine","version":"1.0.0","geminiConfigured":true,"provider":"gemini"}',
            200,
          );
        },
      ),
    );
    final health = await client.checkHealth();
    expect(health['status'], 'healthy');
    expect(health['geminiConfigured'], true);
    expect(health['provider'], 'gemini');
  });

  test('checkHealth throws clear error if backend URL is not configured', () async {
    final client = ZenithHttpClient(
      baseUrl: '',
      client: MockClient((_) async => http.Response('', 200)),
    );
    await expectLater(
      client.checkHealth(),
      throwsA(
        predicate(
          (error) => error.toString().contains('site owner must set the production API URL'),
        ),
      ),
    );
  });
}
