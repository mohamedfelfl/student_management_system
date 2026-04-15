import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../features/settings/services/settings_service.dart';

part 'locale_cubit.freezed.dart';

@freezed
abstract class LocaleState with _$LocaleState {
  const factory LocaleState({
    @Default('ar') String languageCode,
    @Default(ThemeMode.system) ThemeMode themeMode,
  }) = _LocaleState;
}

/// Manages app-wide locale (language) and theme mode.
class LocaleCubit extends Cubit<LocaleState> {
  final SettingsService _settingsService;

  LocaleCubit({required SettingsService settingsService})
      : _settingsService = settingsService,
        super(const LocaleState());

  Future<void> loadInitialSettings() async {
    final themeStr = await _settingsService.getOrDefault(SettingsKeys.themeMode, 'system');
    final lang = await _settingsService.getOrDefault(SettingsKeys.language, 'ar');

    ThemeMode mode;
    switch (themeStr) {
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'light':
        mode = ThemeMode.light;
        break;
      default:
        mode = ThemeMode.system;
    }

    emit(state.copyWith(
      themeMode: mode,
      languageCode: lang,
    ));
  }

  void setLanguage(String languageCode) {
    emit(state.copyWith(languageCode: languageCode));
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'en' ? 'ar' : 'en';
    emit(state.copyWith(languageCode: newLang));
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }
}
