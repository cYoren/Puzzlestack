// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silhouette_match_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SilhouetteMatchNotifier)
final silhouetteMatchProvider = SilhouetteMatchNotifierProvider._();

final class SilhouetteMatchNotifierProvider
    extends $NotifierProvider<SilhouetteMatchNotifier, SilhouetteMatchState> {
  SilhouetteMatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'silhouetteMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$silhouetteMatchNotifierHash();

  @$internal
  @override
  SilhouetteMatchNotifier create() => SilhouetteMatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SilhouetteMatchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SilhouetteMatchState>(value),
    );
  }
}

String _$silhouetteMatchNotifierHash() =>
    r'd5efaf10436f941a792ae64e78cf9d4ba8cc40ae';

abstract class _$SilhouetteMatchNotifier
    extends $Notifier<SilhouetteMatchState> {
  SilhouetteMatchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SilhouetteMatchState, SilhouetteMatchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SilhouetteMatchState, SilhouetteMatchState>,
              SilhouetteMatchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
