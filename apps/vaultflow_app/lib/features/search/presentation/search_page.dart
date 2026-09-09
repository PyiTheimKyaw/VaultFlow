import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_item_tile.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_ui/vf_ui.dart';

/// `/search?q=…`: folder and document names plus note full text.
///
/// The query lives in the URL so results are shareable/bookmarkable on web
/// and survive a reload; typing updates the URL (debounced) rather than
/// local state.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.query = ''});

  final String query;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final _controller = TextEditingController(text: widget.query);
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didUpdateWidget(SearchPage old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _go(value));
  }

  void _go(String value) {
    if (!mounted) return;
    context.go(AppRoutes.searchFor(value));
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(widget.query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VfSpacing.md,
            VfSpacing.sm,
            VfSpacing.md,
            VfSpacing.xs,
          ),
          child: TextField(
            key: const Key('search-field'),
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _go,
            decoration: InputDecoration(
              hintText: 'Search names and note text',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('search-clear'),
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _go('');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: widget.query.trim().isEmpty
              ? const EmptyState(
                  key: Key('search-idle'),
                  icon: Icons.search,
                  title: 'Search your vault',
                  message:
                      'Matches folder and file names and the full text of '
                      'notes. Works offline.',
                )
              : results.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Search failed',
                    message: '$e',
                  ),
                  data: (hits) => hits.isEmpty
                      ? EmptyState(
                          key: const Key('search-empty'),
                          icon: Icons.search_off,
                          title: 'No matches',
                          message:
                              'Nothing named or containing '
                              '"${widget.query.trim()}".',
                        )
                      : _Results(hits: hits),
                ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.hits});

  final FolderContents hits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget header(String label, int count) => Padding(
      padding: const EdgeInsets.fromLTRB(
        VfSpacing.lg,
        VfSpacing.md,
        VfSpacing.lg,
        VfSpacing.xs,
      ),
      child: Text(
        '$label · $count',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return ListView(
      key: const Key('search-results'),
      children: [
        if (hits.folders.isNotEmpty) header('Folders', hits.folders.length),
        for (final f in hits.folders) VaultItemTile(item: VaultItem.folder(f)),
        if (hits.documents.isNotEmpty) header('Files', hits.documents.length),
        for (final d in hits.documents)
          VaultItemTile(item: VaultItem.document(d)),
        if (hits.notes.isNotEmpty) header('Notes', hits.notes.length),
        for (final n in hits.notes) VaultItemTile(item: VaultItem.note(n)),
      ],
    );
  }
}
