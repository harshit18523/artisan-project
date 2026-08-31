import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/order.dart';
import '../theme/palette.dart';

/// Slide-down toast notification for an incoming order.
/// Shows a wiggling bell icon, order summary, and an Accept button.
class NewOrderToast extends StatefulWidget {
  final bool visible;

  /// The real pending order this toast represents.
  final Order order;
  final Language language;
  final DashboardStrings strings;
  final VoidCallback onAccept;

  const NewOrderToast({
    super.key,
    required this.visible,
    required this.order,
    required this.language,
    required this.strings,
    required this.onAccept,
  });

  @override
  State<NewOrderToast> createState() => _NewOrderToastState();
}

class _NewOrderToastState extends State<NewOrderToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bell;

  @override
  void initState() {
    super.initState();
    _bell = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: false, period: const Duration(milliseconds: 2300));
  }

  @override
  void dispose() {
    _bell.dispose();
    super.dispose();
  }

  /// "₹850 · Handmade Scarf" — the real amount and product, in the app language.
  String get _summary {
    final order = widget.order;
    final name = widget.language == Language.hi ? order.productHi : order.productEn;
    return '${order.formattedAmount} · $name';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, -1.5),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.ink200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffron600.withAlpha(89),
                  blurRadius: 40, offset: const Offset(0, 18), spreadRadius: -18,
                ),
              ],
            ),
            child: Row(children: [
              // Bell with wiggle animation + notification dot
              SizedBox(
                width: 40, height: 40,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.saffron50, shape: BoxShape.circle),
                    child: AnimatedBuilder(
                      animation: _bell,
                      builder: (_, child) {
                        // Wiggle between -14° and +12°
                        final t = _bell.value;
                        final angle = t < 0.5
                            ? math.sin(t * 2 * math.pi * 2) * 0.25
                            : 0.0;
                        return Transform.rotate(
                          angle: angle,
                          alignment: const Alignment(0, -0.4),
                          child: const Icon(Icons.notifications_rounded, size: 20, color: AppColors.saffron600),
                        );
                      },
                    ),
                  ),
                  // Red notification dot
                  Positioned(right: 0, top: 0, child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.red600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  )),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.strings.toastTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink900)),
                  Text(_summary, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink500)),
                ],
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onAccept,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.saffron600,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(widget.strings.accept,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
