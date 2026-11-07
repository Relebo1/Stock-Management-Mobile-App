import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../data/prototype_auth_service.dart';
import '../forgot_password_screen.dart';
import '../register_screen.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.authService, this.onSignedIn});

  final AuthService authService;
  final VoidCallback? onSignedIn;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _showPassword = false;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final signedIn = await widget.authService.signIn(
      identity: _identity.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (signedIn) {
      widget.onSignedIn?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your sign-in details.')));
    }
  }

  void _forgotPassword() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()));
  }

  Future<void> _register() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RegisterScreen(authService: widget.authService)),
    );
    if (registered == true && mounted) widget.onSignedIn?.call();
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel('Email or username'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _identity,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'you@business.com', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter your email or username' : null,
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: TextButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  child: Text(_showPassword ? 'Hide' : 'Show', style: const TextStyle(color: AppColors.deepTeal, fontWeight: FontWeight.w700)),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.deepTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Remember me', style: TextStyle(color: Color(0xFF566A64), fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot password?', style: TextStyle(color: AppColors.deepTeal, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _signIn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Sign in with your account details, or create an account below.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText, fontSize: 10, height: 1.45)),
            const SizedBox(height: 8),
            TextButton(onPressed: _register, child: const Text('New to StockMate? Create an account', style: TextStyle(color: AppColors.deepTeal, fontSize: 11, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(color: AppColors.darkForest, fontSize: 13, fontWeight: FontWeight.w700),
      );
}
