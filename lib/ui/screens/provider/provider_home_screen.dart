import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/service.dart';
import '../../../data/models/availability.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/provider_viewmodel.dart';

/// Main home screen for the Provider role.
class ProviderHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onProfileClick;

  const ProviderHomeScreen({
    super.key,
    required this.onLogout,
    required this.onProfileClick,
  });

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProviderViewModel, AuthViewModel>(
      builder: (context, providerVM, authVM, _) {
        // Show invitation dialog if there is a pending invite
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authVM.pendingInvitation != null) {
            _showInvitationDialog(context, authVM);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Emettitore'),
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
              _ServicesListTab(providerVM: providerVM),
              _ProviderBookingsTab(providerVM: providerVM),
              _ReviewsListTab(providerVM: providerVM),
              _AvailabilityTab(providerVM: providerVM),
              _StatisticsTab(providerVM: providerVM),
            ],
          ),
          floatingActionButton: _selectedTab == 0
              ? FloatingActionButton(
                  onPressed: () => _showServiceDialog(context, providerVM),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (i) => setState(() => _selectedTab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'Servizi'),
              NavigationDestination(
                  icon: Icon(Icons.date_range), label: 'Prenotazioni'),
              NavigationDestination(
                  icon: Icon(Icons.star), label: 'Recensioni'),
              NavigationDestination(
                  icon: Icon(Icons.settings), label: 'Orari'),
              NavigationDestination(icon: Icon(Icons.info), label: 'Stats'),
            ],
          ),
        );
      },
    );
  }

  void _showInvitationDialog(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Invito Supervisione'),
        content: const Text(
          'Un Responsabile desidera supervisionare il tuo account. '
          'Accettando, potrà visualizzare le tue statistiche e i tuoi servizi.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              authVM.declineInvitation();
              Navigator.of(ctx).pop();
            },
            child: const Text('Rifiuta'),
          ),
          FilledButton(
            onPressed: () {
              authVM.acceptInvitation();
              Navigator.of(ctx).pop();
            },
            child: const Text('Accetta'),
          ),
        ],
      ),
    );
  }

  void _showServiceDialog(
    BuildContext context,
    ProviderViewModel providerVM, {
    Service? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final durationCtrl = TextEditingController(
        text: existing != null ? existing.durationMinutes.toString() : '');
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.price.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Nuovo Servizio' : 'Modifica Servizio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nome', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descrizione', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Durata (min)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                    labelText: 'Prezzo (€)', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text;
              final desc = descCtrl.text;
              final dur = int.tryParse(durationCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (existing == null) {
                providerVM.addService(name, desc, dur, price);
              } else {
                providerVM.updateService(
                    existing.id, name, desc, dur, price);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}

// ─── Services List Tab ────────────────────────────────────────

class _ServicesListTab extends StatelessWidget {
  final ProviderViewModel providerVM;

  const _ServicesListTab({required this.providerVM});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('I Tuoi Servizi',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...providerVM.services.map((service) => Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(service.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('€${service.price}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(service.description,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Durata: ${service.durationMinutes} min',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            final state = context
                                .findAncestorStateOfType<
                                    _ProviderHomeScreenState>();
                            state?._showServiceDialog(
                              context,
                              providerVM,
                              existing: service,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () =>
                              providerVM.deleteService(service.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Provider Bookings Tab ────────────────────────────────────

class _ProviderBookingsTab extends StatelessWidget {
  final ProviderViewModel providerVM;

  const _ProviderBookingsTab({required this.providerVM});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF4CAF50);
      case 'Completed':
        return const Color(0xFF2196F3);
      case 'Rejected':
        return const Color(0xFFF44336);
      default:
        return Colors.deepPurple;
    }
  }

  Color _cardColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey.shade100;
      case 'Confirmed':
        return const Color(0xFFE8F5E9);
      case 'Rejected':
        return const Color(0xFFFFEBEE);
      case 'Completed':
        return const Color(0xFFE3F2FD);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = providerVM.incomingBookings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Richieste Prenotazione',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Nessuna richiesta in attesa.',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ...bookings.map((booking) => Card(
              color: _cardColor(booking.status),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(booking.serviceName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(booking.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(booking.status,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    Text('Data: ${booking.date}'),
                    if (booking.status == 'Pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => providerVM.updateBookingStatus(
                                booking.id, 'Rejected'),
                            icon: const Icon(Icons.clear),
                            label: const Text('Rifiuta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => providerVM.updateBookingStatus(
                                booking.id, 'Confirmed'),
                            icon: const Icon(Icons.check),
                            label: const Text('Accetta'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (booking.status == 'Confirmed') ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => providerVM.updateBookingStatus(
                              booking.id, 'Completed'),
                          icon: const Icon(Icons.done),
                          label: const Text('Segna come Completato'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Reviews List Tab ─────────────────────────────────────────

class _ReviewsListTab extends StatelessWidget {
  final ProviderViewModel providerVM;

  const _ReviewsListTab({required this.providerVM});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recensioni Clienti',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...providerVM.reviews.map((review) => Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.clientName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ...List.generate(
                          review.rating,
                          (_) => const Icon(Icons.star,
                              color: Color(0xFFFFB400), size: 16),
                        ),
                      ],
                    ),
                    Text(review.date,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(review.comment),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Availability Tab ─────────────────────────────────────────

class _AvailabilityTab extends StatelessWidget {
  final ProviderViewModel providerVM;

  const _AvailabilityTab({required this.providerVM});

  static const _dayNames = [
    'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'
  ];

  @override
  Widget build(BuildContext context) {
    final avail = providerVM.availability;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Gestione Orari di Lavoro',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Definisci quando sei disponibile per le prenotazioni',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        if (avail != null)
          ...avail.weeklyAvailability.map((dayAvail) =>
              _DayAvailabilityItem(
                dayName: _dayNames[dayAvail.dayOfWeek - 1],
                dayAvailability: dayAvail,
                onUpdate: (updatedDay) {
                  final newList = avail.weeklyAvailability.map((d) {
                    return d.dayOfWeek == updatedDay.dayOfWeek ? updatedDay : d;
                  }).toList();
                  providerVM.updateAvailability(
                      avail.copyWith(weeklyAvailability: newList));
                },
              )),
      ],
    );
  }
}

class _DayAvailabilityItem extends StatelessWidget {
  final String dayName;
  final DayAvailability dayAvailability;
  final void Function(DayAvailability) onUpdate;

  const _DayAvailabilityItem({
    required this.dayName,
    required this.dayAvailability,
    required this.onUpdate,
  });

  Future<void> _pickTime(
    BuildContext context,
    int rangeIndex,
    bool isStart,
  ) async {
    final currentRange = dayAvailability.timeRanges[rangeIndex];
    final currentTimeStr = isStart ? currentRange.startTime : currentRange.endTime;
    final parts = currentTimeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final newRanges = List<TimeRange>.from(dayAvailability.timeRanges);
      if (isStart) {
        newRanges[rangeIndex] = newRanges[rangeIndex].copyWith(startTime: newTime);
      } else {
        newRanges[rangeIndex] = newRanges[rangeIndex].copyWith(endTime: newTime);
      }
      onUpdate(dayAvailability.copyWith(timeRanges: newRanges));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: dayAvailability.workDay
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF5F5F5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Switch(
                  value: dayAvailability.workDay,
                  onChanged: (v) =>
                      onUpdate(dayAvailability.copyWith(workDay: v)),
                ),
              ],
            ),
            if (dayAvailability.workDay) ...[
              ...dayAvailability.timeRanges
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            ActionChip(
                              label: Text(entry.value.startTime),
                              onPressed: () =>
                                  _pickTime(context, entry.key, true),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(' - '),
                            ),
                            ActionChip(
                              label: Text(entry.value.endTime),
                              onPressed: () =>
                                  _pickTime(context, entry.key, false),
                            ),
                            const Spacer(),
                            if (dayAvailability.timeRanges.length > 1)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  final newRanges = List<TimeRange>.from(
                                      dayAvailability.timeRanges)
                                    ..removeAt(entry.key);
                                  onUpdate(dayAvailability.copyWith(
                                      timeRanges: newRanges));
                                },
                              ),
                          ],
                        ),
                      )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    final newRanges =
                        List<TimeRange>.from(dayAvailability.timeRanges)
                          ..add(const TimeRange());
                    onUpdate(
                        dayAvailability.copyWith(timeRanges: newRanges));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi Fascia Oraria'),
                ),
              ),
            ] else
              const Text('Chiuso',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Statistics Tab ───────────────────────────────────────────

class _StatisticsTab extends StatelessWidget {
  final ProviderViewModel providerVM;

  const _StatisticsTab({required this.providerVM});

  @override
  Widget build(BuildContext context) {
    final completedCount =
        providerVM.incomingBookings.where((b) => b.status == 'Completed').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Le Tue Statistiche',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Fatturato Totale'),
                  Text(
                    '€${providerVM.totalTurnover.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Servizi Attivi',
                            style: TextStyle(fontSize: 12)),
                        Text('${providerVM.services.length}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Lavori Fatti',
                            style: TextStyle(fontSize: 12)),
                        Text('$completedCount',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
