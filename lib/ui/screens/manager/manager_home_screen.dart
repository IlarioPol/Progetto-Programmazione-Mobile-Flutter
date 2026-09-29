import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      managerVM.fetchMyProviders(authVM.userBusiness?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManagerViewModel, AuthViewModel>(
      builder: (context, managerVM, authVM, _) {
        final business = authVM.userBusiness;

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
