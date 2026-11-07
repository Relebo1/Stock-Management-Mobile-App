import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../inventory/domain/stock_product.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inventory/presentation/product_details_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _signedIn = false;
  int _selectedIndex = 0;

  void _navigate(int index) {
    if (index == 2) {
      _openScanner();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openScanner() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF102321),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: SafeArea(
          child: Column(children: [
            Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white))),
            const Spacer(),
            Container(width: 260, height: 190, decoration: BoxDecoration(border: Border.all(color: AppColors.limeAccent, width: 2), borderRadius: BorderRadius.circular(22)), child: const Center(child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 62))),
            const SizedBox(height: 24),
            const Text('Scan a product barcode', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Align the barcode within the frame', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Enter barcode manually', style: TextStyle(color: AppColors.limeAccent))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Future<void> _showProduct(StockProduct product) => showModalBottomSheet<void>(
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

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return SignInScreen(onSignedIn: () => setState(() => _signedIn = true));
    }
    final screens = [
      DashboardScreen(onNavigate: _navigate, onProductTap: _showProduct),
      const InventoryScreen(),
      const _TransactionsScreen(),
      _MoreScreen(onSignOut: () => setState(() => _signedIn = false)),
    ];
    final mappedIndex = _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: mappedIndex, children: screens),
      bottomNavigationBar: _StockMateBottomNavigation(selectedIndex: _selectedIndex, onSelect: _navigate, onScan: _openScanner),
    );
  }
}

class _StockMateBottomNavigation extends StatelessWidget {
  const _StockMateBottomNavigation({required this.selectedIndex, required this.onSelect, required this.onScan});
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 72 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(children: [
                Expanded(child: _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', active: selectedIndex == 0, onTap: () => onSelect(0))),
                Expanded(child: _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Inventory', active: selectedIndex == 1, onTap: () => onSelect(1))),
                const SizedBox(width: 62),
                Expanded(child: _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Transactions', active: selectedIndex == 3, onTap: () => onSelect(3))),
                Expanded(child: _NavItem(icon: Icons.more_horiz_rounded, activeIcon: Icons.more_horiz_rounded, label: 'More', active: selectedIndex == 4, onTap: () => onSelect(4))),
              ]),
            ),
          ),
          Positioned(left: 0, right: 0, top: -22, child: Center(child: GestureDetector(onTap: onScan, child: Container(width: 57, height: 57, decoration: BoxDecoration(color: AppColors.deepTeal, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: AppColors.deepTeal.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 7))]), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24))))),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(active ? activeIcon : icon, size: 21, color: active ? AppColors.deepTeal : AppColors.subtleText), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.deepTeal : AppColors.mutedText))]));
}

class _TransactionsScreen extends StatefulWidget {
  const _TransactionsScreen();
  @override
  State<_TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<_TransactionsScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
        const Text('BUSINESS RECORDS', style: TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
        const SizedBox(height: 5),
        Text('Transactions', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.softSurface, borderRadius: BorderRadius.circular(13)), child: Row(children: [
          _TransactionTab(label: 'Sales', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
          _TransactionTab(label: 'Purchases', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
        ])),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: Text(_tab == 0 ? 'Recent sales' : 'Recent purchases', style: Theme.of(context).textTheme.titleMedium)), const Text('This month', style: TextStyle(color: AppColors.mutedText, fontSize: 10)), const Icon(Icons.keyboard_arrow_down, color: AppColors.mutedText, size: 18)]),
        const SizedBox(height: 9),
        ...(_tab == 0 ? const [
          _TransactionRow(icon: Icons.point_of_sale_outlined, title: 'Sale #SL-1042', detail: 'Today · 10:42 AM · 2 items', amount: 'M 86.50', status: 'Completed', color: AppColors.successBackground, foreground: AppColors.success),
          _TransactionRow(icon: Icons.point_of_sale_outlined, title: 'Sale #SL-1041', detail: 'Today · 9:18 AM · 1 item', amount: 'M 42.00', status: 'Completed', color: AppColors.successBackground, foreground: AppColors.success),
          _TransactionRow(icon: Icons.point_of_sale_outlined, title: 'Sale #SL-1040', detail: 'Yesterday · 4:05 PM · 4 items', amount: 'M 214.75', status: 'Completed', color: AppColors.successBackground, foreground: AppColors.success),
        ] : const [
          _TransactionRow(icon: Icons.move_to_inbox_outlined, title: 'Purchase #PO-0188', detail: 'Yesterday · Fresh Foods', amount: 'M 1,240.00', status: 'Received', color: AppColors.informationBackground, foreground: AppColors.information),
          _TransactionRow(icon: Icons.move_to_inbox_outlined, title: 'Purchase #PO-0187', detail: '5 Nov · Mountain Supply', amount: 'M 860.50', status: 'Ordered', color: AppColors.warningBackground, foreground: AppColors.warning),
        ]).map((row) => Padding(padding: const EdgeInsets.only(bottom: 9), child: row)),
      ]);
}

class _TransactionTab extends StatelessWidget {
  const _TransactionTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? AppColors.deepTeal : AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w700)))));
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.icon, required this.title, required this.detail, required this.amount, required this.status, required this.color, required this.foreground});
  final IconData icon;
  final String title, detail, amount, status;
  final Color color, foreground;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 41, height: 41, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: foreground, size: 20)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: AppColors.mutedText, fontSize: 9)), const SizedBox(height: 6), Text(status, style: TextStyle(color: foreground, fontSize: 9, fontWeight: FontWeight.w700))])), Text(amount, style: const TextStyle(color: AppColors.darkForest, fontSize: 11, fontWeight: FontWeight.w800))]));
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({required this.onSignOut});
  final VoidCallback onSignOut;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
        const Text('STOCKMATE', style: TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
        const SizedBox(height: 5),
        Text('More', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.paleMint, borderRadius: BorderRadius.circular(18)), child: const Row(children: [CircleAvatar(radius: 23, backgroundColor: AppColors.limeAccent, child: Icon(Icons.person_outline_rounded, color: AppColors.darkForest)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Demo Owner', style: TextStyle(color: AppColors.darkForest, fontSize: 13, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('StockMate Demo Business', style: TextStyle(color: AppColors.mutedText, fontSize: 10))])), Icon(Icons.chevron_right_rounded, color: AppColors.mutedText)])),
        const SizedBox(height: 22),
        const Text('BUSINESS', style: TextStyle(color: AppColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 9),
        const _SettingsTile(icon: Icons.storefront_outlined, title: 'Business profile', detail: 'Name, contact details and address'),
        const _SettingsTile(icon: Icons.people_outline_rounded, title: 'Team members', detail: 'Manage staff and access'),
        const _SettingsTile(icon: Icons.tune_rounded, title: 'Preferences', detail: 'Tax, notifications and SKU prefixes'),
        const SizedBox(height: 20),
        const Text('ACCOUNT', style: TextStyle(color: AppColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 9),
        const _SettingsTile(icon: Icons.help_outline_rounded, title: 'Help and support', detail: 'Get assistance with StockMate'),
        _SettingsTile(icon: Icons.logout_rounded, title: 'Sign out', detail: 'Leave your StockMate account', danger: true, onTap: onSignOut),
      ]);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.detail, this.danger = false, this.onTap});
  final IconData icon;
  final String title, detail;
  final bool danger;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2), leading: Icon(icon, color: danger ? AppColors.danger : AppColors.deepTeal, size: 21), title: Text(title, style: TextStyle(color: danger ? AppColors.danger : AppColors.ink, fontSize: 11, fontWeight: FontWeight.w700)), subtitle: Text(detail, style: const TextStyle(color: AppColors.mutedText, fontSize: 9)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.subtleText, size: 19));
}
