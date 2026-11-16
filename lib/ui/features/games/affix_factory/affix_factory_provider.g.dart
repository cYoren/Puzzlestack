// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affix_factory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AffixFactoryNotifier)
final affixFactoryProvider = AffixFactoryNotifierProvider._();

final class AffixFactoryNotifierProvider
    extends $NotifierProvider<AffixFactoryNotifier, AffixFactoryState> {
  AffixFactoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'affixFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$affixFactoryNotifierHash();

  @$internal
  @override
  AffixFactoryNotifier create() => AffixFactoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AffixFactoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AffixFactoryState>(value),
    );
  }
}

String _$affixFactoryNotifierHash() =>
    r'a7eaa3f0c26fe97fe60402e601f828ecc4c6e386';

abstract class _$AffixFactoryNotifier extends $Notifier<AffixFactoryState> {
  AffixFactoryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AffixFactoryState, AffixFactoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AffixFactoryState, AffixFactoryState>,
              AffixFactoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
