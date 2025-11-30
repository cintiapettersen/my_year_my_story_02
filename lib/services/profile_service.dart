// lib/services/profile_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;

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

  void updateLocal(Map<String, dynamic> newData) {
    profile = newData;
    notifyListeners();
  }

  bool get isPremium => (profile?['is_premium'] ?? false) == true;
}

// 🌟 SINGLETON OFICIAL DO APP
final profileService = ProfileService();
