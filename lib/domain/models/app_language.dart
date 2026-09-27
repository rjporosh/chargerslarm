/// Supported in-app languages. The value is the ISO 639-1 code persisted
/// to settings and passed to [Locale].
enum AppLanguage {
  english('en'),
  bengali('bn');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
