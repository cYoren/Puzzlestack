// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_trait_association_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FaceTraitAssociationNotifier)
final faceTraitAssociationProvider = FaceTraitAssociationNotifierProvider._();

final class FaceTraitAssociationNotifierProvider
    extends
        $NotifierProvider<
          FaceTraitAssociationNotifier,
          FaceTraitAssociationState
        > {
  FaceTraitAssociationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'faceTraitAssociationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$faceTraitAssociationNotifierHash();

  @$internal
  @override
  FaceTraitAssociationNotifier create() => FaceTraitAssociationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FaceTraitAssociationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FaceTraitAssociationState>(value),
    );
  }
}

String _$faceTraitAssociationNotifierHash() =>
    r'991f65790e9ac96c155d2914b85e067d3d90d943';

abstract class _$FaceTraitAssociationNotifier
    extends $Notifier<FaceTraitAssociationState> {
  FaceTraitAssociationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<FaceTraitAssociationState, FaceTraitAssociationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FaceTraitAssociationState, FaceTraitAssociationState>,
              FaceTraitAssociationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
