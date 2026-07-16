import 'package:flutter/material.dart';

/// Section title — parity with vcareapp [SectionHeading].
class ClientDetailSectionHeading extends StatelessWidget {
  const ClientDetailSectionHeading(
    this.text, {
    super.key,
    this.trailing,
    this.bottomMargin = 12,
  });

  final String text;
  final Widget? trailing;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    if (trailing != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: Row(
          children: [
            Expanded(child: _Title(text: text)),
            trailing!,
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: _Title(text: text),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}
