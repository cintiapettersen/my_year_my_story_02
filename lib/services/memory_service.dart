import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/memory_model.dart';

class MemoryService {
  // Get memories for a story
  static Future<List<MemoryModel>> getMemoriesForStory(String storyId) async {
    final data = await SupabaseService.select(
      'memories',
      where: 'story_id',
      equals: storyId,
      orderBy: 'memory_date',
      ascending: true,
    );
    return data.map((json) => MemoryModel.fromJson(json)).toList();
  }

  // Get user's memories
  static Future<List<MemoryModel>> getUserMemories(String userId) async {
    final data = await SupabaseService.select(
      'memories',
      where: 'user_id',
      equals: userId,
      orderBy: 'memory_date',
      ascending: false,
    );
    return data.map((json) => MemoryModel.fromJson(json)).toList();
  }

  // Get memory by ID
  static Future<MemoryModel?> getMemoryById(String memoryId) async {
    final data = await SupabaseService.selectOne(
      'memories',
      where: 'id',
      equals: memoryId,
    );
    return data != null ? MemoryModel.fromJson(data) : null;
  }

  // Create new memory
  static Future<MemoryModel> createMemory({
    required String storyId,
    required String userId,
    required String title,
    String? description,
    required DateTime memoryDate,
    String? location,
    List<String> tags = const [],
  }) async {
    final data = await SupabaseService.insert('memories', {
      'story_id': storyId,
      'user_id': userId,
      'title': title,
      'description': description,
      'memory_date': memoryDate.toIso8601String().split('T')[0],
      'location': location,
      'tags': tags,
    });
    return MemoryModel.fromJson(data.first);
  }

  // Update memory
  static Future<MemoryModel> updateMemory(String memoryId, Map<String, dynamic> updates) async {
    final data = await SupabaseService.update(
      'memories',
      updates,
      where: 'id',
      equals: memoryId,
    );
    return MemoryModel.fromJson(data.first);
  }

  // Delete memory
  static Future<void> deleteMemory(String memoryId) async {
    await SupabaseService.delete(
      'memories',
      where: 'id',
      equals: memoryId,
    );
  }

  // Get memories by date range
  static Future<List<MemoryModel>> getMemoriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('memories')
        .select()
        .eq('user_id', userId)
        .gte('memory_date', startDate.toIso8601String().split('T')[0])
        .lte('memory_date', endDate.toIso8601String().split('T')[0])
        .order('memory_date', ascending: true);
    return data.map<MemoryModel>((json) => MemoryModel.fromJson(json)).toList();
  }

  // Search memories by title or description
  static Future<List<MemoryModel>> searchMemories(String userId, String query) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('memories')
        .select()
        .eq('user_id', userId)
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('memory_date', ascending: false);
    return data.map<MemoryModel>((json) => MemoryModel.fromJson(json)).toList();
  }

  // Get memories by tags
  static Future<List<MemoryModel>> getMemoriesByTag(String userId, String tag) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('memories')
        .select()
        .eq('user_id', userId)
        .contains('tags', [tag])
        .order('memory_date', ascending: false);
    return data.map<MemoryModel>((json) => MemoryModel.fromJson(json)).toList();
  }

  // Get all unique tags for user
  static Future<List<String>> getUserTags(String userId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('memories')
        .select('tags')
        .eq('user_id', userId);
    
    final Set<String> allTags = {};
    for (final item in data) {
      final tags = item['tags'] as List?;
      if (tags != null) {
        allTags.addAll(tags.cast<String>());
      }
    }
    
    return allTags.toList()..sort();
  }

  // Get recent memories
  static Future<List<MemoryModel>> getRecentMemories(String userId, {int limit = 10}) async {
    final data = await SupabaseService.select(
      'memories',
      where: 'user_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );
    return data.map((json) => MemoryModel.fromJson(json)).toList();
  }
}