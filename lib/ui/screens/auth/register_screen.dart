import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_role.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Registration screen with name, email, password, role selection.
class RegisterScreen extends StatefulWidget {
  final void Function(UserRole role) onRegisterSuccess;
  final VoidCallback onLoginClick;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onLoginClick,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  UserRole _selectedRole = UserRole.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // Listen for state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authVM.status == AuthStatus.success &&
              authVM.currentUser != null) {
            widget.onRegisterSuccess(authVM.currentUser!.role);
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
                    'Registrazione',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() =>
                            _confirmPasswordVisible =
                                !_confirmPasswordVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Iscriviti come:',
                      style: Theme.of(context).textTheme.titleMedium),
                  ...UserRole.values.map((role) => RadioListTile<UserRole>(
                        title: Text(role.displayName),
                        value: role,
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      )),
                  const SizedBox(height: 24),

                  // Verification email dialog
                  if (authVM.status == AuthStatus.verificationEmailSent) ...[
                    Builder(builder: (ctx) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: ctx,
                          barrierDismissible: false,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Verifica Email'),
                            content: Text(
                              'Ti abbiamo inviato un\'email di verifica a ${_emailController.text}. '
                              'Per favore controlla la tua posta e clicca sul link prima di accedere.',
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(dialogCtx).pop();
                                  authVM.resetState();
                                  widget.onLoginClick();
                                },
                                child: const Text('Vai al Login'),
                              ),
                            ],
                          ),
                        );
                      });
                      return const SizedBox.shrink();
                    }),
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
                          authVM.register(
                            _nameController.text,
                            _emailController.text,
                            _passwordController.text,
                            _confirmPasswordController.text,
                            _selectedRole,
                          );
                        },
                        child: const Text('Registrati'),
                      ),
                    ),
                  TextButton(
                    onPressed: widget.onLoginClick,
                    child: const Text('Hai già un account? Accedi'),
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
