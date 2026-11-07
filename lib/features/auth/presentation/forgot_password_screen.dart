import 'package:flutter/material.dart';

import '../../../core/widgets/stockmate_widgets.dart';
import '../../../theme/app_colors.dart';
import 'widgets/brand_lockup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendInstructions() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink)),
                      const SizedBox(width: 4),
                      const BrandLockup(),
                    ]),
                    SizedBox(height: constraints.maxHeight < 650 ? 36 : 76),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: AppColors.paleMint, borderRadius: BorderRadius.circular(23)),
                        child: Icon(_sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded, color: AppColors.deepTeal, size: 32),
                      ),
                    ),
                    const SizedBox(height: 27),
                    Center(child: StockMateEyebrow(_sent ? 'Check your inbox' : 'Account recovery', color: AppColors.deepTeal)),
                    const SizedBox(height: 8),
                    Text(_sent ? 'Instructions sent' : 'Forgot password?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 9),
                    Text(
                      _sent
                          ? 'If an account exists for ${_emailController.text.trim()}, you’ll receive instructions to reset your password.'
                          : 'Enter the email address connected to your StockMate account and we’ll help you get back in.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.55),
                    ),
                    const SizedBox(height: 27),
                    if (!_sent) ...[
                      Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Text('Email address', style: TextStyle(color: AppColors.darkForest, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(hintText: 'you@business.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email address' : null,
                            onFieldSubmitted: (_) => _sendInstructions(),
                          ),
                          const SizedBox(height: 18),
                          StockMatePrimaryButton(label: 'Send reset instructions', icon: Icons.arrow_forward_rounded, onPressed: _sendInstructions),
                        ]),
                      ),
                    ] else ...[
                      const StockMateCard(color: AppColors.paleMint, child: Row(children: [Icon(Icons.info_outline_rounded, color: AppColors.deepTeal, size: 18), SizedBox(width: 9), Expanded(child: Text('Password reset is a prototype screen. Email delivery isn’t connected yet.', style: TextStyle(color: AppColors.darkForest, fontSize: 10, height: 1.45)))])),
                      const SizedBox(height: 18),
                      OutlinedButton(onPressed: () => setState(() => _sent = false), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.deepTeal, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: const Text('Try another email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                    ],
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to sign in', style: TextStyle(color: AppColors.deepTeal, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
