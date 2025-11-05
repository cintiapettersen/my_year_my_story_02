import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import condicional: web usa web_storage_web.dart, mobile usa stub
import 'web_storage_stub.dart'
if (dart.library.html) 'web_storage_web.dart';

// 🌎 Instância global do cliente Supabase (lazy getter)
SupabaseClient get supabase => Supabase.instance.client;

class SupabaseConfig {
  static bool _initialized = false;

  // 🔗 Chaves e URLs do seu projeto Supabase
  static const String supabaseUrl = 'https://abrctowsfsgfxdoszmdq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFicmN0b3dzZnNnZnhkb3N6bWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1Nzc5MTksImV4cCI6MjA3MDE1MzkxOX0.ptaOeholjF8dBsXocOsBrSdtYidWVm2BtixsIhE2WF8';

  // 🔐 Google OAuth
  static const String googleClientIdWeb =
      '240120649571-4ateuuhpbc36cbcga7ghtnq40hdhuimu.apps.googleusercontent.com';
  static const String googleClientIdAndroid =
      '240120649571-npl204vd3rfb5d82cd6g8j7h13jmkee3.apps.googleusercontent.com';
  static const String googleClientSecret =
      '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';

  // 🌎 URLs de redirecionamento
  static const String supabaseCallbackUrl =
      'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';

  static const String appRedirectUrl = 'http://localhost:55078/';

  static SupabaseClient get client => Supabase.instance.client;

  /// 🚀 Inicializa o Supabase (somente uma vez)
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚙️ Supabase já estava inicializado.');
      return;
    }

    print('🚀 Inicializando Supabase...');

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          authFlowType: AuthFlowType.pkce,
        ),
      );

      _initialized = true;
      print('✅ Supabase inicializado com sucesso!');

      // 🧠 Testa conexão, mas sem limpar cache (mantém sessão)
      await testConnection();
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }

  /// 🧭 Garante que o Supabase esteja inicializado antes de usar
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 🔌 Testa conexão com o Supabase
  static Future<void> testConnection() async {
    try {
      print('🧪 Testando conexão com Supabase...');
      final response = await client.from('users').select('id').limit(1);
      print('✅ Conexão Supabase OK: ${response != null}');
    } catch (e) {
      print('⚠️ Falha ao testar conexão: $e');
    }
  }

  /// 👋 Faz logout completo
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      print('👋 Logout realizado com sucesso.');
    } catch (e) {
      print('⚠️ Erro ao sair da conta: $e');
    }
  }

  static User? getCurrentUser() => client.auth.currentUser;

  static Future<UserResponse> updateUserMetadata(
      Map<String, dynamic> metadata) async {
    return await client.auth.updateUser(UserAttributes(data: metadata));
  }

  /// 🧹 Limpeza manual de cache (somente se for chamada explicitamente)
  static Future<void> clearAllCache({bool silent = false}) async {
    if (!_initialized) {
      if (!silent) print('⚠️ Supabase ainda não inicializado. Pulando limpeza.');
      return;
    }

    if (!silent) print('🧹 Limpando cache local...');

    try {
      await Supabase.instance.client.auth.signOut();
      if (!silent) print('✅ Sessão Supabase limpa.');
    } catch (_) {
      if (!silent) print('⚠️ Nenhuma sessão anterior encontrada.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!silent) print('✅ SharedPreferences limpo.');
    } catch (e) {
      if (!silent) print('⚠️ Erro ao limpar SharedPreferences: $e');
    }

    if (kIsWeb) {
      try {
        WebStorage.clear();
        if (!silent) print('✅ Browser storage limpo.');
      } catch (e) {
        if (!silent) print('⚠️ Erro ao limpar browser storage: $e');
      }
    }

    if (!silent) print('🎉 Limpeza concluída!');
  }

  /// 🔧 Limpeza manual e reinicialização (somente para debug)
  static Future<void> manualCacheClear() async {
    print('🔧 Limpeza manual iniciada...');
    await clearAllCache();

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          authFlowType: AuthFlowType.pkce,
        ),
      );
      print('✅ Reinitialização após limpeza concluída.');
    } catch (e) {
      print('❌ Erro ao reinicializar Supabase: $e');
    }
  }
}

// 🔐 Utilitários de autenticação
class SupabaseAuth {
  static SupabaseClient get _client => SupabaseConfig.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// 🌸 Login com Google (corrigido para app e web)
  static Future<bool> signInWithOAuth(String provider) async {
    try {
      // Detecta automaticamente o ambiente atual
      String redirectUrl;

      if (kIsWeb) {
        // Web usa o callback do Supabase
        redirectUrl = SupabaseConfig.supabaseCallbackUrl;
      } else {
        // Mobile usa o esquema personalizado do app
        redirectUrl = 'com.myyear.my_year_my_story://login-callback/';
      }

      await _client.auth.signInWithOAuth(
        OAuthProvider.values.firstWhere(
              (p) => p.name == provider,
          orElse: () => OAuthProvider.google,
        ),
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      print('✅ OAuth iniciado com redirectTo: $redirectUrl');
      return true;
    } catch (e) {
      print('❌ OAuth Error: $e');
      return false;
    }
  }
}

// 🧠 Funções CRUD e Realtime (mantidas)
class SupabaseService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<Map<String, dynamic>>> select(
      String table, {
        String? where,
        dynamic equals,
        String? orderBy,
        bool ascending = true,
        int? limit,
      }) async {
    dynamic query = _client.from(table).select();

    if (where != null && equals != null) query = query.eq(where, equals);
    if (orderBy != null) query = query.order(orderBy, ascending: ascending);
    if (limit != null) query = query.limit(limit);

    return await query;
  }

  static Future<Map<String, dynamic>?> selectOne(
      String table, {
        String? where,
        dynamic equals,
      }) async {
    dynamic query = _client.from(table).select();
    if (where != null && equals != null) query = query.eq(where, equals);
    return await query.maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> insert(
      String table,
      Map<String, dynamic> data,
      ) async {
    return await _client.from(table).insert(data).select();
  }

  static Future<List<Map<String, dynamic>>> update(
      String table,
      Map<String, dynamic> data, {
        required String where,
        required dynamic equals,
      }) async {
    return await _client.from(table).update(data).eq(where, equals).select();
  }

  static Future<void> delete(
      String table, {
        required String where,
        required dynamic equals,
      }) async {
    await _client.from(table).delete().eq(where, equals);
  }

  static Future<List<Map<String, dynamic>>> insertMany(
      String table,
      List<Map<String, dynamic>> dataList,
      ) async {
    return await _client.from(table).insert(dataList).select();
  }

  static RealtimeChannel subscribe(
      String table,
      void Function(PostgresChangePayload payload) callback,
      ) {
    return _client
        .channel('public:$table')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: callback,
    )
        .subscribe();
  }
}
