// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_kit_suppression.dart';

const _tracerName = 'dartastic_otel_libs_kit';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class KitResult {
  const KitResult({
    this.itemCount,
    this.totalSubscribers,
    this.subscriberState,
    this.broadcastStatus,
    this.sequenceStatus,
    this.formKind,
    this.purchaseAmountMinor,
    this.currency,
    this.tier,
    this.requestId,
    this.statusCode,
  });

  /// Items in collection.
  final int? itemCount;

  /// `total_subscribers` from account.
  final int? totalSubscribers;

  /// `active` / `inactive` / `bounced` / `complained` / `cancelled`
  /// — Kit bills per active subscriber.
  final String? subscriberState;

  /// `draft` / `scheduled` / `sending` / `sent` / `paused` /
  /// `failed`.
  final String? broadcastStatus;

  /// `active` / `paused` / `archived`.
  final String? sequenceStatus;

  /// `inline` / `modal` / `slidein` / `sticky_bar` / `landing_page`.
  final String? formKind;

  /// Purchase amount in minor units (Kit Commerce).
  final int? purchaseAmountMinor;

  /// ISO 4217.
  final String? currency;

  /// `free` / `creator` / `creator_pro`.
  final String? tier;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class KitCallResult<T> {
  const KitCallResult({required this.value, this.result});
  final T value;
  final KitResult? result;
}

/// Wraps a Kit (ConvertKit) v4 API call in a CLIENT span. [operation]
/// is one of `subscribers.list`, `subscribers.create`,
/// `subscribers.update`, `subscribers.unsubscribe`,
/// `subscribers.tags.list`, `subscribers.tags.add`, `tags.list`,
/// `tags.create`, `broadcasts.list`, `broadcasts.create`,
/// `broadcasts.send`, `sequences.list`, `sequences.subscribers.add`,
/// `forms.list`, `forms.subscribers.add`, `purchases.list`,
/// `purchases.create`, `webhooks.create`, `account.get`.
Future<T> tracedKit<T>({
  required String operation,
  required Future<KitCallResult<T>> Function() invoke,
}) async {
  if (kitInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'kit',
    'rpc.method': operation,
    'kit.operation': operation,
  };

  final span = _tracer().startSpan(
    'kit $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'kit.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalSubscribers != null) {
        extras.add(OTel.attributeInt(
          'kit.total_subscribers',
          r.result!.totalSubscribers!,
        ));
      }
      if (r.result!.subscriberState != null) {
        extras.add(OTel.attributeString(
          'kit.subscriber.state',
          r.result!.subscriberState!,
        ));
      }
      if (r.result!.broadcastStatus != null) {
        extras.add(OTel.attributeString(
          'kit.broadcast.status',
          r.result!.broadcastStatus!,
        ));
        if (r.result!.broadcastStatus == 'failed') {
          span.setStatus(
            SpanStatusCode.Error,
            'Kit broadcast failed',
          );
        }
      }
      if (r.result!.sequenceStatus != null) {
        extras.add(OTel.attributeString(
          'kit.sequence.status',
          r.result!.sequenceStatus!,
        ));
      }
      if (r.result!.formKind != null) {
        extras.add(OTel.attributeString(
          'kit.form.kind',
          r.result!.formKind!,
        ));
      }
      if (r.result!.purchaseAmountMinor != null) {
        extras.add(OTel.attributeInt(
          'kit.purchase.amount.minor',
          r.result!.purchaseAmountMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'kit.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTel.attributeString('kit.tier', r.result!.tier!));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'kit.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Kit HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
