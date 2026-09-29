import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

/// Screen for viewing/editing user profile, changing password, and deleting account.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAccountDeleted;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onAccountDeleted,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // Handle state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authVM.status == AuthStatus.passwordUpdated) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Password Aggiornata'),
                content: const Text(
                    'La tua password è stata modificata con successo.'),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      authVM.resetState();
                      widget.onBack();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (authVM.status == AuthStatus.accountDeleted) {
            widget.onAccountDeleted();
          }
        });

        final user = authVM.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Il Mio Profilo'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Info Card
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dati Account',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        if (user != null) ...[
                          Text('Nome: ${user.name}'),
                          Text('Email: ${user.email}'),
                          Text('Ruolo: ${user.role.name.toUpperCase()}'),
                        ] else if (authVM.status == AuthStatus.loading)
                          const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Text(
                              "Impossibile caricare i dati dell'account."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Change Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Modifica Password',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nuova Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Conferma Nuova Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (authVM.status == AuthStatus.error) ...[
                  Text(authVM.errorMessage,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                ],
                if (authVM.status == AuthStatus.loading && user != null)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_newPasswordController.text ==
                            _confirmPasswordController.text) {
                          authVM
                              .updatePassword(_newPasswordController.text);
                        }
                      },
                      child: const Text('Salva Nuova Password'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(context, authVM),
                      icon: const Icon(Icons.delete),
                      label: const Text('Elimina Account Definitivamente'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Account'),
        content: const Text(
          'Sei sicuro di voler eliminare definitivamente il tuo account? '
          'Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              authVM.deleteAccount();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
