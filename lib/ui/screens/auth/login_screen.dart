import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_role.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Login screen with email/password and password reset.
class LoginScreen extends StatefulWidget {
  final void Function(UserRole role) onLoginSuccess;
  final VoidCallback onRegisterClick;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onRegisterClick,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _passwordVisible = false;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  void _showResetDialog(BuildContext context) {
    _resetEmailController.text = _emailController.text;
    showDialog(
      context: context,
      builder: (ctx) {
        final authVM = context.read<AuthViewModel>();
        return AlertDialog(
          title: const Text('Recupero Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Inserisci la tua email per ricevere il link di reset:'),
              const SizedBox(height: 8),
              TextField(
                controller: _resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                authVM.resetPassword(_resetEmailController.text);
                Navigator.of(ctx).pop();
              },
              child: const Text('Invia'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // Listen for state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authVM.status == AuthStatus.success &&
              authVM.currentUser != null) {
            widget.onLoginSuccess(authVM.currentUser!.role);
            authVM.resetState();
          } else if (authVM.status == AuthStatus.passwordResetSent) {
            setState(() {
              _successMessage =
                  'Email di reset inviata! Controlla la tua posta.';
            });
            authVM.resetState();
          }
        });

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EasyBook',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accedi al tuo account',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showResetDialog(context),
                      child: const Text('Password dimenticata?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_successMessage != null) ...[
                    Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (authVM.status == AuthStatus.error) ...[
                    Text(
                      authVM.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (authVM.status == AuthStatus.loading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _successMessage = null);
                          authVM.login(
                            _emailController.text,
                            _passwordController.text,
                          );
                        },
                        child: const Text('Accedi'),
                      ),
                    ),
                  TextButton(
                    onPressed: widget.onRegisterClick,
                    child: const Text('Non hai un account? Registrati'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
