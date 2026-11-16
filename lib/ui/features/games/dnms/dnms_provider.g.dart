// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dnms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DnmsNotifier)
final dnmsProvider = DnmsNotifierProvider._();

final class DnmsNotifierProvider
    extends $NotifierProvider<DnmsNotifier, DnmsState> {
  DnmsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dnmsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dnmsNotifierHash();

  @$internal
  @override
  DnmsNotifier create() => DnmsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DnmsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DnmsState>(value),
    );
  }
}

String _$dnmsNotifierHash() => r'54edd153a203c92f695ec9779f1dfcfcce6488e4';

abstract class _$DnmsNotifier extends $Notifier<DnmsState> {
  DnmsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DnmsState, DnmsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DnmsState, DnmsState>,
              DnmsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
