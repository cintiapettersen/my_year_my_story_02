import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RemoteDataWrapper extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final Widget child;

  const RemoteDataWrapper({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 42,
                color: Colors.black45,
              ),
              const SizedBox(height: 16),
              Text(
                tr('common.offline_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('common.offline_message'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
  onPressed: onRetry,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE25BA6), // rosa do app 🌸
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
  ),
  child: Text(tr('common.try_again')),
),

            ],
          ),
        ),
      );
    }

    return child;
  }
}
