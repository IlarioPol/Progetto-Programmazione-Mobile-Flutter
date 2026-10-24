import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

/// Screen for the Manager to set up their business.
class BusinessSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const BusinessSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Medicina';
  bool _setupTriggered = false;

  static const _categories = [
    'Medicina', 'Legal', 'Beauty', 'Ristorazione', 'Istruzione', 'Altro'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // Navigate on success or if business is already loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if ((authVM.status == AuthStatus.businessCreated ||
                  authVM.userBusiness != null) &&
              !_setupTriggered) {
            _setupTriggered = true;
            widget.onSetupComplete();
          }
        });

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Configura la tua Azienda',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completa i dati per iniziare a gestire il tuo team',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Azienda / Studio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Macro-Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Indirizzo Sede',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Breve Descrizione',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  if (authVM.status == AuthStatus.error) ...[
                    Text(authVM.errorMessage,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  if (authVM.status == AuthStatus.loading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nameController.text.isNotEmpty &&
                                _addressController.text.isNotEmpty
                            ? () {
                                authVM.createBusiness(
                                  _nameController.text,
                                  _selectedCategory,
                                  _descriptionController.text,
                                  _addressController.text,
                                );
                              }
                            : null,
                        child: const Text('Salva e Continua'),
                      ),
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
