import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/product_repository.dart';
import '../domain/stock_product.dart';

class ProductDetailsSheet extends StatefulWidget {
  const ProductDetailsSheet({super.key, required this.product, required this.scrollController});
  final StockProduct product;
  final ScrollController scrollController;

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
  }

  Future<void> _adjustStock() async {
    final updated = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _StockAdjustmentSheet(quantity: _quantity),
    );
    if (updated != null && updated != _quantity && mounted) {
      await ProductRepository.instance.adjustStock(widget.product, updated);
      if (mounted) setState(() => _quantity = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentValue = product.price * _quantity;
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)), const Expanded(child: Text('Product details', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))), IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded))]),
          const SizedBox(height: 18),
          Center(child: Container(width: 102, height: 102, decoration: BoxDecoration(color: Color(product.colorValue), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.inventory_2_outlined, color: AppColors.deepTeal, size: 42))),
          const SizedBox(height: 14),
          Center(child: _StatusBadge(quantity: _quantity, minimum: product.minimumStock)),
          const SizedBox(height: 8),
          Text(product.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('${product.category} · ${product.sku}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
          const SizedBox(height: 20),
          StockMateCard(child: Row(children: [Expanded(child: _Stat(label: 'Available', value: '$_quantity')), Expanded(child: _Stat(label: 'Selling price', value: 'M ${product.price.toStringAsFixed(2)}')), Expanded(child: _Stat(label: 'Stock value', value: 'M ${currentValue.toStringAsFixed(2)}'))])),
          const SizedBox(height: 14),
          StockMateCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Product information', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 13), _InfoRow(label: 'Cost price', value: 'M ${product.cost.toStringAsFixed(2)}'), _InfoRow(label: 'Profit margin', value: '${product.price == 0 ? 0 : ((product.price - product.cost) / product.price * 100).round()}%'), _InfoRow(label: 'Minimum stock level', value: '${product.minimumStock} units'), _InfoRow(label: 'Barcode', value: product.barcode.isEmpty ? 'Not added' : product.barcode)])),
          const SizedBox(height: 14),
          const StockMateSectionHeader('Recent stock movements'),
          const StockMateCard(child: _MovementRow()),
          const SizedBox(height: 18),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _adjustStock, icon: const Icon(Icons.tune_rounded), label: const Text('Adjust stock'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.deepTeal, side: const BorderSide(color: AppColors.deepTeal), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))))), const SizedBox(width: 10), Expanded(child: StockMatePrimaryButton(label: 'Record sale', icon: Icons.point_of_sale_outlined, onPressed: () {}))]),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.quantity, required this.minimum});
  final int quantity, minimum;
  @override
  Widget build(BuildContext context) {
    final out = quantity <= 0;
    final low = !out && quantity <= minimum;
    final color = out ? AppColors.danger : low ? AppColors.warning : AppColors.success;
    final background = out ? AppColors.dangerBackground : low ? AppColors.warningBackground : AppColors.successBackground;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)), child: Text(out ? 'Out of stock' : low ? 'Low stock' : 'In stock', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.darkForest, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 5), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 9))]);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 11))), Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600))]));
}

class _MovementRow extends StatelessWidget {
  const _MovementRow();
  @override
  Widget build(BuildContext context) => const Row(children: [StockMateIconContainer(icon: Icons.move_to_inbox_outlined, background: AppColors.successBackground, foreground: AppColors.success, size: 38), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Opening stock', style: TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w700)), SizedBox(height: 3), Text('Today · Demo Owner', style: TextStyle(color: AppColors.mutedText, fontSize: 9))])), Text('+ 12 units', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700))]);
}

class _StockAdjustmentSheet extends StatefulWidget {
  const _StockAdjustmentSheet({required this.quantity});
  final int quantity;
  @override
  State<_StockAdjustmentSheet> createState() => _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends State<_StockAdjustmentSheet> {
  late int _quantity;
  @override
  void initState() { super.initState(); _quantity = widget.quantity; }
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const StockMateEyebrow('Inventory update'), const SizedBox(height: 5), Text('Adjust stock', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 9), const Text('Stock changes are recorded as movements so you can review the full history.', style: TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.5)),
          const SizedBox(height: 24), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: _quantity > 0 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_rounded), style: IconButton.styleFrom(backgroundColor: AppColors.softSurface)), Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(children: [Text('$_quantity', style: const TextStyle(fontSize: 36, color: AppColors.ink, fontWeight: FontWeight.w800)), const Text('units on hand', style: TextStyle(fontSize: 10, color: AppColors.mutedText))])), IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: AppColors.softMint))]),
          const SizedBox(height: 24), StockMatePrimaryButton(label: 'Save adjustment', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context, _quantity)),
        ]),
      );
}
