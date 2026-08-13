import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/payment/card_connect_field_validators.dart';
import 'package:vcare_admin/core/services/payment/card_connect_tokenizer_client.dart';
import 'package:vcare_admin/core/services/payment/card_connect_types.dart';
import 'package:vcare_admin/core/services/payment/card_number_input_formatter.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_payment_method_mapper.dart';
import 'package:vcare_admin/features/clients/domain/entities/add_client_payment_method_request.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_payment_methods_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class _AddMethodOption {
  const _AddMethodOption({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String type;
  final String label;
  final String description;
  final IconData icon;
}

const _addMethodOptions = [
  _AddMethodOption(
    type: 'CARD',
    label: 'Credit / Debit Card',
    description: 'Card on file with tokenized payment details',
    icon: LucideIcons.creditCard,
  ),
  _AddMethodOption(
    type: 'BANK',
    label: 'Bank Transfer',
    description: 'Checking or savings account',
    icon: LucideIcons.landmark,
  ),
  _AddMethodOption(
    type: 'ACH',
    label: 'ACH',
    description: 'Automated bank debit',
    icon: LucideIcons.landmark,
  ),
  _AddMethodOption(
    type: 'CASH',
    label: 'Cash',
    description: 'Record cash as payment method',
    icon: LucideIcons.banknote,
  ),
];

class ClientAddPaymentMethodSheet extends ConsumerStatefulWidget {
  const ClientAddPaymentMethodSheet({
    super.key,
    required this.clientId,
    this.submitLabel,
    this.onAdded,
  });

  final String clientId;

  /// When set, CTA uses this label and [onAdded] runs after a successful save
  /// (web charge-from-add flow: `Save and pay $X`).
  final String? submitLabel;

  /// Called with the created method after save when [submitLabel] / charge flow
  /// is active. Caller is responsible for follow-up charge and toasts.
  final Future<void> Function(ClientPaymentMethod method)? onAdded;

  bool get isChargeFlow =>
      submitLabel != null && submitLabel!.trim().isNotEmpty;

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    String? submitLabel,
    Future<void> Function(ClientPaymentMethod method)? onAdded,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => ClientAddPaymentMethodSheet(
        clientId: clientId,
        submitLabel: submitLabel,
        onAdded: onAdded,
      ),
    );
  }

  @override
  ConsumerState<ClientAddPaymentMethodSheet> createState() =>
      _ClientAddPaymentMethodSheetState();
}

class _ClientAddPaymentMethodSheetState
    extends ConsumerState<ClientAddPaymentMethodSheet> {
  String? _selectedType;
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _routingController = TextEditingController();
  final _accountController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _tokenizer = CardConnectTokenizerClient();

  int? _selectedExpMonth;
  int? _selectedExpYear;

  var _isSubmitting = false;
  String? _fieldError;

  static const _expYearRange = 20;

  List<int> get _expYearOptions {
    final currentYear = DateTime.now().year;
    return List.generate(_expYearRange, (i) => currentYear + i);
  }

  List<int> get _expMonthOptions {
    final now = DateTime.now();
    final startMonth = _selectedExpYear == now.year ? now.month : 1;
    return [for (var m = startMonth; m <= 12; m++) m];
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _cardNumberController,
      _cvvController,
      _routingController,
      _accountController,
      _nicknameController,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _cardNumberController,
      _cvvController,
      _routingController,
      _accountController,
      _nicknameController,
    ]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (_fieldError != null) {
      setState(() => _fieldError = null);
    } else {
      setState(() {});
    }
  }

  bool get _needsCardFields => _selectedType == 'CARD';

  bool get _needsBankFields =>
      _selectedType == 'BANK' || _selectedType == 'ACH';

  /// Enable CTA once required fields have input; full validation runs on submit.
  bool get _hasRequiredInput {
    final type = _selectedType;
    if (type == null || _isSubmitting) return false;
    if (type == 'CASH') return true;
    if (type == 'CARD') {
      return isCompleteValidCardNumber(_cardNumberController.text) &&
          _selectedExpMonth != null &&
          _selectedExpYear != null &&
          isExpiryCurrentOrFuture(
            month: _selectedExpMonth!,
            year: _selectedExpYear!,
          ) &&
          isValidCvv(
            _cvvController.text,
            cardNumber: _cardNumberController.text,
          );
    }
    return digitsOnly(_routingController.text).length == 9 &&
        digitsOnly(_accountController.text).length >= 4;
  }

  String? get _cardNumberError =>
      cardNumberFieldError(_cardNumberController.text);

  String? get _cvvError => cvvFieldError(
    _cvvController.text,
    cardNumber: _cardNumberController.text,
  );

  String? get _cardBrandHint {
    final digits = digitsOnly(_cardNumberController.text);
    if (digits.length < 2) return null;
    final brand = detectCardBrand(digits);
    return brand == 'Card' ? null : brand;
  }

  void _onSelectType(String type) {
    setState(() {
      _selectedType = type;
      _fieldError = null;
      _selectedExpMonth = null;
      _selectedExpYear = null;
      _cardNumberController.clear();
      _cvvController.clear();
      _routingController.clear();
      _accountController.clear();
      _nicknameController.clear();
    });
  }

  void _onExpYearChanged(int? year) {
    setState(() {
      _selectedExpYear = year;
      _fieldError = null;
      if (_selectedExpMonth != null &&
          year != null &&
          !_expMonthOptions.contains(_selectedExpMonth)) {
        _selectedExpMonth = null;
      }
    });
  }

  void _onExpMonthChanged(int? month) {
    setState(() {
      _selectedExpMonth = month;
      _fieldError = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final type = _selectedType;
    if (type == null) return;

    final nickname = _nicknameController.text.trim();
    final trimmedNickname = nickname.isEmpty ? null : nickname;

    setState(() {
      _isSubmitting = true;
      _fieldError = null;
    });

    try {
      late final AddClientPaymentMethodRequest request;

      if (type == 'CASH') {
        request = AddClientPaymentMethodRequest.cash(nickname: trimmedNickname);
      } else if (type == 'CARD') {
        final month = _selectedExpMonth;
        final year = _selectedExpYear;
        final validationError = validateCardFields(
          cardNumber: _cardNumberController.text,
          expMonth: month?.toString() ?? '',
          expYear: year?.toString() ?? '',
          cvv: _cvvController.text,
        );
        if (validationError != null || month == null || year == null) {
          setState(() {
            _isSubmitting = false;
            _fieldError = validationError ?? 'Select expiration month and year';
          });
          return;
        }

        final tokenized = await _tokenizer.tokenizeCard(
          cardNumber: _cardNumberController.text,
          expMonth: month,
          expYear: year,
          cvv: _cvvController.text,
        );

        request = AddClientPaymentMethodRequest.card(
          paymentToken: tokenized.paymentToken,
          cardLast4: tokenized.cardLast4,
          cardBrand: tokenized.cardBrand,
          cardExpMonth: month,
          cardExpYear: year,
          nickname: trimmedNickname,
        );
      } else {
        final validationError = validateBankFields(
          routingNumber: _routingController.text,
          accountNumber: _accountController.text,
        );
        if (validationError != null) {
          setState(() {
            _isSubmitting = false;
            _fieldError = validationError;
          });
          return;
        }

        final tokenized = await _tokenizer.tokenizeBank(
          routingNumber: _routingController.text,
          accountNumber: _accountController.text,
        );

        if (type == 'ACH') {
          request = AddClientPaymentMethodRequest.ach(
            paymentToken: tokenized.paymentToken,
            nickname: trimmedNickname,
          );
        } else {
          request = AddClientPaymentMethodRequest.bank(
            paymentToken: tokenized.paymentToken,
            nickname: trimmedNickname,
          );
        }
      }

      if (!mounted) return;

      await ref
          .read(clientPaymentMethodsStateProvider(widget.clientId).notifier)
          .addPaymentMethod(
            request: request,
            onCompleted: (success, error, [method]) async {
              if (!mounted) return;

              if (!success || method == null) {
                setState(() => _isSubmitting = false);
                context.showVcareToast(
                  title: error ?? 'Could not add payment method',
                  variant: VcareToastVariant.destructive,
                );
                return;
              }

              if (widget.isChargeFlow && widget.onAdded != null) {
                context.pop();
                await widget.onAdded!(method);
                return;
              }

              context.showVcareToast(
                title: 'Payment method added',
                variant: VcareToastVariant.success,
              );
              context.pop();
            },
          );

      if (!mounted || !_isSubmitting) return;
      setState(() => _isSubmitting = false);
    } on CardConnectTokenizeException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _fieldError = e.message;
      });
      context.showVcareToast(
        title: e.message,
        variant: VcareToastVariant.destructive,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showVcareToast(
        title: 'Could not add payment method',
        variant: VcareToastVariant.destructive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                _selectedType == null
                    ? 'Add payment method'
                    : 'Add payment details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (_selectedType == null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
                child: Column(
                  children: [
                    for (final option in _addMethodOptions)
                      if (!widget.isChargeFlow ||
                          option.type == 'CARD' ||
                          option.type == 'BANK')
                        InkWell(
                          onTap: () => _onSelectType(option.type),
                          borderRadius: VCareRadius.lgAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.vcare.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: 16,
                                    color: context.vcare.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        option.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: vcare.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_needsCardFields) ...[
                      const _FieldLabel('Card number', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardNumberController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardNumberInputFormatter(),
                        ],
                        decoration: _inputDecoration(
                          vcare,
                          hint: 'xxxx xxxx xxxx xxxx',
                          errorText: _cardNumberError,
                          suffixText: _cardBrandHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel(
                                  'Expiry month',
                                  isRequired: true,
                                ),
                                const SizedBox(height: 6),
                                _ExpiryDropdown<int>(
                                  value: _selectedExpMonth,
                                  hint: 'Month',
                                  items: [
                                    for (final month in _expMonthOptions)
                                      DropdownMenuItem(
                                        value: month,
                                        child: Text(
                                          month.toString().padLeft(2, '0'),
                                        ),
                                      ),
                                  ],
                                  onChanged: _isSubmitting
                                      ? null
                                      : _onExpMonthChanged,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel(
                                  'Expiry year',
                                  isRequired: true,
                                ),
                                const SizedBox(height: 6),
                                _ExpiryDropdown<int>(
                                  value: _selectedExpYear,
                                  hint: 'Year',
                                  items: [
                                    for (final year in _expYearOptions)
                                      DropdownMenuItem(
                                        value: year,
                                        child: Text('$year'),
                                      ),
                                  ],
                                  onChanged: _isSubmitting
                                      ? null
                                      : _onExpYearChanged,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel('CVC/CVV', isRequired: true),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      expectedCvvLength,
                                    ),
                                  ],
                                  decoration: _inputDecoration(
                                    vcare,
                                    hint: 'xxxx',
                                    errorText: _cvvError,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_needsBankFields) ...[
                      const _FieldLabel('Routing number', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _routingController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: _inputDecoration(vcare, hint: '011401533'),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Account number', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(17),
                        ],
                        decoration: _inputDecoration(
                          vcare,
                          hint: 'Account number',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const _FieldLabel('Nickname', hint: 'Optional'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nicknameController,
                      decoration: _inputDecoration(
                        vcare,
                        hint: _selectedType == 'CASH'
                            ? 'Cash payments'
                            : 'Personal checking',
                      ),
                    ),
                    if (_fieldError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _fieldError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _selectedType = null;
                                    _selectedExpMonth = null;
                                    _selectedExpYear = null;
                                    _fieldError = null;
                                  }),
                            text: 'Back',
                            height: 44,
                            width: null,
                            borderRadius: VCareRadius.lgAll,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton.elevated(
                            onPressed: (_hasRequiredInput && !_isSubmitting)
                                ? _submit
                                : null,
                            text: _isSubmitting
                                ? (widget.isChargeFlow
                                      ? 'Processing…'
                                      : 'Adding…')
                                : (widget.submitLabel?.trim().isNotEmpty == true
                                      ? widget.submitLabel!.trim()
                                      : 'Add method'),
                            loading: _isSubmitting,
                            color: context.vcare.primary,
                            onButtonColor: context.theme.colorScheme.onPrimary,
                            height: 44,
                            width: null,
                            borderRadius: VCareRadius.lgAll,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    VCareThemeExtension vcare, {
    String? hint,
    String? errorText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      suffixText: suffixText,
      filled: true,
      fillColor: vcare.card,
      border: OutlineInputBorder(
        borderRadius: VCareRadius.lgAll,
        borderSide: BorderSide(color: vcare.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: VCareRadius.lgAll,
        borderSide: BorderSide(color: vcare.border),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: VCareRadius.lgAll,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: VCareRadius.lgAll,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.isRequired = false, this.hint});

  final String label;
  final bool isRequired;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.vcare.foreground,
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint!,
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
            ),
          ),
      ],
    );
  }
}

class _ExpiryDropdown<T> extends StatelessWidget {
  const _ExpiryDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: vcare.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: VCareRadius.lgAll,
          borderSide: BorderSide(color: vcare.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VCareRadius.lgAll,
          borderSide: BorderSide(color: vcare.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VCareRadius.lgAll,
          borderSide: BorderSide(color: context.vcare.primary),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: VCareRadius.lgAll,
          hint: Text(
            hint,
            style: TextStyle(color: vcare.mutedForeground, fontSize: 14),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
