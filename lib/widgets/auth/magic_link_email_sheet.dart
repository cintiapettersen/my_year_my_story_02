// lib/widgets/auth/magic_link_email_sheet.dart
import 'package:flutter/material.dart';
import 'package:my_year_my_story/theme.dart';
import 'package:my_year_my_story/widgets/auth/auth_button.dart';

/// Exibe um bottom sheet para solicitar o email usado no login por Magic Link.
/// Retorna o email validado ou `null` se o usuário fechar o modal.
Future<String?> showMagicLinkEmailSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String emailLabel,
  required String emailEmptyError,
  required String emailInvalidError,
  required String confirmLabel,
  String? initialEmail,
}) async {
  final emailController = TextEditingController(text: initialEmail ?? '');
  final formKey = GlobalKey<FormState>();
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  String? result;

  try {
    result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () => FocusScope.of(sheetContext).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Text(
                          title,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: LightModeColors.lightSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.black87,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: emailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return emailEmptyError;
                            if (!emailRegex.hasMatch(email)) {
                              return emailInvalidError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: AuthButton(
                            text: confirmLabel,
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                final trimmed = emailController.text.trim();
                                final navigator = Navigator.of(sheetContext);
                                if (navigator.canPop()) {
                                  navigator.pop(trimmed);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } finally {
    emailController.dispose();
  }

  return result?.trim();
}
