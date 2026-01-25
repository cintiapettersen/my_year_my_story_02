// lib/services/profile_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;

  bool get isProfileComplete {
    return profile != null &&
        profile!['email'] != null &&
        profile!['full_name'] != null;
  }

  Future<void> load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    profile = data;
    notifyListeners();
  }

  Future<void> ensureProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      // 🆕 cria profile mínimo
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'profile_type': 'standard',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void updateLocal(Map<String, dynamic> newData) {
    profile = newData;
    notifyListeners();
  }

  bool get isPremium => (profile?['is_premium'] ?? false) == true;
}

/// 🌟 SINGLETON OFICIAL DO APP (FORA da classe)
final ProfileService profileService = ProfileService();
