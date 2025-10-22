import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import condicional: web usa web_storage_web.dart, mobile usa stub
import 'web_storage_stub.dart'
if (dart.library.html) 'web_storage_web.dart';

// Global supabase client instance
final SupabaseClient supabase = Supabase.instance.client;

class SupabaseConfig {
  static const String supabaseUrl = 'https://abrctowsfsgfxdoszmdq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFicmN0b3dzZnNnZnhkb3N6bWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1Nzc5MTksImV4cCI6MjA3MDE1MzkxOX0.ptaOeholjF8dBsXocOsBrSdtYidWVm2BtixsIhE2WF8';

  // Google OAuth Configuration
  static const String googleClientIdWeb =
      '240120649571-4ateuuhpbc36cbcga7ghtnq40hdhuimu.apps.googleusercontent.com';
  static const String googleClientIdAndroid =
      '240120649571-npl204vd3rfb5d82cd6g8j7h13jmkee3.apps.googleusercontent.com';
  static const String googleClientSecret =
      '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';

  // Multiple redirect URLs for different environments
  static const String redirectUrl =
      'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
  static const String dreamFlowRedirectUrl =
      'https://l7gbb2ja6zoqkc1yeu48.share.dreamflow.app/';

  static SupabaseClient get client => supabase;

  static Future<void> initialize() async {
    print('🧹 Starting comprehensive cache clearing...');
    await clearAllCache();

    print('🔧 Initializing Supabase with URL: $supabaseUrl');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: true,
    );

    print('✅ Supabase initialized successfully');
    await testConnection();
  }

  static Future<void> testConnection() async {
    try {
      print('🧪 Testing Supabase connection...');
      final response = await client.from('users').select('id').limit(1);
      print('✅ Connection test successful: ${response != null}');
    } catch (e) {
      print('⚠️ Connection test failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      print('Sign out error (ignored): $e');
    }
  }

  static User? getCurrentUser() => client.auth.currentUser;

  static Future<UserResponse> updateUserMetadata(
      Map<String, dynamic> metadata) async {
    return await client.auth.updateUser(UserAttributes(data: metadata));
  }

  static Future<void> clearAllCache() async {
    print('🧹 Starting comprehensive cache clearing process...');

    // Step 1: Clear Supabase auth state
    try {
      await Supabase.instance.client.auth.signOut();
      print('✅ Supabase auth state cleared');
    } catch (e) {
      print('⚠️ Error clearing Supabase auth: $e');
    }

    // Step 2: Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences: $e');
    }

    // Step 3: Clear browser storage (web only)
    if (kIsWeb) {
      try {
        WebStorage.clear();
        print('✅ Browser storage cleared');
      } catch (e) {
        print('⚠️ Error clearing browser storage: $e');
      }
    } else {
      print('📱 Running on mobile/desktop - skipping browser storage clear');
    }

    print('🎉 Cache clearing completed!');
  }

  static Future<void> manualCacheClear() async {
    print('🔧 Manual cache clear initiated...');
    await clearAllCache();

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: true,
      );
      print('✅ Manual cache clear and reinitialization completed!');
    } catch (e) {
      print('❌ Error during reinitialization: $e');
      rethrow;
    }
  }
}

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

  static Future<bool> signInWithOAuth(String provider) async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.values.firstWhere(
              (p) => p.name == provider,
          orElse: () => OAuthProvider.google,
        ),
        redirectTo: SupabaseConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return true;
    } catch (e) {
      print('OAuth Error: $e');
      return false;
    }
  }
}

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
