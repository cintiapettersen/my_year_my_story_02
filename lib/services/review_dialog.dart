import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_review/in_app_review.dart';





class ReviewDialog extends StatelessWidget {
  const ReviewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),

      backgroundColor: const Color.fromARGB(255, 255, 218, 230),
      content: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [

          const Icon(
  Icons.favorite_rounded,
  size: 36,
  color: Color(0xFFE04CB7), // rosinha da marca 💗
),

const SizedBox(height: 16),

         Text(
  'review.title'.tr(),
  textAlign: TextAlign.center,
),

Text(
  'review.message'.tr(),
  textAlign: TextAlign.center,
),
const SizedBox(height: 16),

          SizedBox(
  width: double.infinity,

  
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE04CB7),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  onPressed: () async {
  Navigator.pop(context);

  final inAppReview = InAppReview.instance;

  if (await inAppReview.isAvailable()) {
    await inAppReview.requestReview();
  }
},

    child: Text('review.cta'.tr()),
  ),
),

        ],
      ),
    );
  }
}
