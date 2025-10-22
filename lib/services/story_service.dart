import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/story_model.dart';

class StoryService {
  // Get all public stories
  static Future<List<StoryModel>> getPublicStories({int? limit}) async {
    final data = await SupabaseService.select(
      'stories',
      where: 'is_public',
      equals: true,
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );
    return data.map((json) => StoryModel.fromJson(json)).toList();
  }

  // Get user's stories
  static Future<List<StoryModel>> getUserStories(String userId) async {
    final data = await SupabaseService.select(
      'stories',
      where: 'user_id',
      equals: userId,
      orderBy: 'year',
      ascending: false,
    );
    return data.map((json) => StoryModel.fromJson(json)).toList();
  }

  // Get story by ID
  static Future<StoryModel?> getStoryById(String storyId) async {
    final data = await SupabaseService.selectOne(
      'stories',
      where: 'id',
      equals: storyId,
    );
    return data != null ? StoryModel.fromJson(data) : null;
  }

  // Get story by year for user
  static Future<StoryModel?> getStoryByYear(String userId, int year) async {
    final data = await SupabaseService.selectOne(
      'stories',
      where: 'user_id',
      equals: userId,
    );
    
    if (data != null) {
      final story = StoryModel.fromJson(data);
      if (story.year == year) {
        return story;
      }
    }
    return null;
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
    final data = await SupabaseService.insert('stories', {
      'user_id': userId,
      'year': year,
      'title': title,
      'content': content,
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
    });
    return StoryModel.fromJson(data.first);
  }

  // Update story
  static Future<StoryModel> updateStory(String storyId, Map<String, dynamic> updates) async {
    final data = await SupabaseService.update(
      'stories',
      updates,
      where: 'id',
      equals: storyId,
    );
    return StoryModel.fromJson(data.first);
  }

  // Delete story
  static Future<void> deleteStory(String storyId) async {
    await SupabaseService.delete(
      'stories',
      where: 'id',
      equals: storyId,
    );
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