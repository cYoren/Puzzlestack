// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_shift_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BaseShiftNotifier)
final baseShiftProvider = BaseShiftNotifierProvider._();

final class BaseShiftNotifierProvider
    extends $NotifierProvider<BaseShiftNotifier, BaseShiftState> {
  BaseShiftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baseShiftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baseShiftNotifierHash();

  @$internal
  @override
  BaseShiftNotifier create() => BaseShiftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaseShiftState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaseShiftState>(value),
    );
  }
}

String _$baseShiftNotifierHash() => r'ff4970e7795c35cb1941247c888a751dd246d57f';

abstract class _$BaseShiftNotifier extends $Notifier<BaseShiftState> {
  BaseShiftState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BaseShiftState, BaseShiftState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BaseShiftState, BaseShiftState>,
              BaseShiftState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
