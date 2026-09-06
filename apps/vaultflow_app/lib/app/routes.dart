/// Route paths and names. Paths are the public URL contract on web, so keep
/// them stable; names are what `context.goNamed` uses.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String vault = '/vault';
  static const String notes = '/notes';
  static const String transfers = '/transfers';
  static const String settings = '/settings';
  static const String settingsOutbox = '/settings/outbox';

  static const String folderParam = 'folderId';
  static const String noteParam = 'noteId';

  static String folder(String folderId) => '$vault/$folderId';
  static String note(String noteId) => '$notes/$noteId';

  static const String loginName = 'login';
  static const String vaultName = 'vault';
  static const String folderName = 'folder';
  static const String notesName = 'notes';
  static const String noteName = 'note';
  static const String transfersName = 'transfers';
  static const String settingsName = 'settings';
  static const String settingsOutboxName = 'settings-outbox';
}
