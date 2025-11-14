import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService extends ChangeNotifier {
  Map<String, dynamic>? profile;

  final supabase = Supabase.instance.client;

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

  bool get isPremium => (profile?['is_premium'] ?? false) == true;
}

final profileService = ProfileService();
