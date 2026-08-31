import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/order.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';

/// Confetti piece definition for the shipped celebration.
class _Confetti {
  final double x, y, size;
  final Color color;
  const _Confetti(this.x, this.y, this.size, this.color);
}

const _pieces = <_Confetti>[
  _Confetti(-70, -52, 10, AppColors.saffron600),
  _Confetti(66, -60, 8, AppColors.green600),
  _Confetti(-84, 18, 7, Color(0xFFF97316)),
  _Confetti(82, 12, 9, Color(0xFFFACC15)),
  _Confetti(-46, 62, 7, AppColors.green600),
  _Confetti(52, 66, 8, AppColors.saffron600),
  _Confetti(0, -82, 8, Color(0xFFFACC15)),
];

/// Full-screen "Order Shipped" celebration modal with confetti.
class OrderShippedModal extends StatefulWidget {
  final bool visible;

  /// The order just accepted — every detail shown comes from it.
  final Order order;
  final Language language;
  final DashboardStrings strings;
  final VoidCallback onClose;

  const OrderShippedModal({
    super.key,
    required this.visible,
    required this.order,
    required this.language,
    required this.strings,
    required this.onClose,
  });

  @override
  State<OrderShippedModal> createState() => _OrderShippedModalState();
}

class _OrderShippedModalState extends State<OrderShippedModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void didUpdateWidget(OrderShippedModal old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _anim.forward(from: 0);
    if (!widget.visible && old.visible) _anim.reverse();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    final s = widget.strings;

    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Stack(children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black54),
        ),

        // Dialog
        Center(
          child: AnimatedScale(
            scale: widget.visible ? 1.0 : 0.96,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 10))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Confetti + package icon
                SizedBox(
                  width: 112, height: 112,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, child) {
                      final t = Curves.easeOut.transform(_anim.value.clamp(0, 1));
                      return Stack(alignment: Alignment.center, children: [
                        // Confetti dots
                        for (int i = 0; i < _pieces.length; i++)
                          Positioned(
                            left: 56 + _pieces[i].x * t,
                            top: 56 + _pieces[i].y * t,
                            child: Opacity(
                              opacity: (t * 2).clamp(0, 1),
                              child: Container(
                                width: _pieces[i].size,
                                height: _pieces[i].size,
                                decoration: BoxDecoration(color: _pieces[i].color, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        // Main icon
                        Transform.rotate(
                          angle: (1 - t) * -0.1,
                          child: Opacity(
                            opacity: t,
                            child: Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.saffron600,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: kLiftShadow,
                              ),
                              child: const Icon(Icons.local_shipping_rounded, size: 48, color: Colors.white),
                            ),
                          ),
                        ),
                      ]);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // "Shipped" pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.green800),
                    const SizedBox(width: 6),
                    Text(s.shippedPill, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green800)),
                  ]),
                ),

                const SizedBox(height: 8),
                Text(s.shippedTitle.replaceFirst('{id}', '#${widget.order.id}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.ink900)),

                const SizedBox(height: 16),

                // Buyer details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink200),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(s.buyerLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink500)),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(widget.order.buyerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                        Text(widget.order.formattedPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink500)),
                      ]),
                    ]),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.ink200)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(s.orderLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink500)),
                      Flexible(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(
                            widget.language == Language.hi
                                ? widget.order.productHi
                                : widget.order.productEn,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink900),
                          ),
                          Text(widget.order.formattedAmount,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.saffron700)),
                        ]),
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 20),

                // Share on WhatsApp CTA
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: AppColors.saffron600, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.chat_rounded, size: 24, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(s.shareTracking, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),

                const SizedBox(height: 8),

                // Done button
                GestureDetector(
                  onTap: widget.onClose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.done, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink500)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
