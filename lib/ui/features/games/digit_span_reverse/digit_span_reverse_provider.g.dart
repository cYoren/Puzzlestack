// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digit_span_reverse_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DigitSpanReverseNotifier)
final digitSpanReverseProvider = DigitSpanReverseNotifierProvider._();

final class DigitSpanReverseNotifierProvider
    extends $NotifierProvider<DigitSpanReverseNotifier, DigitSpanState> {
  DigitSpanReverseNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'digitSpanReverseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$digitSpanReverseNotifierHash();

  @$internal
  @override
  DigitSpanReverseNotifier create() => DigitSpanReverseNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DigitSpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DigitSpanState>(value),
    );
  }
}

String _$digitSpanReverseNotifierHash() =>
    r'421e3364b74dbc7215d7307b0dab387fb5243bf7';

abstract class _$DigitSpanReverseNotifier extends $Notifier<DigitSpanState> {
  DigitSpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DigitSpanState, DigitSpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DigitSpanState, DigitSpanState>,
              DigitSpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
