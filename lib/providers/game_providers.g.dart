// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filteredGames)
final filteredGamesProvider = FilteredGamesFamily._();

final class FilteredGamesProvider
    extends
        $FunctionalProvider<
          List<GameMetadata>,
          List<GameMetadata>,
          List<GameMetadata>
        >
    with $Provider<List<GameMetadata>> {
  FilteredGamesProvider._({
    required FilteredGamesFamily super.from,
    required ({
      String searchQuery,
      String selectedCategory,
      Map<String, String> localizedTitles,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'filteredGamesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredGamesHash();

  @override
  String toString() {
    return r'filteredGamesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<GameMetadata>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<GameMetadata> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String searchQuery,
              String selectedCategory,
              Map<String, String> localizedTitles,
            });
    return filteredGames(
      ref,
      searchQuery: argument.searchQuery,
      selectedCategory: argument.selectedCategory,
      localizedTitles: argument.localizedTitles,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<GameMetadata> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<GameMetadata>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGamesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredGamesHash() => r'855eb1ddf3b2898e508f26450eb04eb66c508855';

final class FilteredGamesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<GameMetadata>,
          ({
            String searchQuery,
            String selectedCategory,
            Map<String, String> localizedTitles,
          })
        > {
  FilteredGamesFamily._()
    : super(
        retry: null,
        name: r'filteredGamesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredGamesProvider call({
    required String searchQuery,
    required String selectedCategory,
    required Map<String, String> localizedTitles,
  }) => FilteredGamesProvider._(
    argument: (
      searchQuery: searchQuery,
      selectedCategory: selectedCategory,
      localizedTitles: localizedTitles,
    ),
    from: this,
  );

  @override
  String toString() => r'filteredGamesProvider';
}

@ProviderFor(categoryStats)
final categoryStatsProvider = CategoryStatsProvider._();

final class CategoryStatsProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  CategoryStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryStatsHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return categoryStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$categoryStatsHash() => r'a6f802d5e9a0c3979677eddad776563b736ab6c1';

@ProviderFor(solvedStats)
final solvedStatsProvider = SolvedStatsProvider._();

final class SolvedStatsProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  SolvedStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'solvedStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$solvedStatsHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return solvedStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$solvedStatsHash() => r'b19f6f52c117fe91b4f5f92e33f4527c699873b0';

@ProviderFor(solvedTodayCount)
final solvedTodayCountProvider = SolvedTodayCountProvider._();

final class SolvedTodayCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  SolvedTodayCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'solvedTodayCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$solvedTodayCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return solvedTodayCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$solvedTodayCountHash() => r'd5f608feb7a3c479a98f78bdf47689576ce8e1b5';
