import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthAppBarUi extends StatelessWidget {
  ///callback function for appbar ui
  final VoidCallback? callBack;

  const AuthAppBarUi({super.key, this.callBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      // mainAxisAlignment: .start,
      crossAxisAlignment: .end,
      children: [
        IconButton(
          onPressed: callBack ?? context.pop,
          icon: const Icon(Icons.arrow_back_ios, size: 18.0),
        ),
      ],
    );
  }
}
