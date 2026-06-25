import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/documents/data/mappers/agent_file_mapper.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';

void main() {
  group('AgentFileModelMapper', () {
    test('maps file payload and resolves relative url', () {
      const hostBaseUrl = 'https://dev-api-v4.vitafyhealth.com/';

      final entity = AgentFileModel.fromJson({
        'id': '09f5ce8e-3936-49e4-babf-dc13fe0c2d03',
        'name': 'this.jpg',
        'url': 'test/9346ddf1-c96c-4bc7-9d3b-e2df2c81afd8944441926674748496.jpg',
        'category': 'CLIENT',
        'categoryReferenceId': '49003cc0-da6e-4776-a7da-dc6868be898c',
        'createdAt': '2026-06-25T11:06:33.526Z',
      }).toEntity(hostBaseUrl: hostBaseUrl);

      expect(entity.id, '09f5ce8e-3936-49e4-babf-dc13fe0c2d03');
      expect(entity.name, 'this.jpg');
      expect(
        entity.url,
        'https://dev-api-v4.vitafyhealth.com/api/test/9346ddf1-c96c-4bc7-9d3b-e2df2c81afd8944441926674748496.jpg',
      );
      expect(entity.category, 'CLIENT');
    });
  });

  group('documentItemFromAgentFile', () {
    test('maps client category to client detail link', () {
      final item = documentItemFromAgentFile(
        AgentFileModel.fromJson({
          'id': '1',
          'name': 'photo.jpg',
          'url': 'https://example.com/photo.jpg',
          'category': 'CLIENT',
          'categoryReferenceId': 'client-1',
          'createdAt': '2026-06-25T11:06:33.526Z',
        }).toEntity(hostBaseUrl: 'https://example.com/'),
      );

      expect(item.sourceLabel, 'Client document');
      expect(item.sourceRouteName, isNotNull);
      expect(item.sourceRouteParameters, {'id': 'client-1'});
      expect(isDocumentImage(item.dataUrl, item.name), isTrue);
    });
  });
}
