import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_cubit.freezed.dart';

@freezed
abstract class LocaleState with _$LocaleState {
  const factory LocaleState({
    @Default('en') String languageCode,
    @Default(false) bool isDarkMode,
  }) = _LocaleState;
}

/// Manages app-wide locale (language) and theme mode.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(const LocaleState());

  void setLanguage(String languageCode) {
    emit(state.copyWith(languageCode: languageCode));
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'en' ? 'ar' : 'en';
    emit(state.copyWith(languageCode: newLang));
  }

  void toggleDarkMode() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void setDarkMode(bool isDark) {
    emit(state.copyWith(isDarkMode: isDark));
  }
}
