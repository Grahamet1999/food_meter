import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication screen for email/password sign-in and registration.
/// ADA accessible and color-blind friendly.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _error;
  bool _loading = false;

  // Mirrors this Firebase project's enforced password policy (Authentication
  // > Settings > Password policy): min 8 chars, at least one uppercase,
  // one numeric, and one non-alphanumeric character from the allowed set
  // below. Only checked on Register — Sign In must still accept passwords
  // created before this policy existed.
  static const _allowedSpecialChars = r'''^$*.[]{}()?"!@#%&/\,><':;|_~`-''';

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (_isLogin) return null;
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    if (!value.split('').any((c) => _allowedSpecialChars.contains(c))) {
      return 'Password must contain a special character (e.g. ! @ # -)';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Sign In' : 'Register',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Ensures consistent background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08), // Use a semi-transparent fill for contrast
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08), // Use a semi-transparent fill for contrast
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'At least 8 characters, with an uppercase letter, a number, '
                      'and a special character.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : () {
                      if (_formKey.currentState?.validate() ?? false) _submit();
                    },
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isLogin ? 'Sign In' : 'Register'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _loading ? null : () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Create an account' : 'Already have an account? Sign In'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setState(() {
                                _error = 'Enter your email above to reset password.';
                              });
                              return;
                            }
                            setState(() { _loading = true; _error = null; });
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              setState(() {
                                _error = 'Password reset email sent! Check your inbox.';
                              });
                            } on FirebaseAuthException catch (e) {
                              setState(() { _error = e.message; });
                            } finally {
                              setState(() { _loading = false; });
                            }
                          },
                    child: const Text('Forgot password?'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
