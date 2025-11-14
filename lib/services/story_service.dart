import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/models/story_model.dart';

class StoryService {
  // Get all public stories
  static Future<List<StoryModel>> getPublicStories({int? limit}) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return data.map<StoryModel>((json) => StoryModel.fromJson(json)).toList();
  }

  // Get user's stories
  static Future<List<StoryModel>> getUserStories(String userId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .order('year', ascending: false);

    return data.map<StoryModel>((json) => StoryModel.fromJson(json)).toList();
  }

  // Get story by ID
  static Future<StoryModel?> getStoryById(String storyId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .eq('id', storyId)
        .maybeSingle();

    return data != null ? StoryModel.fromJson(data) : null;
  }

  // Get story by year for user
  static Future<StoryModel?> getStoryByYear(String userId, int year) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .maybeSingle();

    return data != null ? StoryModel.fromJson(data) : null;
  }

  // Create new story
  static Future<StoryModel> createStory({
    required String userId,
    required int year,
    required String title,
    required String content,
    String? coverImageUrl,
    bool isPublic = false,
  }) async {
    final client = SupabaseConfig.client;
    final data = await client.from('stories').insert({
      'user_id': userId,
      'year': year,
      'title': title,
      'content': content,
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
    }).select();

    return StoryModel.fromJson(data.first);
  }

  // Update story
  static Future<StoryModel> updateStory(String storyId, Map<String, dynamic> updates) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .update(updates)
        .eq('id', storyId)
        .select();

    return StoryModel.fromJson(data.first);
  }

  // Delete story
  static Future<void> deleteStory(String storyId) async {
    final client = SupabaseConfig.client;
    await client.from('stories').delete().eq('id', storyId);
  }

  // Get stories by year range
  static Future<List<StoryModel>> getStoriesByYearRange(int startYear, int endYear) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .gte('year', startYear)
        .lte('year', endYear)
        .eq('is_public', true)
        .order('year', ascending: false);

    return data.map<StoryModel>((json) => StoryModel.fromJson(json)).toList();
  }

  // Search stories by title or content
  static Future<List<StoryModel>> searchPublicStories(String query) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select()
        .eq('is_public', true)
        .or('title.ilike.%$query%,content.ilike.%$query%')
        .order('created_at', ascending: false);

    return data.map<StoryModel>((json) => StoryModel.fromJson(json)).toList();
  }
}
