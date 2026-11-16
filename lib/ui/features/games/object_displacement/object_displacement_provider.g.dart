// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_displacement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ObjectDisplacementNotifier)
final objectDisplacementProvider = ObjectDisplacementNotifierProvider._();

final class ObjectDisplacementNotifierProvider
    extends
        $NotifierProvider<ObjectDisplacementNotifier, ObjectDisplacementState> {
  ObjectDisplacementNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'objectDisplacementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$objectDisplacementNotifierHash();

  @$internal
  @override
  ObjectDisplacementNotifier create() => ObjectDisplacementNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ObjectDisplacementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ObjectDisplacementState>(value),
    );
  }
}

String _$objectDisplacementNotifierHash() =>
    r'1c67812b03bb2dec4c087693a3d64fa6a5fa9e17';

abstract class _$ObjectDisplacementNotifier
    extends $Notifier<ObjectDisplacementState> {
  ObjectDisplacementState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ObjectDisplacementState, ObjectDisplacementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ObjectDisplacementState, ObjectDisplacementState>,
              ObjectDisplacementState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
