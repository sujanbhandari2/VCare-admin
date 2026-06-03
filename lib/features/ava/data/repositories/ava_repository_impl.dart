import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import '../../domain/entities/ava_message.dart';
import '../../domain/repositories/ava_repository.dart';
import '../ava_mock_data.dart';

class AvaRepositoryImpl implements AvaRepository {
  @override
  Future<EitherResponseOrException<List<AvaMessage>>> getMessages() async {
    return safeNetworkCall(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      return List<AvaMessage>.from(AvaMockData.seedMessages);
    });
  }

  @override
  Future<EitherResponseOrException<AvaMessage>> sendMessage(String body) async {
    return safeNetworkCall(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      return AvaMessage(
        id: 'm-${DateTime.now().millisecondsSinceEpoch}',
        sender: AvaSender.me,
        body: body,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<AvaMessage>> editMessage(
    String id,
    String body,
  ) async {
    return safeNetworkCall(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      return AvaMessage(
        id: id,
        sender: AvaSender.me,
        body: body,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteMessage(String id) async {
    return safeNetworkCall(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
  }
}
