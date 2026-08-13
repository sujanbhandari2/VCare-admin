import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/widgets/tenant_branded_image.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Full wordmark above login card — parity: LoginShell.tsx `h-12 w-auto`.
class LoginWordmark extends ConsumerWidget {
  const LoginWordmark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(tenantBrandingStateProvider).branding.logoUrl;
    return TenantBrandedImage(
      source: logoUrl,
      height: 48,
      fallbackAsset: VCareAssets.logo,
    );
  }
}

/// Card shell — parity: vcare-agent-app-2.0/src/features/auth/components/LoginShell.tsx
class LoginShell extends StatelessWidget {
  const LoginShell({super.key, required this.body, this.onBack});

  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return ColoredBox(
      color: context.vcare.background,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // parity: LoginShell.tsx `w-full relative flex items-center justify-center min-h-[56px]`
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (onBack != null)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: _LoginHeaderBackButton(
                              onTap: onBack!,
                              backgroundColor: vcare.muted,
                            ),
                          ),
                        const Center(child: LoginWordmark()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: VCareColors.loginCardSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        VCareLayout.loginCardRadius,
                      ),
                      side: BorderSide(
                        color: vcare.border.withValues(alpha: 0.6),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                          child: body,
                        ),
                        const LoginFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: vcare.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 11,
                color: vcare.mutedForeground,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: "By continuing you agree to VCare's "),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: context.vcare.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: context.vcare.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: context.vcare.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'HIPAA Compliant · Secure',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,

                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular back control in the login header row — parity: LoginShell.tsx back button.
class _LoginHeaderBackButton extends StatelessWidget {
  const _LoginHeaderBackButton({
    required this.onTap,
    required this.backgroundColor,
  });

  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(LucideIcons.arrowLeft, size: 16),
        ),
      ),
    );
  }
}

class LoginStepHeader extends StatelessWidget {
  const LoginStepHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.vcare.primary.withValues(alpha: 0.1),
              borderRadius: VCareRadius.xlAll,
            ),
            child: Icon(icon, color: context.vcare.primary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: vcare.mutedForeground,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
                child: subtitle!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Text(
            'Welcome to VCare',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in or get started in one step',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class LoginTextField extends StatefulWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.autofocus = false,
    this.focusNode,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final borderColor = widget.hasError ? vcare.destructive : vcare.border;
    final focusedBorderColor = widget.hasError
        ? vcare.destructive
        : vcare.primary.withValues(alpha: 0.4);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText ? _obscured : false,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      autofocus: widget.autofocus,
      onChanged: widget.enabled ? widget.onChanged : null,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: widget.enabled ? null : vcare.mutedForeground,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: vcare.mutedForeground.withValues(alpha: 0.6),
        ),
        prefixIcon: widget.prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
                icon: Icon(
                  _obscured ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 16,
                  color: vcare.mutedForeground,
                ),
              )
            : null,
        filled: true,
        fillColor: widget.enabled
            ? vcare.muted.withValues(alpha: 0.5)
            : vcare.muted.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: borderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: vcare.border.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: focusedBorderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: vcare.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: VCareRadius.xlAll,
          borderSide: BorderSide(color: vcare.destructive, width: 2),
        ),
      ),
    );
  }
}

class LoginFieldGroup extends StatelessWidget {
  const LoginFieldGroup({super.key, required this.field, this.errorText});

  final Widget field;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: context.vcare.destructive),
            ),
          ),
        ],
      ],
    );
  }
}

class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: VCareButtonSize.md.height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: VCareButtonStyles.filled(
          background: context.vcare.primary,
          foreground: context.theme.colorScheme.onPrimary,
          size: VCareButtonSize.md,
          labelStyle: context.textTheme.medium14,
          dimWhenDisabled: !loading,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.theme.colorScheme.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: VCareButtonStyles.iconSize),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: VCareButtonStyles.iconSize,
                  ),
                ],
              ),
      ),
    );
  }
}

class LoginSocialButton extends StatelessWidget {
  const LoginSocialButton({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.lgAll,
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: VCareRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    child,
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class LoginOtpInput extends StatefulWidget {
  const LoginOtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<LoginOtpInput> createState() => _LoginOtpInputState();
}

class _LoginOtpInputState extends State<LoginOtpInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _caretController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
    _caretController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _caretController.dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  void _handleTextChange() => setState(() {});

  int get _activeIndex {
    final length = widget.controller.text.length;
    return length >= 6 ? 5 : length;
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final code = widget.controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final char = index < code.length ? code[index] : '';
              final isActive = _focusNode.hasFocus && index == _activeIndex;

              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: vcare.muted.withValues(alpha: 0.4),
                    borderRadius: VCareRadius.lgAll,
                    border: Border.all(
                      color: isActive
                          ? context.vcare.primary.withValues(alpha: 0.4)
                          : vcare.border,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: context.vcare.primary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 0,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: char.isNotEmpty
                      ? Text(
                          char,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : isActive
                      ? FadeTransition(
                          opacity: _caretController,
                          child: Container(
                            width: 1,
                            height: 16,
                            color: context.vcare.foreground,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0.01,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (value.length == 6) {
                  widget.onCompleted(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LoginClientCard extends StatelessWidget {
  const LoginClientCard({
    super.key,
    required this.fullName,
    required this.detail,
  });

  final String fullName;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.3),
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: vcare.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Or continue with'.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          Expanded(child: Divider(color: vcare.border)),
        ],
      ),
    );
  }
}
