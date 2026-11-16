// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silhouette_match_ortho_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SilhouetteMatchOrthoNotifier)
final silhouetteMatchOrthoProvider = SilhouetteMatchOrthoNotifierProvider._();

final class SilhouetteMatchOrthoNotifierProvider
    extends
        $NotifierProvider<
          SilhouetteMatchOrthoNotifier,
          SilhouetteMatchOrthoState
        > {
  SilhouetteMatchOrthoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'silhouetteMatchOrthoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$silhouetteMatchOrthoNotifierHash();

  @$internal
  @override
  SilhouetteMatchOrthoNotifier create() => SilhouetteMatchOrthoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SilhouetteMatchOrthoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SilhouetteMatchOrthoState>(value),
    );
  }
}

String _$silhouetteMatchOrthoNotifierHash() =>
    r'8990602309f0c1ff626c34c6e673d53d879dc0b4';

abstract class _$SilhouetteMatchOrthoNotifier
    extends $Notifier<SilhouetteMatchOrthoState> {
  SilhouetteMatchOrthoState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SilhouetteMatchOrthoState, SilhouetteMatchOrthoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SilhouetteMatchOrthoState, SilhouetteMatchOrthoState>,
              SilhouetteMatchOrthoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
