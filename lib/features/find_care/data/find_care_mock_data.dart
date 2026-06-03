import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/vcare_sync/data/vcare_catalog.dart';

/// Mock providers aligned with vcareapp `src/lib/mock-data.ts`.
class FindCareMockData {
  FindCareMockData._();

  static const favoriteProviderIds = ['p1', 'p9', 'p12', 'p2'];

  static const providers = <Provider>[
    Provider(
      id: 'p1',
      name: 'Dr. Maya Patel, MD',
      specialty: 'Family Medicine',
      address: '120 Market St, Suite 400',
      city: 'San Francisco, CA',
      distanceMi: 1.2,
      phone: '(415) 555-0111',
      hours: 'Mon–Fri 8am–5pm',
      inNetwork: true,
      rating: 4.8,
    ),
    Provider(
      id: 'p2',
      name: 'Bay Area Cardiology',
      specialty: 'Cardiology',
      address: '455 Sutter St',
      city: 'San Francisco, CA',
      distanceMi: 2.4,
      phone: '(415) 555-0122',
      hours: 'Mon–Fri 9am–6pm',
      inNetwork: true,
      acceptingNew: false,
      rating: 4.6,
    ),
    Provider(
      id: 'p3',
      name: 'Dr. Jonah Kim, MD',
      specialty: 'Pediatrics',
      address: '78 Geary Blvd',
      city: 'San Francisco, CA',
      distanceMi: 0.8,
      phone: '(415) 555-0133',
      hours: 'Mon–Sat 8am–6pm',
      inNetwork: true,
      rating: 4.9,
    ),
    Provider(
      id: 'p9',
      name: 'MinuteCare Urgent Clinic',
      specialty: 'Urgent Care',
      address: '1200 Polk St',
      city: 'San Francisco, CA',
      distanceMi: 1.0,
      phone: '(415) 555-0199',
      hours: 'Daily 8am–10pm',
      inNetwork: true,
      rating: 4.5,
    ),
    Provider(
      id: 'p12',
      name: 'CPMC Emergency Department',
      specialty: 'Emergency Room',
      address: '1101 Van Ness Ave',
      city: 'San Francisco, CA',
      distanceMi: 1.9,
      phone: '(415) 555-0221',
      hours: '24/7',
      inNetwork: true,
      rating: 4.4,
    ),
  ];

  static Provider? providerById(String id) {
    for (final provider in providers) {
      if (provider.id == id) return provider;
    }
    final synced = VCareCatalog.providerById(id);
    if (synced == null) return null;
    return Provider(
      id: synced.id,
      name: synced.name,
      specialty: synced.specialty,
      address: synced.address,
      city: synced.city,
      distanceMi: synced.distanceMi,
      phone: synced.phone,
      hours: synced.hours,
      inNetwork: synced.inNetwork,
      rating: synced.rating,
      acceptingNew: synced.acceptingNew,
    );
  }

  static List<SavedProviderItem> savedProviders(List<String> favoriteIds) {
    return providers
        .where((p) => favoriteIds.contains(p.id))
        .map(
          (p) => SavedProviderItem(
            key: 'm-${p.id}',
            name: p.name,
            tag: p.specialty,
            location: p.distanceMi > 0
                ? '${p.distanceMi} mi · ${p.address}'
                : p.address,
            rating: p.rating,
            providerId: p.id,
            phone: p.phone,
            inNetwork: p.inNetwork,
          ),
        )
        .toList();
  }
}
