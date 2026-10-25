import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/business.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/manager_viewmodel.dart';

/// Main home screen for the Manager role.
class ManagerHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onProfileClick;

  const ManagerHomeScreen({
    super.key,
    required this.onLogout,
    required this.onProfileClick,
  });

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final managerVM = context.read<ManagerViewModel>();
      final bId = authVM.userBusiness?.id;
      if (bId != null && bId.isNotEmpty) {
        managerVM.listenToBusiness(bId);
        managerVM.fetchMyProviders(bId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagerViewModel, AuthViewModel>(
      builder: (context, managerVM, authVM, _) {
        final business = managerVM.currentBusiness ?? authVM.userBusiness;

        if (managerVM.currentBusiness == null &&
            business?.id != null &&
            business!.id.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            managerVM.listenToBusiness(business.id);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(business?.name ?? 'Area Manager'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: widget.onProfileClick,
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () {
                  authVM.logout();
                  widget.onLogout();
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedTab,
            children: [
              _TeamTab(managerVM: managerVM, business: business),
              _StatsTab(managerVM: managerVM),
              _BusinessProfileTab(managerVM: managerVM, business: business),
            ],
          ),
          floatingActionButton: _selectedTab == 0
              ? FloatingActionButton(
                  onPressed: () =>
                      _showInviteDialog(context, managerVM, business),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (i) => setState(() => _selectedTab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.person), label: 'Team'),
              NavigationDestination(
                  icon: Icon(Icons.bar_chart), label: 'Statistiche'),
              NavigationDestination(
                  icon: Icon(Icons.business), label: 'Profilo'),
            ],
          ),
        );
      },
    );
  }

  void _showInviteDialog(
    BuildContext context,
    ManagerViewModel managerVM,
    Business? business,
  ) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invita nuovo Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Inserisci l'email del professionista da aggiungere alla tua azienda:",
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
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
              managerVM.inviteProvider(
                  emailCtrl.text, business?.id, business?.name);
              Navigator.of(ctx).pop();
            },
            child: const Text('Invia Invito'),
          ),
        ],
      ),
    );
  }
}

// ─── Team Tab ─────────────────────────────────────────────────

class _TeamTab extends StatelessWidget {
  final ManagerViewModel managerVM;
  final Business? business;

  const _TeamTab({required this.managerVM, required this.business});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professionisti del Team',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (business != null)
            Text('Categoria: ${business!.category}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          if (managerVM.myProviders.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Nessun professionista associato.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: managerVM.myProviders.length,
                itemBuilder: (_, i) {
                  final provider = managerVM.myProviders[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(provider.name),
                      subtitle: Text(provider.email),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final ManagerViewModel managerVM;

  const _StatsTab({required this.managerVM});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard Analitica',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Turnover
        Row(
          children: [
            Expanded(child: _StatCard(
              title: 'Fatturato Totale',
              value: '€${managerVM.totalTurnover.toStringAsFixed(2)}',
            )),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(
              title: 'Questo Mese',
              value: '€${managerVM.monthlyTurnover.toStringAsFixed(2)}',
            )),
          ],
        ),
        const SizedBox(height: 16),

        // Rating
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Rating Medio Team'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      managerVM.averageRating.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Icon(Icons.star,
                        color: Color(0xFFFFB400), size: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Provider Performance
        Text('Performance Professionisti',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...managerVM.providerStats.map((stat) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stat.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rating: ${stat.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      '€${stat.turnover.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 16),

        // Service Trends
        Text('Servizi più richiesti',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...managerVM.serviceTrends.map((trend) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trend.name),
                    Text('${trend.count} prenotazioni',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )),
          ],
        ),
      ),
    );
  }
}

class _BusinessProfileTab extends StatefulWidget {
  final ManagerViewModel managerVM;
  final Business? business;

  const _BusinessProfileTab({
    required this.managerVM,
    required this.business,
  });

  @override
  State<_BusinessProfileTab> createState() => _BusinessProfileTabState();
}

class _BusinessProfileTabState extends State<_BusinessProfileTab> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.business?.description ?? '');
    _addressController =
        TextEditingController(text: widget.business?.address ?? '');
  }

  @override
  void didUpdateWidget(covariant _BusinessProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.business?.description != widget.business?.description) {
      if (_descriptionController.text.isEmpty ||
          _descriptionController.text == oldWidget.business?.description) {
        _descriptionController.text = widget.business?.description ?? '';
      }
    }
    if (oldWidget.business?.address != widget.business?.address) {
      if (_addressController.text.isEmpty ||
          _addressController.text == oldWidget.business?.address) {
        _addressController.text = widget.business?.address ?? '';
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final business = widget.business;
    if (business == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Scegli dalla galleria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scatta una foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;

      final error =
          await widget.managerVM.uploadBusinessImage(business.id, picked);
      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto caricata con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore selezione foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    if (business == null) {
      return const Center(child: Text('Nessuna azienda associata'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profilo Aziendale',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Gestisci le informazioni visibili ai clienti',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Main info Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dati Principali',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Nome: ${business.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Categoria: ${business.category}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Indirizzo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      final error = await widget.managerVM.updateBusinessInfo(
                        business.id,
                        _descriptionController.text.trim(),
                        _addressController.text.trim(),
                      );
                      if (context.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Errore salvataggio: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Modifiche salvate con successo!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Salva Modifiche'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Photo Gallery
        Text(
          'Galleria Immagini',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (widget.managerVM.isUploading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: widget.managerVM.isUploading ? null : _pickAndUploadImage,
            icon: const Icon(Icons.photo_camera_back),
            label: const Text('Aggiungi Foto'),
          ),
        ),
        const SizedBox(height: 12),

        if (business.imageUrls.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nessuna immagine caricata.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: business.imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = business.imageUrls[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 160,
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 160,
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Elimina foto'),
                                content: const Text(
                                    'Vuoi davvero eliminare questa foto dalla galleria?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Annulla'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Elimina'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true || !context.mounted) return;

                            final error = await widget.managerVM
                                .deleteImage(business.id, url);
                            if (context.mounted) {
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Errore eliminazione foto: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Foto rimossa con successo'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
