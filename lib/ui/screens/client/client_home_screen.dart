import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/business.dart';
import '../../../data/models/service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/client_viewmodel.dart';

/// Main home screen for the Client role.
class ClientHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onProfileClick;
  final void Function(String businessId) onBusinessClick;

  const ClientHomeScreen({
    super.key,
    required this.onLogout,
    required this.onProfileClick,
    required this.onBusinessClick,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClientViewModel, AuthViewModel>(
      builder: (context, clientVM, authVM, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Prenota Servizi'),
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
              _ExploreTab(
                clientVM: clientVM,
                onBusinessClick: widget.onBusinessClick,
              ),
              _MyBookingsTab(clientVM: clientVM),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (i) => setState(() => _selectedTab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.search), label: 'Esplora'),
              NavigationDestination(
                  icon: Icon(Icons.date_range), label: 'Prenotazioni'),
            ],
          ),
        );
      },
    );
  }
}

// ─── Explore Tab ──────────────────────────────────────────────

class _ExploreTab extends StatelessWidget {
  final ClientViewModel clientVM;
  final void Function(String) onBusinessClick;

  const _ExploreTab({required this.clientVM, required this.onBusinessClick});

  static const _categories = [
    'Tutte', 'Medicina', 'Legal', 'Beauty', 'Ristorazione', 'Istruzione', 'Altro'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: clientVM.onSearchQueryChange,
            decoration: InputDecoration(
              hintText: 'Cerca azienda o servizio...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = clientVM.selectedCategory == cat;
              return FilterChip(
                selected: selected,
                label: Text(cat),
                onSelected: (_) => clientVM.onCategorySelected(cat),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (clientVM.availableBusinesses.isNotEmpty) ...[
                Text(
                  'Aziende e Professionisti',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...clientVM.availableBusinesses.map((b) => _BusinessCard(
                      business: b,
                      onTap: () => onBusinessClick(b.id),
                    )),
                const SizedBox(height: 24),
              ],
              Text(
                'Servizi Disponibili',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (clientVM.availableServices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nessun servizio trovato.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...clientVM.availableServices.map((s) => _ServiceCard(
                      service: s,
                      onBook: () => _showBookingDialog(context, s),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (_) => _BookingDialog(
        service: service,
        clientVM: context.read<ClientViewModel>(),
      ),
    );
  }
}

// ─── Business Card ────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(business.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(business.category,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(business.description),
              Text(business.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onBook;

  const _ServiceCard({required this.service, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onBook,
                child: const Text('Prenota Ora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Bookings Tab ──────────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  final ClientViewModel clientVM;

  const _MyBookingsTab({required this.clientVM});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF4CAF50);
      case 'Completed':
        return const Color(0xFF2196F3);
      case 'Rejected':
        return const Color(0xFFF44336);
      case 'Canceled':
        return const Color(0xFF9E9E9E);
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
      case 'Canceled':
        return const Color(0xFFEEEEEE);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = clientVM.myBookings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Le Mie Prenotazioni',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Non hai ancora prenotazioni.',
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
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                    if (booking.status == 'Pending' ||
                        booking.status == 'Confirmed') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              _showCancelDialog(context, booking),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Annulla Prenotazione',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                    if (booking.status == 'Completed') ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showReviewDialog(context, booking),
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text('Lascia Recensione'),
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

  void _showCancelDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annulla Prenotazione'),
        content: Text(
            'Sei sicuro di voler annullare la prenotazione per ${booking.serviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Indietro'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              clientVM.cancelBooking(booking.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Conferma Annullamento'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (_) => _ReviewDialog(
        serviceName: booking.serviceName,
        onConfirm: (rating, comment) {
          clientVM.addReview(
              booking.serviceId, booking.serviceName, rating, comment);
        },
      ),
    );
  }
}

// ─── Booking Dialog ───────────────────────────────────────────

class _BookingDialog extends StatefulWidget {
  final Service service;
  final ClientViewModel clientVM;

  const _BookingDialog({required this.service, required this.clientVM});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  String? _selectedDateText;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    widget.clientVM.fetchProviderAvailability(widget.service.providerId);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      final dateStr = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _selectedDateText = dateStr;
        _selectedSlot = null;
      });
      await widget.clientVM.generateSlots(widget.service, dateStr);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Prenota ${widget.service.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.date_range),
                label: Text(_selectedDateText ?? 'Seleziona Data'),
              ),
            ),
            if (_selectedDateText != null) ...[
              const SizedBox(height: 16),
              const Text('Orari disponibili:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (widget.clientVM.availableSlots.isEmpty)
                const Text(
                  'Nessuno slot disponibile per questo giorno.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.clientVM.availableSlots.map((slot) {
                    final selected = _selectedSlot == slot;
                    return FilterChip(
                      selected: selected,
                      label: Text(slot),
                      onSelected: (_) =>
                          setState(() => _selectedSlot = slot),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _selectedSlot != null
              ? () {
                  widget.clientVM.bookService(
                    widget.service,
                    '$_selectedDateText $_selectedSlot',
                  );
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}

// ─── Review Dialog ────────────────────────────────────────────

class _ReviewDialog extends StatefulWidget {
  final String serviceName;
  final void Function(int rating, String comment) onConfirm;

  const _ReviewDialog({required this.serviceName, required this.onConfirm});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Recensisci ${widget.serviceName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valutazione:'),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  Icons.star,
                  color: index < _rating
                      ? const Color(0xFFFFB400)
                      : Colors.grey,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Commento',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_rating, _commentController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Invia'),
        ),
      ],
    );
  }
}
