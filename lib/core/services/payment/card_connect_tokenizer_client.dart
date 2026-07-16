import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/payment/card_connect_config.dart';
import 'package:vcare_admin/core/services/payment/card_connect_field_validators.dart';
import 'package:vcare_admin/core/services/payment/card_connect_types.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_payment_method_mapper.dart';

/// Calls CardSecure tokenize API directly (no WebView / iframe).
class CardConnectTokenizerClient {
  CardConnectTokenizerClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {'Content-Type': 'application/json'},
                // Do not attach VCare auth interceptors.
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  final Dio _dio;

  Future<CardConnectCardTokenResult> tokenizeCard({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvv,
  }) async {
    final account = digitsOnly(cardNumber);
    final last4 = cardLast4(account);
    if (last4 == null) {
      throw CardConnectTokenizeException('Invalid card number');
    }

    final token = await _tokenize({
      'account': account,
      'expiry': formatExpiryMmyy(month: expMonth, year: expYear),
      'cvv': digitsOnly(cvv),
    });

    return CardConnectCardTokenResult(
      paymentToken: token,
      cardLast4: last4,
      cardBrand: detectCardBrand(account),
      cardExpMonth: expMonth,
      cardExpYear: expYear,
    );
  }

  Future<CardConnectBankTokenResult> tokenizeBank({
    required String routingNumber,
    required String accountNumber,
  }) async {
    final routing = digitsOnly(routingNumber);
    final account = digitsOnly(accountNumber);
    final token = await _tokenize({'account': '$routing/$account'});

    return CardConnectBankTokenResult(
      paymentToken: token,
      accountLast4: accountLast4(account),
    );
  }

  Future<String> _tokenize(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        getCardSecureTokenizeUrl(),
        data: body,
      );

      final data = response.data;
      if (data is! Map) {
        throw CardConnectTokenizeException(
          'Unexpected response from payment provider',
        );
      }

      final parsed = CardSecureTokenizeResponse.fromJson(
        Map<String, dynamic>.from(data),
      );

      if (!parsed.isSuccess) {
        final message = parsed.message.trim().isNotEmpty
            ? parsed.message.trim()
            : 'Failed to tokenize payment method';
        throw CardConnectTokenizeException(message);
      }

      return parsed.token!;
    } on CardConnectTokenizeException {
      rethrow;
    } on DioException catch (e) {
      throw CardConnectTokenizeException(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Unable to reach payment provider',
      );
    } catch (_) {
      throw CardConnectTokenizeException(
        'Unable to tokenize payment method',
      );
    }
  }
}
