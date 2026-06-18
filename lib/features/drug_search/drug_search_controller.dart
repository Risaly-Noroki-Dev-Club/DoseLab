import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../shared/extensions/string_x.dart';
import 'fda_client.dart';
import 'fda_envelope.dart';
import 'zh_resolver.dart';

/// Three-state UI model. Using a sealed family keeps the switch in
/// the view exhaustive.
@immutable
sealed class SearchState {
  const SearchState();
}

class SearchIdle extends SearchState {
  const SearchIdle();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchUnmappedChinese extends SearchState {
  const SearchUnmappedChinese(this.input);
  final String input;
}

class SearchSuccess extends SearchState {
  const SearchSuccess(this.envelope, {this.resolvedFrom});
  final FdaEnvelope envelope;
  final ZhResolution? resolvedFrom;
}

class SearchError extends SearchState {
  const SearchError(this.failure);
  final Failure failure;
}

class DrugSearchController extends AsyncNotifier<SearchState> {
  @override
  Future<SearchState> build() async => const SearchIdle();

  Future<void> search(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      state = const AsyncData(SearchIdle());
      return;
    }
    state = const AsyncData(SearchLoading());

    final resolver = await ref.read(zhResolverProvider.future);
    final resolution = resolver.resolve(query);
    if (resolution == null) {
      state = AsyncData(SearchUnmappedChinese(query));
      return;
    }

    final fda = ref.read(fdaClientProvider);
    try {
      var env = await fda.searchNdc(resolution.english);
      if (env.results.isEmpty && !resolution.english.hasCjk) {
        env = await fda.searchNdcLoose(resolution.english);
      }
      state = AsyncData(SearchSuccess(env, resolvedFrom: resolution));
    } on Failure catch (f) {
      state = AsyncData(SearchError(f));
    } catch (e) {
      state = AsyncData(SearchError(Failure.unknown(message: '$e')));
    }
  }
}

final drugSearchControllerProvider =
    AsyncNotifierProvider<DrugSearchController, SearchState>(
  DrugSearchController.new,
);
