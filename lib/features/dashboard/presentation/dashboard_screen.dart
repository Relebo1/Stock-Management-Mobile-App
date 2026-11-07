import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import '../../inventory/domain/stock_product.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate, required this.onProductTap});
  final ValueChanged<int> onNavigate;
  final ValueChanged<StockProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    final lowStock = StockProducts.demo.where((p) => p.isLowStock || p.isOutOfStock).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
      children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const StockMateEyebrow('Saturday, 7 November'),
            const SizedBox(height: 5),
            Text('Good morning, Demo', style: Theme.of(context).textTheme.headlineMedium),
          ]),
          const Spacer(),
          Stack(children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink)),
            Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle))),
          ]),
        ]),
        const SizedBox(height: 20),
        _InventoryValueCard(),
        const SizedBox(height: 23),
        const StockMateSectionHeader('Quick actions'),
        const SizedBox(height: 10),
        Row(children: [
          _QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'Scan item', color: AppColors.paleMint, onTap: () => onNavigate(2)),
          _QuickAction(icon: Icons.add_box_outlined, label: 'Add product', color: AppColors.informationBackground, onTap: () => onNavigate(1)),
          _QuickAction(icon: Icons.point_of_sale_outlined, label: 'New sale', color: AppColors.purpleBackground, onTap: () => onNavigate(3)),
          _QuickAction(icon: Icons.move_to_inbox_outlined, label: 'Receive stock', color: AppColors.warningBackground, onTap: () => onNavigate(3)),
        ]),
        const SizedBox(height: 22),
        StockMateSectionHeader('Needs attention', action: 'View all', onAction: () => onNavigate(1)),
        const SizedBox(height: 10),
        ...lowStock.take(2).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _AttentionTile(product: product, onTap: () => onProductTap(product)),
            )),
        const SizedBox(height: 12),
        StockMateSectionHeader('Recent activity', action: 'See all', onAction: () => onNavigate(3)),
        const SizedBox(height: 10),
        const _ActivityTile(icon: Icons.shopping_bag_outlined, title: 'Sale completed', detail: '2 items · Today, 10:42 AM', amount: '+ M 86.50', color: AppColors.successBackground, foreground: AppColors.success),
        const Divider(height: 18, indent: 58),
        const _ActivityTile(icon: Icons.move_to_inbox_outlined, title: 'Stock received', detail: 'Orange Juice · Yesterday', amount: '+ 12 units', color: AppColors.informationBackground, foreground: AppColors.information),
        const SizedBox(height: 18),
        const StockMateSectionHeader('Running low'),
        const SizedBox(height: 10),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lowStock.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _LowStockCard(product: lowStock[index], onTap: () => onProductTap(lowStock[index])),
          ),
        ),
      ],
    );
  }
}

class _InventoryValueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.deepTeal,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [BoxShadow(color: AppColors.deepTeal.withOpacity(.18), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Stack(children: [
          Positioned(right: -27, top: -46, child: _Circle(size: 130, color: Colors.white.withOpacity(.06))),
          Positioned(right: 36, bottom: -78, child: _Circle(size: 118, color: Colors.white.withOpacity(.05))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL INVENTORY VALUE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('M 24,860.50', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(width: 9),
              Container(margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: AppColors.limeAccent, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.trending_up, size: 12, color: AppColors.darkForest), SizedBox(width: 3), Text('8.2%', style: TextStyle(color: AppColors.darkForest, fontSize: 10, fontWeight: FontWeight.w800))])),
            ]),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 13),
            const Row(children: [
              _SummaryMetric(value: '1,284', label: 'Total units'), SizedBox(width: 32), _SummaryMetric(value: '86', label: 'Products'),
            ]),
          ]),
        ]),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(children: [StockMateIconContainer(icon: icon, background: color, size: 43), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.ink, fontWeight: FontWeight.w600))]))));
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.product, required this.onTap});
  final StockProduct product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final out = product.isOutOfStock;
    final foreground = out ? AppColors.danger : AppColors.warning;
    final background = out ? AppColors.dangerBackground : AppColors.warningBackground;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: StockMateCard(padding: const EdgeInsets.all(12), child: Row(children: [StockMateIconContainer(icon: out ? Icons.remove_shopping_cart_outlined : Icons.inventory_2_outlined, background: background, foreground: foreground, size: 40), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(out ? 'Out of stock' : 'Only ${product.quantity} left · ${product.category}', style: TextStyle(fontSize: 10, color: foreground))])), const Icon(Icons.chevron_right, color: AppColors.subtleText, size: 19)])));
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.icon, required this.title, required this.detail, required this.amount, required this.color, required this.foreground});
  final IconData icon;
  final String title, detail, amount;
  final Color color, foreground;
  @override
  Widget build(BuildContext context) => Row(children: [StockMateIconContainer(icon: icon, background: color, foreground: foreground, size: 42), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(detail, style: const TextStyle(fontSize: 10, color: AppColors.mutedText))])), Text(amount, style: const TextStyle(fontSize: 11, color: AppColors.darkForest, fontWeight: FontWeight.w700))]);
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.product, required this.onTap});
  final StockProduct product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(width: 205, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: Color(product.colorValue), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined, color: AppColors.deepTeal, size: 20)), const SizedBox(width: 9), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(product.isOutOfStock ? 'Out of stock' : '${product.quantity} left', style: TextStyle(fontSize: 10, color: product.isOutOfStock ? AppColors.danger : AppColors.warning))]))])));
}
