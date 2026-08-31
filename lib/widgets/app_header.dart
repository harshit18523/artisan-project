import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/palette.dart';

class AppHeader extends StatelessWidget {
  final Language language;
  final ValueChanged<Language> onLanguageChange;

  const AppHeader({
    super.key,
    required this.language,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.ink950 : Colors.white;
    final borderColor = dark ? AppColors.ink700 : AppColors.ink200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text.rich(TextSpan(
            text: 'Hand',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: dark ? Colors.white : AppColors.ink900,
            ),
            children: [
              TextSpan(text: 'ora', style: TextStyle(color: AppColors.saffron600)),
            ],
          )),

          // EN / HI toggle pill
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.saffron50,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.saffron600, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LangPill('EN', language == Language.en, () => onLanguageChange(Language.en)),
                const SizedBox(width: 4),
                _LangPill('हिं', language == Language.hi, () => onLanguageChange(Language.hi), deva: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool deva;

  const _LangPill(this.label, this.active, this.onTap, {this.deva = false});

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: active ? Colors.white : AppColors.saffron700,
    );
    if (deva) style = style.copyWith(fontFamily: 'NotoSansDevanagari');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.saffron600 : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(child: Text(label, style: style)),
      ),
    );
  }
}
