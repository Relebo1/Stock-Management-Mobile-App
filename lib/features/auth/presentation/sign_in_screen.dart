import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import '../data/prototype_auth_service.dart';
import 'widgets/brand_lockup.dart';
import 'widgets/sign_in_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.authService = const PrototypeAuthService(), this.onSignedIn});

  final AuthService authService;
  final VoidCallback? onSignedIn;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + keyboardInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLockup(),
                  const SizedBox(height: 35),
                  const StockMateEyebrow('Welcome back', color: AppColors.deepTeal),
                  const SizedBox(height: 8),
                  Text('Sign in to your business', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text('Keep your stock accurate and your business moving.', style: TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 25),
                  SignInForm(authService: authService, onSignedIn: onSignedIn),
                  const SizedBox(height: 22),
                  const _InventoryInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryInfoCard extends StatelessWidget {
  const _InventoryInfoCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.paleMint, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: AppColors.limeAccent, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.analytics_outlined, color: AppColors.darkForest, size: 22)),
          const SizedBox(width: 13),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your inventory, under control.', style: TextStyle(color: AppColors.darkForest, fontSize: 12, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Track stock, sales and purchases in one place.', style: TextStyle(color: AppColors.mutedText, fontSize: 10, height: 1.4)),
          ])),
        ]),
      );
}
