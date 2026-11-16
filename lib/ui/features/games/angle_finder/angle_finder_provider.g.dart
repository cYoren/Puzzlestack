// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'angle_finder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AngleFinderNotifier)
final angleFinderProvider = AngleFinderNotifierProvider._();

final class AngleFinderNotifierProvider
    extends $NotifierProvider<AngleFinderNotifier, AngleFinderState> {
  AngleFinderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'angleFinderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$angleFinderNotifierHash();

  @$internal
  @override
  AngleFinderNotifier create() => AngleFinderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AngleFinderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AngleFinderState>(value),
    );
  }
}

String _$angleFinderNotifierHash() =>
    r'5315a90d31ea690e1eed25410cafca415f8bf98a';

abstract class _$AngleFinderNotifier extends $Notifier<AngleFinderState> {
  AngleFinderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AngleFinderState, AngleFinderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AngleFinderState, AngleFinderState>,
              AngleFinderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
