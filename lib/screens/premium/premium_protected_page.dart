
import 'package:flutter/material.dart';
import 'package:myyearmystory/utils/access_control.dart';

class PremiumProtectedPage extends StatelessWidget {
  final Widget child;

  const PremiumProtectedPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 Check automático
    AccessControl.checkAccess(context);
    return child;
  }
}
