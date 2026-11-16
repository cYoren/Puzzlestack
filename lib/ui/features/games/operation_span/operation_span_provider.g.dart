// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_span_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OperationSpanNotifier)
final operationSpanProvider = OperationSpanNotifierProvider._();

final class OperationSpanNotifierProvider
    extends $NotifierProvider<OperationSpanNotifier, OperationSpanState> {
  OperationSpanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'operationSpanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$operationSpanNotifierHash();

  @$internal
  @override
  OperationSpanNotifier create() => OperationSpanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OperationSpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OperationSpanState>(value),
    );
  }
}

String _$operationSpanNotifierHash() =>
    r'e0f7968c78d27bc9cb779face11b46dfed904b25';

abstract class _$OperationSpanNotifier extends $Notifier<OperationSpanState> {
  OperationSpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OperationSpanState, OperationSpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OperationSpanState, OperationSpanState>,
              OperationSpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
