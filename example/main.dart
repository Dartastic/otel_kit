// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_kit/otel_kit.dart';

/// Traces Kit (ConvertKit) v4 calls with OpenTelemetry.
///
/// `otel_kit` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Kit (ConvertKit) v4 call in
/// [tracedKit]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'kit-example');

  // Wraps a Kit (ConvertKit) v4 API call in a CLIENT span.
  final kitId = await tracedKit<String>(
    operation: 'subscribers.create',
    invoke: () async {
      // Make the Kit (ConvertKit) v4 call here, then report what it returned.
      const id = 'kit_8f3a2c';
      return const KitCallResult(
          value: id,
          result: KitResult(
              itemCount: 3,
              totalSubscribers: 1,
              subscriberState: 'active',
              broadcastStatus: 'draft',
              sequenceStatus: 'active',
              formKind: 'inline',
              purchaseAmountMinor: 1999,
              currency: 'usd',
              tier: 'free',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedKit subscribers.create returned $kitId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutKitInstrumentationAsync.
  await runWithoutKitInstrumentationAsync(
    () => tracedKit<String>(
      operation: 'subscribers.create',
      invoke: () async {
        const id = 'kit_8f3a2c';
        return const KitCallResult(
            value: id,
            result: KitResult(
                itemCount: 3,
                totalSubscribers: 1,
                subscriberState: 'active',
                broadcastStatus: 'draft',
                sequenceStatus: 'active',
                formKind: 'inline',
                purchaseAmountMinor: 1999,
                currency: 'usd',
                tier: 'free',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
