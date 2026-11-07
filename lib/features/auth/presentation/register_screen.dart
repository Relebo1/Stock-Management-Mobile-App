import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../data/prototype_auth_service.dart';
import 'widgets/brand_lockup.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _businessName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _businessType = 'Retail';
  bool _showPassword = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _businessName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    final error = await widget.authService.register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      username: _username.text,
      email: _email.text,
      phone: _phone.text,
      businessName: _businessName.text,
      businessType: _businessType,
      password: _password.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() { _isSubmitting = false; _error = error; });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 350;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)), const SizedBox(width: 5), const BrandLockup()]),
                  const SizedBox(height: 25),
                  Text('Create your account', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 6),
                  const Text('Set up your StockMate login and business workspace.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 22),
                  _sectionLabel('YOUR DETAILS'),
                  const SizedBox(height: 9),
                  _row(narrow, _field(_firstName, 'First name', validator: _required), _field(_lastName, 'Last name', validator: _required)),
                  const SizedBox(height: 11),
                  _field(_username, 'Username', validator: _validateUsername, prefix: const Icon(Icons.alternate_email_rounded)),
                  const SizedBox(height: 11),
                  _field(_email, 'Email address', keyboardType: TextInputType.emailAddress, validator: _validateEmail, prefix: const Icon(Icons.mail_outline_rounded)),
                  const SizedBox(height: 11),
                  _field(_phone, 'Phone number (optional)', keyboardType: TextInputType.phone, prefix: const Icon(Icons.phone_outlined)),
                  const SizedBox(height: 20),
                  _sectionLabel('YOUR BUSINESS'),
                  const SizedBox(height: 9),
                  _field(_businessName, 'Business name', validator: _required, prefix: const Icon(Icons.storefront_outlined)),
                  const SizedBox(height: 11),
                  DropdownButtonFormField<String>(
                    value: _businessType,
                    decoration: const InputDecoration(labelText: 'Business type', prefixIcon: Icon(Icons.category_outlined)),
                    items: const ['Retail', 'Wholesale', 'Convenience store', 'Pharmacy', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) { if (value != null) setState(() => _businessType = value); },
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('SECURE YOUR ACCOUNT'),
                  const SizedBox(height: 9),
                  _field(_password, 'Password', obscure: !_showPassword, validator: _validatePassword, prefix: const Icon(Icons.lock_outline_rounded), suffix: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
                  const SizedBox(height: 11),
                  _field(_confirmPassword, 'Confirm password', obscure: true, validator: (value) => value != _password.text ? 'Passwords do not match' : null, prefix: const Icon(Icons.lock_outline_rounded)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                  ],
                  const SizedBox(height: 17),
                  SizedBox(height: 50, child: FilledButton(onPressed: _isSubmitting ? null : _createAccount, style: FilledButton.styleFrom(backgroundColor: AppColors.deepTeal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
                  const SizedBox(height: 11),
                  const Text('Creating an account gives you an owner role for this business.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedText, fontSize: 10)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: const TextStyle(color: AppColors.deepTeal, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1));

  Widget _field(TextEditingController controller, String label, {String? Function(String?)? validator, TextInputType? keyboardType, bool obscure = false, Widget? prefix, Widget? suffix}) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        textCapitalization: keyboardType == TextInputType.emailAddress ? TextCapitalization.none : TextCapitalization.words,
        decoration: InputDecoration(labelText: label, prefixIcon: prefix, suffixIcon: suffix),
        validator: validator,
      );

  Widget _row(bool narrow, Widget first, Widget second) => narrow ? Column(children: [first, const SizedBox(height: 11), second]) : Row(children: [Expanded(child: first), const SizedBox(width: 10), Expanded(child: second)]);
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Choose a username';
    if (!RegExp(r'^[a-zA-Z0-9_.-]{3,30}$').hasMatch(value.trim())) return 'Use 3–30 letters, numbers, dots or dashes';
    return null;
  }
  String? _validateEmail(String? value) {
    if (value == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) return 'Use at least 8 characters';
    if (value.length > 128) return 'Password must be at most 128 characters';
    return null;
  }
}
