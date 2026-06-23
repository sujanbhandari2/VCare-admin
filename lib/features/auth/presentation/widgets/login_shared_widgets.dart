import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';

/// Full wordmark above login card — parity: LoginShell.tsx `h-12 w-auto`.
class LoginWordmark extends StatelessWidget {
  const LoginWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VCareAssets.logo,
      height: 48,
      fit: BoxFit.contain,
      semanticLabel: 'VCare Advocacy',
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
      color: VCareColors.background,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (onBack != null)
                          Positioned(
                            left: 0,
                            child: Material(
                              color: vcare.muted,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: onBack,
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(LucideIcons.arrowLeft, size: 16),
                                ),
                              ),
                            ),
                          ),
                        const LoginWordmark(),
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
                    color: VCareColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: VCareColors.foreground,
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
                color: VCareColors.primary,
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

class LoginBackButton extends StatelessWidget {
  const LoginBackButton({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: TextButton.icon(
          onPressed: onBack,
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 14,
            color: vcare.mutedForeground,
          ),
          label: Text(
            'Back',
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
              color: VCareColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: VCareColors.primary, size: 24),
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

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      autofocus: autofocus,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: vcare.mutedForeground.withValues(alpha: 0.6),
        ),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: vcare.muted.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: vcare.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: vcare.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: VCareColors.primary.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
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
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: VCareColors.primary,
          foregroundColor: VCareColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          shadowColor: VCareColors.primary.withValues(alpha: 0.5),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VCareColors.primaryForeground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 16),
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? VCareColors.primary.withValues(alpha: 0.4)
                          : vcare.border,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: VCareColors.primary.withValues(alpha: 0.12),
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
                            color: VCareColors.foreground,
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
        borderRadius: BorderRadius.circular(16),
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
