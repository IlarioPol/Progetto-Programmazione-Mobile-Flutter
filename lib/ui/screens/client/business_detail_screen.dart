import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/service.dart';
import '../../viewmodels/client_viewmodel.dart';
import 'client_home_screen.dart';

/// Screen showing details of a business (gallery, info, team, service catalog).
class BusinessDetailScreen extends StatefulWidget {
  final String businessId;
  final VoidCallback onBack;

  const BusinessDetailScreen({
    super.key,
    required this.businessId,
    required this.onBack,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  List<AppUser> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    final clientVM = context.read<ClientViewModel>();
    clientVM.fetchTeamMembers(widget.businessId).then((members) {
      if (mounted) setState(() => _teamMembers = members);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientViewModel>(
      builder: (context, clientVM, _) {
        final business = clientVM.allBusinesses
                .where((b) => b.id == widget.businessId)
                .firstOrNull ??
            clientVM.availableBusinesses
                .where((b) => b.id == widget.businessId)
                .firstOrNull;
        final businessServices =
            clientVM.getServicesForBusiness(widget.businessId);

        return Scaffold(
          appBar: AppBar(
            title: Text(business?.name ?? 'Dettagli Azienda'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: business == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Gallery
                    if (business.imageUrls.isNotEmpty) ...[
                      Text('Galleria',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemCount: business.imageUrls.length,
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: business.imageUrls[i],
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informazioni',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(business.description),
                            const SizedBox(height: 8),
                            Text('Indirizzo: ${business.address}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            Text('Categoria: ${business.category}',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Team
                    if (_teamMembers.isNotEmpty) ...[
                      Text('Il Nostro Team',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._teamMembers.map((member) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(Icons.person,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                const SizedBox(width: 12),
                                Text(member.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Service Catalog
                    Text('Catalogo Servizi',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (businessServices.isEmpty)
                      const Text(
                          'Nessun servizio disponibile al momento.',
                          style: TextStyle(color: Colors.grey))
                    else
                      ...businessServices.map((s) => _ServiceCardDetail(
                            service: s,
                            onBook: () => _showBookingDialog(context, s),
                          )),
                  ],
                ),
        );
      },
    );
  }

  void _showBookingDialog(BuildContext context, Service service) {
    showDialog(
      context: context,
      builder: (_) => BookingDialog(
        service: service,
        clientVM: context.read<ClientViewModel>(),
      ),
    );
  }
}

class _ServiceCardDetail extends StatelessWidget {
  final Service service;
  final VoidCallback onBook;

  const _ServiceCardDetail({
    required this.service,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '€${service.price} • ${service.durationMinutes} min',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onBook,
              child: const Text('Prenota'),
            ),
          ],
        ),
      ),
    );
  }
}
