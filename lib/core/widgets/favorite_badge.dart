import 'package:flutter/material.dart';

/// شارة عدد بسيطة (دائرة حمراء عليها رقم) — تستبدل مكتبة `badges`.
///
/// إذا كان [count] صفر فلا تظهر الشارة.
class FavoriteBadge extends StatelessWidget {
  const FavoriteBadge({
    super.key,
    required this.count,
    required this.child,
    this.color = Colors.amber,
    this.textColor = Colors.black,
  });

  final int count;
  final Widget child;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
