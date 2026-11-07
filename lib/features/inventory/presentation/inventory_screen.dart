import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/product_repository.dart';
import '../domain/stock_product.dart';
import 'add_product_sheet.dart';
import 'product_details_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  String _filter = 'All products';
  List<StockProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ProductRepository.instance.getProducts();
    if (!mounted) return;
    setState(() { _products = products; _loading = false; });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StockProduct> get _visibleProducts {
    final query = _search.text.toLowerCase().trim();
    return _products.where((product) {
      final matchesQuery = query.isEmpty || '${product.name} ${product.sku} ${product.category}'.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All products' || (_filter == 'Low stock' && product.isLowStock) || (_filter == 'Out of stock' && product.isOutOfStock);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _showDetails(StockProduct product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .94,
        maxChildSize: .94,
        minChildSize: .6,
        expand: false,
        builder: (_, controller) => ProductDetailsSheet(product: product, scrollController: controller),
      ),
    );
    await _loadProducts();
  }

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<StockProduct>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddProductSheet(),
    );
    if (product != null && mounted) {
      final saved = await ProductRepository.instance.addProduct(product);
      if (mounted) setState(() => _products.insert(0, saved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProducts;
    final totalValue = _products.fold<double>(0, (sum, product) => sum + product.quantity * product.price);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        const StockMateEyebrow('Your products'),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: Text('Stock Catalogue', style: Theme.of(context).textTheme.headlineLarge)),
          IconButton.filledTonal(onPressed: _addProduct, icon: const Icon(Icons.add_rounded, color: AppColors.deepTeal), style: IconButton.styleFrom(backgroundColor: AppColors.softMint)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(controller: _search, decoration: const InputDecoration(hintText: 'Search products', prefixIcon: Icon(Icons.search_rounded), isDense: true))),
          const SizedBox(width: 9),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
        ]),
        const SizedBox(height: 13),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All products', 'Low stock', 'Out of stock'].map((filter) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(filter), selected: _filter == filter, onSelected: (_) => setState(() => _filter = filter), selectedColor: AppColors.softMint, backgroundColor: Colors.white, side: BorderSide(color: _filter == filter ? AppColors.softMint : AppColors.border), labelStyle: TextStyle(color: _filter == filter ? AppColors.deepTeal : AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w700)))).toList())),
        const SizedBox(height: 14),
        StockMateCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), color: AppColors.softSurface, child: Row(children: [Expanded(child: Text('${visible.length} products', style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w700))), const Text('Stock value ', style: TextStyle(fontSize: 10, color: AppColors.mutedText)), Text('M ${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.darkForest, fontWeight: FontWeight.w800))])),
        const SizedBox(height: 10),
        if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.deepTeal)))
        else if (visible.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No products match your search.', style: TextStyle(color: AppColors.mutedText))))
        else ...visible.map((product) => Column(children: [
              _ProductRow(product: product, onTap: () => _showDetails(product)),
              const Divider(height: 1, color: AppColors.border),
            ])),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});
  final StockProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = product.isOutOfStock ? AppColors.danger : product.isLowStock ? AppColors.warning : AppColors.success;
    final statusBackground = product.isOutOfStock ? AppColors.dangerBackground : product.isLowStock ? AppColors.warningBackground : AppColors.successBackground;
    final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Container(width: 47, height: 47, decoration: BoxDecoration(color: Color(product.colorValue), borderRadius: BorderRadius.circular(13)), child: Center(child: Text(initial, style: const TextStyle(color: AppColors.deepTeal, fontSize: 16, fontWeight: FontWeight.w800)))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${product.category} · ${product.sku}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
        const SizedBox(height: 5),
        Text('M ${product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.darkForest, fontSize: 11, fontWeight: FontWeight.w700)),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${product.quantity} in stock', style: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(15)), child: Text(product.isOutOfStock ? 'Out' : product.isLowStock ? 'Low' : 'In stock', style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700))),
      ]),
    ])));
  }
}
