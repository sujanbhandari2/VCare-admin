import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_hsl.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/tenant_branding/data/models/tenant_branding_model.dart';
import 'package:vcare_admin/features/tenant_branding/data/mappers/tenant_branding_mapper.dart';
import 'package:vcare_admin/features/tenant_branding/data/repositories/tenant_branding_session_store.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/features/tenant_branding/domain/tenant_branding_validators.dart';

import '../../helpers/in_memory_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TenantBrandingModel', () {
    test('maps API settings branding with defaults for nulls', () {
      final model = TenantBrandingModel.fromSettingsJson({
        'tenantId': 'tenant-1',
        'branding': {
          'primaryLogo': null,
          'iconMark': 'https://example.com/icon.png',
          'primaryColor': null,
          'secondaryColor': '#222C55',
          'accentColor': '',
        },
        'theme': {'fontThemeKey': 'editorial'},
      });

      final entity = model.toEntity();
      expect(entity.tenantId, 'tenant-1');
      expect(entity.logoUrl, isNull);
      expect(entity.iconUrl, 'https://example.com/icon.png');
      expect(entity.primaryColor, VCareColors.defaultPrimaryHex);
      expect(entity.secondaryColor, '#222C55');
      expect(entity.accentColor, VCareColors.defaultAccentHex);
      expect(entity.fontThemeKey, 'editorial');
    });

    test('falls back to vitafy font when theme key missing', () {
      final model = TenantBrandingModel.fromSettingsJson({
        'branding': {},
        'theme': {},
      });
      expect(model.fontThemeKey, VCareFontTheme.defaultKey);
    });
  });

  group('TenantBrandingSessionStore', () {
    late InMemoryStorageService storage;
    late TenantBrandingSessionStore store;

    setUp(() {
      storage = InMemoryStorageService();
      store = TenantBrandingSessionStore(storage);
    });

    test('saves and reads branding by slug', () async {
      const branding = TenantBranding(
        primaryColor: '#3B82F6',
        secondaryColor: '#222C55',
        accentColor: '#F8FAFC',
        fontThemeKey: 'modern-tech',
        logoUrl: 'https://example.com/logo.png',
      );

      await store.save(slug: 'ocean', branding: branding);

      final loaded = store.readForSlug('ocean');
      expect(loaded, isNotNull);
      expect(loaded!.primaryColor, '#3B82F6');
      expect(loaded.fontThemeKey, 'modern-tech');
      expect(loaded.logoUrl, 'https://example.com/logo.png');
      expect(store.readActiveSlug(), 'ocean');
    });

    test('readActiveOrDefaults returns defaults when empty', () {
      final branding = store.readActiveOrDefaults(fallbackSlug: 'vcare-advocacy');
      expect(branding, TenantBranding.defaults);
    });

    test('prefers auth tenant slug when active slug missing', () async {
      await storage.set(StorageKeys.authTenantSlug, 'from-auth');
      await storage.set(
        StorageKeys.tenantBranding('from-auth'),
        jsonEncode(
          const TenantBranding(
            primaryColor: '#5FA8A8',
            secondaryColor: '#7ca07d',
            accentColor: '#F8F7F2',
          ).toJson(),
        ),
      );

      final branding = store.readActiveOrDefaults();
      expect(branding.primaryColor, '#5FA8A8');
      expect(store.readActiveSlug(), 'from-auth');
    });
  });

  group('TenantBrandingValidators', () {
    test('accepts six-digit hex colors', () {
      expect(TenantBrandingValidators.isHexColor('#e06629'), isTrue);
      expect(TenantBrandingValidators.isHexColor('#FFF'), isFalse);
      expect(TenantBrandingValidators.validateHexColor(null), isNotNull);
    });

    test('accepts http and data image sources', () {
      expect(
        TenantBrandingValidators.isValidImageSource(
          'https://cdn.example.com/logo.png',
        ),
        isTrue,
      );
      expect(
        TenantBrandingValidators.isValidImageSource(
          'data:image/png;base64,abc',
        ),
        isTrue,
      );
      expect(TenantBrandingValidators.isValidImageSource(null), isTrue);
      expect(
        TenantBrandingValidators.isValidImageSource('not-an-image'),
        isFalse,
      );
    });
  });

  group('TenantColorTheme', () {
    test('matches sunset-clay defaults', () {
      final match = TenantColorTheme.match(
        primary: '#e06629',
        secondary: '#2f7f79',
        accent: '#f3f0ed',
      );
      expect(match?.key, 'sunset-clay');
    });
  });

  group('VCareTheme.light branding', () {
    test('builds ThemeData from custom primary hex', () {
      final theme = VCareTheme.light(
        input: const VCareThemeInput(
          primaryHex: '#3B82F6',
          secondaryHex: '#222C55',
          accentHex: '#F8FAFC',
          fontThemeKey: 'modern-tech',
        ),
      );

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary.toARGB32(),
          VCareHsl.colorFromHex('#3B82F6')!.toARGB32());
      final extension = theme.extension<VCareThemeExtension>();
      expect(extension, isNotNull);
      expect(extension!.fontThemeKey, 'modern-tech');
      expect(extension.primaryScale.s500.toARGB32(),
          theme.colorScheme.primary.toARGB32());
    });
  });
}
