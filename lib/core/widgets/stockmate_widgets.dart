import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StockMateEyebrow extends StatelessWidget {
  const StockMateEyebrow(this.label, {super.key, this.color = AppColors.mutedText});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.35),
      );
}

class StockMateSectionHeader extends StatelessWidget {
  const StockMateSectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: AppColors.deepTeal, fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      );
}

class StockMateCard extends StatelessWidget {
  const StockMateCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: child,
      );
}

class StockMateIconContainer extends StatelessWidget {
  const StockMateIconContainer({super.key, required this.icon, required this.background, this.foreground = AppColors.deepTeal, this.size = 44});
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: foreground, size: 21),
      );
}

class StockMatePrimaryButton extends StatelessWidget {
  const StockMatePrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.deepTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
        ),
      );
}
