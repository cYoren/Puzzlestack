// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_span_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReadingSpanNotifier)
final readingSpanProvider = ReadingSpanNotifierProvider._();

final class ReadingSpanNotifierProvider
    extends $NotifierProvider<ReadingSpanNotifier, ReadingSpanState> {
  ReadingSpanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingSpanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingSpanNotifierHash();

  @$internal
  @override
  ReadingSpanNotifier create() => ReadingSpanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingSpanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingSpanState>(value),
    );
  }
}

String _$readingSpanNotifierHash() =>
    r'ba56bb40112e91e71e760ebedd9291f23dd03586';

abstract class _$ReadingSpanNotifier extends $Notifier<ReadingSpanState> {
  ReadingSpanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReadingSpanState, ReadingSpanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReadingSpanState, ReadingSpanState>,
              ReadingSpanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
