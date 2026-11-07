import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import '../domain/stock_product.dart';

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({super.key});
  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _cost = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _minimum = TextEditingController(text: '5');
  String _category = 'Groceries';
  bool _isSaving = false;

  @override
  void dispose() { _name.dispose(); _sku.dispose(); _barcode.dispose(); _cost.dispose(); _price.dispose(); _stock.dispose(); _minimum.dispose(); super.dispose(); }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final product = StockProduct(
      name: _name.text.trim(), category: _category, sku: _sku.text.trim(), barcode: _barcode.text.trim(),
      price: double.tryParse(_price.text) ?? 0, cost: double.tryParse(_cost.text) ?? 0,
      quantity: int.tryParse(_stock.text) ?? 0, minimumStock: int.tryParse(_minimum.text) ?? 0,
      colorValue: 0xFFD8F1E9,
    );
    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 350;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(key: _formKey, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 18),
        const StockMateEyebrow('Catalogue'),
        const SizedBox(height: 5),
        Text('Add product', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Container(height: 92, decoration: BoxDecoration(color: AppColors.softSurface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(15)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: AppColors.mutedText), SizedBox(height: 6), Text('Add product photo', style: TextStyle(color: AppColors.mutedText, fontSize: 10))])),
        const SizedBox(height: 15),
        _input(_name, 'Product name', validator: _required),
        const SizedBox(height: 11),
        _responsiveRow(narrow, _input(_sku, 'SKU', validator: _required), _input(_barcode, 'Barcode')),
        const SizedBox(height: 11),
        DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Groceries', 'Drinks', 'Dairy', 'Bakery', 'Household'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) { if (value != null) setState(() => _category = value); }),
        const SizedBox(height: 11),
        _responsiveRow(narrow, _input(_cost, 'Cost price', number: true), _input(_price, 'Selling price', number: true, validator: _required)),
        const SizedBox(height: 11),
        _responsiveRow(narrow, _input(_stock, 'Opening stock', number: true), _input(_minimum, 'Minimum level', number: true)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.paleMint, borderRadius: BorderRadius.circular(13)), child: const Row(children: [Icon(Icons.info_outline_rounded, size: 17, color: AppColors.deepTeal), SizedBox(width: 8), Expanded(child: Text('Opening stock will be recorded as the first stock movement.', style: TextStyle(color: AppColors.darkForest, fontSize: 10, height: 1.4)))])),
        const SizedBox(height: 16),
        SizedBox(height: 49, child: FilledButton(onPressed: _isSaving ? null : _save, style: FilledButton.styleFrom(backgroundColor: AppColors.deepTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
      ]))),
    );
  }

  Widget _input(TextEditingController controller, String label, {bool number = false, String? Function(String?)? validator}) => TextFormField(controller: controller, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: label), validator: validator);
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  Widget _responsiveRow(bool narrow, Widget first, Widget second) => narrow ? Column(children: [first, const SizedBox(height: 11), second]) : Row(children: [Expanded(child: first), const SizedBox(width: 10), Expanded(child: second)]);
}

