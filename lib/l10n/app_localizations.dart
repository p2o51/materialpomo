import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Existing translations
  String get todoList => Intl.message('Todo List', name: 'todoList');
  String get item => Intl.message('Item', name: 'item');
  String get addItemHint =>
      Intl.message('Press Enter or tap "Add" to add an item.',
          name: 'addItemHint');
  String get add => Intl.message('Add', name: 'add');
  String get todoDeleted => Intl.message('Todo deleted', name: 'todoDeleted');

  // New translations for FocusPage
  String get focus => Intl.message('Focus', name: 'focus');
  String get start => Intl.message('Start', name: 'start');
  String get pause => Intl.message('Pause', name: 'pause');
  String get resume => Intl.message('Resume', name: 'resume');
  String get stop => Intl.message('Stop', name: 'stop');

  // New translations for StatsPage
  String get stats => Intl.message('Stats', name: 'stats');
  String get totalFocusTime =>
      Intl.message('Total Focus Time', name: 'totalFocusTime');
  String get completedTasks =>
      Intl.message('Completed Tasks', name: 'completedTasks');

  // New translations for bottom navigation
  String get focusTab => Intl.message('Focus', name: 'focusTab');
  String get todoTab => Intl.message('Todo', name: 'todoTab');
  String get statsTab => Intl.message('Stats', name: 'statsTab');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    return locale.languageCode == 'ja'
        ? AppLocalizationsJa()
        : AppLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class AppLocalizationsJa extends AppLocalizations {
  @override
  String get todoList => '待办事项';
  @override
  String get item => '事项';
  @override
  String get addItemHint => '键入回车或轻按「创建」以添加事项。';
  @override
  String get add => '创建';
  @override
  String get todoDeleted => 'Todoが削除されました';

  // Japanese translations for FocusPage
  @override
  String get focus => '集中';
  @override
  String get start => '開始';
  @override
  String get pause => '一時停止';
  @override
  String get resume => '再開';
  @override
  String get stop => '停止';

  // Japanese translations for StatsPage
  @override
  String get stats => '統計';
  @override
  String get totalFocusTime => '合計集中時間';
  @override
  String get completedTasks => '完了したタスク';

  // Japanese translations for bottom navigation
  @override
  String get focusTab => '集中';
  @override
  String get todoTab => '待办';
  @override
  String get statsTab => '統計';
}
