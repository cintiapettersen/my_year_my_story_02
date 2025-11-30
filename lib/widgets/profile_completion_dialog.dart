import 'package:flutter/material.dart';
import 'package:myyearmystory/screens/menus/profile_screen.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class ProfileCompletionDialog {
  static bool _hasShownDialog = false;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_hasShownDialog) return;

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final fullName = user.userMetadata?['full_name'] ?? '';
      final birthDate = user.userMetadata?['birth_date'];
      
      // Verifica se o usuário não preencheu dados importantes
      if (fullName.isEmpty || birthDate == null) {
        _hasShownDialog = true;
        
        if (context.mounted) {
          await Future.delayed(const Duration(seconds: 2));
          
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => _buildDialog(context),
            );
          }
        }
      }
    } catch (e) {
      // Ignora erros silenciosamente
    }
  }

  static Widget _buildDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8BBD9).withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '✨ Complete seu Perfil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Adicione sua data de nascimento para receber:\n\n• Mensagens de aniversário especiais 🎂\n• Dicas baseadas no seu signo ✨\n• Marcos importantes da sua idade 🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Depois',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Completar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para resetar o flag (útil para testes)
  static void reset() {
    _hasShownDialog = false;
  }
}