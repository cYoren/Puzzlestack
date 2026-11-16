// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nonogram_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NonogramNotifier)
final nonogramProvider = NonogramNotifierProvider._();

final class NonogramNotifierProvider
    extends $AsyncNotifierProvider<NonogramNotifier, NonogramState> {
  NonogramNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nonogramProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nonogramNotifierHash();

  @$internal
  @override
  NonogramNotifier create() => NonogramNotifier();
}

String _$nonogramNotifierHash() => r'b9cb4105004858b141d6c93e1c3da8b45472b89c';

abstract class _$NonogramNotifier extends $AsyncNotifier<NonogramState> {
  FutureOr<NonogramState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NonogramState>, NonogramState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NonogramState>, NonogramState>,
              AsyncValue<NonogramState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
