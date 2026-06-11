import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import '../entities/ava_message.dart';

abstract class AvaRepository {
  Future<EitherResponseOrException<List<AvaMessage>>> getMessages();
  Future<EitherResponseOrException<AvaMessage>> sendMessage(String body);
  Future<EitherResponseOrException<AvaMessage>> editMessage(
    String id,
    String body,
  );
  Future<EitherResponseOrException<void>> deleteMessage(String id);
}
