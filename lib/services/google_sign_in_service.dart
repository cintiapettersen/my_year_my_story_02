import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? SupabaseConfig.googleClientIdWeb : SupabaseConfig.googleClientIdAndroid,
  );

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🚀 Iniciando Google Sign-In...');
      print('📱 Plataforma: ${kIsWeb ? "Web" : "Mobile"}');
      print('🔑 Client ID configurado: ${kIsWeb ? SupabaseConfig.googleClientIdWeb : "null (para mobile)"}');
      
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      print('🔄 Sign out realizado com sucesso');
      
      print('📞 Chamando _googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('📥 Resposta do Google: ${googleUser != null ? googleUser.email : "null"}');
      
      if (googleUser == null) {
        print('❌ Google User é null - login cancelado');
        return {
          'success': false,
          'message': 'Login cancelado pelo usuário.',
        };
      }

      print('🔐 Obtendo tokens de autenticação...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      print('🎟️ Access Token: ${accessToken != null ? "✅ Obtido" : "❌ Null"}');
      print('🎫 ID Token: ${idToken != null ? "✅ Obtido" : "❌ Null"}');

      if (accessToken == null) {
        print('❌ Access token é null');
        return {
          'success': false,
          'message': 'Erro ao obter token de acesso do Google.',
        };
      }

      if (idToken == null) {
        print('❌ ID token é null');
        return {
          'success': false,
          'message': 'Erro ao obter token de identificação do Google.',
        };
      }

      print('📡 Enviando tokens para Supabase...');
      // Sign in to Supabase with the Google tokens
      final AuthResponse authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      print('📬 Resposta do Supabase: ${authResponse.user != null ? "✅ Usuário autenticado" : "❌ Falha na autenticação"}');

      if (authResponse.user != null) {
        print('👤 Usuário autenticado: ${authResponse.user!.email}');
        print('🔗 Session ativa: ${authResponse.session != null ? "✅" : "❌"}');
        
        // Create user profile if it doesn't exist
        print('🏗️ Iniciando criação/verificação de perfil...');
        await _ensureUserProfile(authResponse.user!);
        print('✅ Processo de perfil concluído');
        
        // Double-check session is still valid
        final currentUser = Supabase.instance.client.auth.currentUser;
        print('🔍 Verificação final - Usuário atual: ${currentUser != null ? currentUser.email : "❌ Null"}');
        
        return {
          'success': true,
          'message': 'Login com Google realizado com sucesso!',
          'user': authResponse.user,
          'hasValidSession': currentUser != null,
        };
      } else {
        print('❌ AuthResponse.user é null');
        return {
          'success': false,
          'message': 'Erro na autenticação com Supabase.',
        };
      }
    } catch (e) {
      print('💥 ERRO no Google Sign-In: $e');
      print('📝 Tipo do erro: ${e.runtimeType}');
      
      String errorMessage = 'Erro no login com Google. Tente novamente.';
      String errorString = e.toString().toLowerCase();
      
      if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      } else if (errorString.contains('cancelled') || errorString.contains('canceled')) {
        errorMessage = 'Login cancelado pelo usuário.';
      } else if (errorString.contains('sign_in_required')) {
        errorMessage = 'É necessário fazer login com o Google.';
      } else if (errorString.contains('sign_in_failed')) {
        errorMessage = 'Falha no login com Google. Tente novamente.';
      } else if (errorString.contains('popup_blocked')) {
        errorMessage = 'Popup bloqueado pelo navegador. Permita popups e tente novamente.';
      } else if (errorString.contains('web_context_canceled')) {
        errorMessage = 'Login cancelado. Tente novamente.';
      } else if (errorString.contains('api_not_available')) {
        errorMessage = 'Google Sign-In indisponível neste momento.';
      } else {
        // Mostrar erro completo para debug
        errorMessage = 'Erro: ${e.toString()}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  static Future<void> _ensureUserProfile(User user) async {
    try {
      print('👤 Verificando perfil do usuário: ${user.email}');
      
      // Check if user profile already exists
      final existingProfile = await SupabaseService.selectOne(
        'users',
        where: 'id',
        equals: user.id,
      );

      print('🔍 Perfil existente: ${existingProfile != null ? "✅ Encontrado" : "❌ Não encontrado"}');

      if (existingProfile == null) {
        print('🏗️ Criando novo perfil do usuário...');
        
        // Extract user info from metadata
        final fullName = user.userMetadata?['full_name'] ?? 
                         user.userMetadata?['name'] ?? 
                         user.email?.split('@').first ?? 
                         'Usuário';
        
        final avatarUrl = user.userMetadata?['avatar_url'] ?? 
                          user.userMetadata?['picture'];
        
        print('📝 Dados do perfil: Nome="$fullName", Avatar=${avatarUrl != null ? "✅" : "❌"}');
        
        // Create user profile with retry logic
        final profileData = {
          'id': user.id,
          'email': user.email,
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await SupabaseService.insert('users', profileData);
        print('✅ Perfil do usuário criado com sucesso!');
      } else {
        print('ℹ️ Perfil já existe, prosseguindo...');
      }
    } catch (e) {
      print('⚠️ Erro ao criar/verificar perfil do usuário: $e');
      print('📋 Detalhes do erro: ${e.runtimeType}');
      
      // Don't fail the login process, but log detailed error
      // The user can still authenticate even if profile creation fails
      print('🔄 Continuando com o login mesmo sem criar o perfil...');
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}