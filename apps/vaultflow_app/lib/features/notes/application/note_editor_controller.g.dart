// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debounced autosave for one note. Edits are held for [debounce] and then
/// written through `NotesUseCases.save`; [flush] writes immediately (used
/// when the editor closes).

@ProviderFor(NoteEditorController)
final noteEditorControllerProvider = NoteEditorControllerFamily._();

/// Debounced autosave for one note. Edits are held for [debounce] and then
/// written through `NotesUseCases.save`; [flush] writes immediately (used
/// when the editor closes).
final class NoteEditorControllerProvider
    extends $NotifierProvider<NoteEditorController, EditorState> {
  /// Debounced autosave for one note. Edits are held for [debounce] and then
  /// written through `NotesUseCases.save`; [flush] writes immediately (used
  /// when the editor closes).
  NoteEditorControllerProvider._({
    required NoteEditorControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteEditorControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteEditorControllerHash();

  @override
  String toString() {
    return r'noteEditorControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NoteEditorController create() => NoteEditorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteEditorControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteEditorControllerHash() =>
    r'377f1239a52981ab0b2bf35050e45bbb599e5f8a';

/// Debounced autosave for one note. Edits are held for [debounce] and then
/// written through `NotesUseCases.save`; [flush] writes immediately (used
/// when the editor closes).

final class NoteEditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          NoteEditorController,
          EditorState,
          EditorState,
          EditorState,
          String
        > {
  NoteEditorControllerFamily._()
    : super(
        retry: null,
        name: r'noteEditorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Debounced autosave for one note. Edits are held for [debounce] and then
  /// written through `NotesUseCases.save`; [flush] writes immediately (used
  /// when the editor closes).

  NoteEditorControllerProvider call(String noteId) =>
      NoteEditorControllerProvider._(argument: noteId, from: this);

  @override
  String toString() => r'noteEditorControllerProvider';
}

/// Debounced autosave for one note. Edits are held for [debounce] and then
/// written through `NotesUseCases.save`; [flush] writes immediately (used
/// when the editor closes).

abstract class _$NoteEditorController extends $Notifier<EditorState> {
  late final _$args = ref.$arg as String;
  String get noteId => _$args;

  EditorState build(String noteId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EditorState, EditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorState, EditorState>,
              EditorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
