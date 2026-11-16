// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pegs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PegsNotifier)
final pegsProvider = PegsNotifierProvider._();

final class PegsNotifierProvider
    extends $NotifierProvider<PegsNotifier, PegsState> {
  PegsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pegsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pegsNotifierHash();

  @$internal
  @override
  PegsNotifier create() => PegsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PegsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PegsState>(value),
    );
  }
}

String _$pegsNotifierHash() => r'907be0c2c285d2782c5bc5f111bb2eed618bfc73';

abstract class _$PegsNotifier extends $Notifier<PegsState> {
  PegsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PegsState, PegsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PegsState, PegsState>,
              PegsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
