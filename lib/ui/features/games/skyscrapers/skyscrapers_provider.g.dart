// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skyscrapers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SkyscrapersNotifier)
final skyscrapersProvider = SkyscrapersNotifierProvider._();

final class SkyscrapersNotifierProvider
    extends $NotifierProvider<SkyscrapersNotifier, SkyscrapersState> {
  SkyscrapersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skyscrapersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skyscrapersNotifierHash();

  @$internal
  @override
  SkyscrapersNotifier create() => SkyscrapersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkyscrapersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkyscrapersState>(value),
    );
  }
}

String _$skyscrapersNotifierHash() =>
    r'792e5ec1984379bb4c08546a3c4221496e48a556';

abstract class _$SkyscrapersNotifier extends $Notifier<SkyscrapersState> {
  SkyscrapersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SkyscrapersState, SkyscrapersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SkyscrapersState, SkyscrapersState>,
              SkyscrapersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
