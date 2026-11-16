// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_shuffle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ObjectShuffleNotifier)
final objectShuffleProvider = ObjectShuffleNotifierProvider._();

final class ObjectShuffleNotifierProvider
    extends $NotifierProvider<ObjectShuffleNotifier, ObjectShuffleState> {
  ObjectShuffleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'objectShuffleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$objectShuffleNotifierHash();

  @$internal
  @override
  ObjectShuffleNotifier create() => ObjectShuffleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ObjectShuffleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ObjectShuffleState>(value),
    );
  }
}

String _$objectShuffleNotifierHash() =>
    r'b15a09667527618910a9f8cc1d211ceb8230c7f7';

abstract class _$ObjectShuffleNotifier extends $Notifier<ObjectShuffleState> {
  ObjectShuffleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ObjectShuffleState, ObjectShuffleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ObjectShuffleState, ObjectShuffleState>,
              ObjectShuffleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
