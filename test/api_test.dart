import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h2go/data/api_client.dart';
import 'package:h2go/widgets/feedback_sheet.dart';
import 'package:h2go/widgets/tip_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

ApiClient _api(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(baseUrl: 'https://api.test/', httpClient: MockClient(handler));

Widget _app(ApiClient api, Widget child) => Provider.value(
      value: api,
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('ApiClient', () {
    test('is not configured without a base URL', () async {
      final api = ApiClient(baseUrl: '');
      expect(api.configured, isFalse);
      expect(await api.todayTip(), isNull);
      expect(await api.sendFeedback(category: 'idea', message: 'hi'), isFalse);
    });

    test('reads today\'s tip', () async {
      late Uri called;
      final api = _api((req) async {
        called = req.url;
        return http.Response(
            jsonEncode({'id': 3, 'text': ' Sip before you\'re thirsty. '}), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });
      expect(await api.todayTip(), 'Sip before you\'re thirsty.');
      expect(called.toString(), 'https://api.test/v1/tips/today');
    });

    test('returns no tip on errors or unexpected bodies', () async {
      for (final res in [
        http.Response('oops', 500),
        http.Response('not json', 200),
        http.Response(jsonEncode({'tip': 'wrong field'}), 200),
        http.Response(jsonEncode({'text': '   '}), 200),
      ]) {
        expect(await _api((_) async => res).todayTip(), isNull);
      }
      expect(
          await _api((_) async => throw http.ClientException('offline'))
              .todayTip(),
          isNull);
    });

    test('posts feedback as JSON', () async {
      late http.Request sent;
      final api = _api((req) async {
        sent = req;
        return http.Response('', 201);
      });
      expect(await api.sendFeedback(category: 'bug', message: 'Crash'), isTrue);
      expect(sent.method, 'POST');
      expect(sent.url.path, '/v1/feedback');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), containsPair('message', 'Crash'));
      expect(jsonDecode(sent.body), containsPair('category', 'bug'));
    });
  });

  group('TipCard', () {
    testWidgets('shows the tip after loading', (tester) async {
      final api = _api((_) async => http.Response(
          jsonEncode({'text': 'Drink a glass with meals.'}), 200));
      await tester.pumpWidget(_app(api, const TipCard()));
      expect(find.bySemanticsLabel('Loading tip of the day'), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tip of the day'), findsOneWidget);
      expect(find.text('Drink a glass with meals.'), findsOneWidget);
    });

    testWidgets('hides itself when the API is offline', (tester) async {
      final api = _api((_) async => throw http.ClientException('offline'));
      await tester.pumpWidget(_app(api, const TipCard()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tip of the day'), findsNothing);
      expect(find.bySemanticsLabel('Loading tip of the day'), findsNothing);
    });

    testWidgets('renders nothing when the API is not configured',
        (tester) async {
      await tester.pumpWidget(_app(ApiClient(baseUrl: ''), const TipCard()));
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.bySemanticsLabel('Loading tip of the day'), findsNothing);
    });
  });

  group('Feedback sheet', () {
    Future<void> open(WidgetTester tester, ApiClient api) async {
      await tester.pumpWidget(_app(
        api,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showFeedbackSheet(context),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'More reminder sounds');
      await tester.pump();
    }

    testWidgets('sends, closes and thanks the user', (tester) async {
      await open(tester, _api((_) async => http.Response('', 201)));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Thanks! Your feedback was sent.'), findsOneWidget);
    });

    testWidgets('stays open with an error when sending fails', (tester) async {
      await open(tester, _api((_) async => http.Response('', 503)));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Couldn\'t send'), findsOneWidget);
    });
  });
}
