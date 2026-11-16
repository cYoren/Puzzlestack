// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etymon_oddball_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EtymonOddballNotifier)
final etymonOddballProvider = EtymonOddballNotifierProvider._();

final class EtymonOddballNotifierProvider
    extends $NotifierProvider<EtymonOddballNotifier, EtymonOddballState> {
  EtymonOddballNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'etymonOddballProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$etymonOddballNotifierHash();

  @$internal
  @override
  EtymonOddballNotifier create() => EtymonOddballNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EtymonOddballState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EtymonOddballState>(value),
    );
  }
}

String _$etymonOddballNotifierHash() =>
    r'8b1869949999a7a1d62331b6a94f6bb0478da016';

abstract class _$EtymonOddballNotifier extends $Notifier<EtymonOddballState> {
  EtymonOddballState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EtymonOddballState, EtymonOddballState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EtymonOddballState, EtymonOddballState>,
              EtymonOddballState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
