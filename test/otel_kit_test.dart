// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_kit/otel_kit.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_kit-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('broadcasts.send records broadcast status + tier', () async {
    await tracedKit<String>(
      operation: 'broadcasts.send',
      invoke: () async => const KitCallResult(
        value: 'ok',
        result: KitResult(
          broadcastStatus: 'sending',
          tier: 'creator_pro',
          totalSubscribers: 12450,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('kit broadcasts.send')!);
    expect(a['kit.broadcast.status'], 'sending');
    expect(a['kit.tier'], 'creator_pro');
    expect(a['kit.total_subscribers'], 12450);
  });

  test('failed broadcast sets span error', () async {
    await tracedKit<String>(
      operation: 'broadcasts.send',
      invoke: () async => const KitCallResult(
        value: 'ok',
        result: KitResult(broadcastStatus: 'failed'),
      ),
    );
    expect(
      spans.findSpanByName('kit broadcasts.send')!.status,
      SpanStatusCode.Error,
    );
  });

  test('purchase records amount', () async {
    await tracedKit<String>(
      operation: 'purchases.create',
      invoke: () async => const KitCallResult(
        value: 'ok',
        result: KitResult(purchaseAmountMinor: 4900, currency: 'USD'),
      ),
    );
    final a = attrsOf(spans.findSpanByName('kit purchases.create')!);
    expect(a['kit.purchase.amount.minor'], 4900);
    expect(a['kit.currency'], 'USD');
  });

  test('suppression skips spans', () async {
    await runWithoutKitInstrumentationAsync(() async {
      await tracedKit<String>(
        operation: 'subscribers.list',
        invoke: () async => const KitCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('kit '), isEmpty);
  });
}
