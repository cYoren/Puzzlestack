// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'face_name_association_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FaceNameAssociationNotifier)
final faceNameAssociationProvider = FaceNameAssociationNotifierProvider._();

final class FaceNameAssociationNotifierProvider
    extends $NotifierProvider<FaceNameAssociationNotifier, FaceNameState> {
  FaceNameAssociationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'faceNameAssociationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$faceNameAssociationNotifierHash();

  @$internal
  @override
  FaceNameAssociationNotifier create() => FaceNameAssociationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FaceNameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FaceNameState>(value),
    );
  }
}

String _$faceNameAssociationNotifierHash() =>
    r'ae825c0e786df5a859caecd24fd2d4d94e9b9cf0';

abstract class _$FaceNameAssociationNotifier extends $Notifier<FaceNameState> {
  FaceNameState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FaceNameState, FaceNameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FaceNameState, FaceNameState>,
              FaceNameState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
