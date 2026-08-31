import 'package:flutter/material.dart';
import 'palette.dart';

/// Font families bundled with the app — see the `fonts:` section of pubspec.yaml.
///
/// These are shipped as assets rather than fetched at runtime (the `google_fonts`
/// package downloads from fonts.gstatic.com on first use). Handora is offline
/// first and its users are often on unreliable rural connections, so a first
/// launch with no network must still render correctly — especially in Hindi.
const kFontFamily = 'Inter';

/// Inter carries no Devanagari glyphs. Listing Noto Sans Devanagari as a
/// fallback makes Hindi text render correctly anywhere in the app without each
/// widget having to opt in.
const kFontFamilyFallback = <String>['NotoSansDevanagari'];

ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFamilyFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saffron600,
      brightness: Brightness.light,
    ),
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.ink950,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFamilyFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saffron600,
      brightness: Brightness.dark,
    ),
  );
}
