import 'package:flutter/material.dart';
import 'package:myyearmystory/services/review_dialog.dart';

Future<void> showReviewPopup(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return Transform.translate(
        offset: Offset(0, (1 - curved.value) * 30),
        child: Opacity(
          opacity: animation.value,
          child: const ReviewDialog(),
        ),
      );
    },
  );
}
