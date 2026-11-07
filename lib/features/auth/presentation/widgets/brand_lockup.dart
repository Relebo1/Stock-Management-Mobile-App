import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.deepTeal, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_rounded, color: AppColors.limeAccent, size: 21),
          ),
          const SizedBox(width: 11),
          const Text('StockMate', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkForest, letterSpacing: -0.5)),
        ],
      );
}
