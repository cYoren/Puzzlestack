// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_fluency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryFluencyNotifier)
final categoryFluencyProvider = CategoryFluencyNotifierProvider._();

final class CategoryFluencyNotifierProvider
    extends $NotifierProvider<CategoryFluencyNotifier, CategoryFluencyState> {
  CategoryFluencyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryFluencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryFluencyNotifierHash();

  @$internal
  @override
  CategoryFluencyNotifier create() => CategoryFluencyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryFluencyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryFluencyState>(value),
    );
  }
}

String _$categoryFluencyNotifierHash() =>
    r'186b5315ccbc994d87ff2dd4a1ec2aefefbb47fc';

abstract class _$CategoryFluencyNotifier
    extends $Notifier<CategoryFluencyState> {
  CategoryFluencyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CategoryFluencyState, CategoryFluencyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CategoryFluencyState, CategoryFluencyState>,
              CategoryFluencyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
