// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VaultFlow';

  @override
  String get navVault => 'Vault';

  @override
  String get navNotes => 'Notes';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navSettings => 'Settings';

  @override
  String get titleSearch => 'Search';

  @override
  String get titleSyncQueue => 'Sync queue';

  @override
  String get titleVaultLock => 'Vault lock';

  @override
  String get titleConflicts => 'Conflicts';

  @override
  String get searchTooltip => 'Search (⌘F)';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }
}
