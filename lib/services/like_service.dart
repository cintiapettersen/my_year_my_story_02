import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/like_model.dart';

class LikeService {
  // Like a story
  static Future<LikeModel> likeStory({
    required String storyId,
    required String userId,
  }) async {
    final data = await SupabaseService.insert('likes', {
      'story_id': storyId,
      'user_id': userId,
    });
    return LikeModel.fromJson(data.first);
  }

  // Unlike a story
  static Future<void> unlikeStory({
    required String storyId,
    required String userId,
  }) async {
    final client = SupabaseConfig.client;
    await client
        .from('likes')
        .delete()
        .eq('story_id', storyId)
        .eq('user_id', userId);
  }

  // Check if user liked story
  static Future<bool> hasUserLikedStory({
    required String storyId,
    required String userId,
  }) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('likes')
        .select()
        .eq('story_id', storyId)
        .eq('user_id', userId)
        .maybeSingle();
    
    return data != null;
  }

  // Get story likes count
  static Future<int> getStoryLikesCount(String storyId) async {
    final data = await SupabaseService.select(
      'likes',
      where: 'story_id',
      equals: storyId,
    );
    return data.length;
  }

  // Get users who liked a story
  static Future<List<LikeModel>> getStoryLikes(String storyId) async {
    final data = await SupabaseService.select(
      'likes',
      where: 'story_id',
      equals: storyId,
      orderBy: 'created_at',
      ascending: false,
    );
    return data.map((json) => LikeModel.fromJson(json)).toList();
  }

  // Get user's likes
  static Future<List<LikeModel>> getUserLikes(String userId) async {
    final data = await SupabaseService.select(
      'likes',
      where: 'user_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
    );
    return data.map((json) => LikeModel.fromJson(json)).toList();
  }

  // Toggle like (like if not liked, unlike if liked)
  static Future<bool> toggleLike({
    required String storyId,
    required String userId,
  }) async {
    final isLiked = await hasUserLikedStory(storyId: storyId, userId: userId);
    
    if (isLiked) {
      await unlikeStory(storyId: storyId, userId: userId);
      return false;
    } else {
      await likeStory(storyId: storyId, userId: userId);
      return true;
    }
  }

  // Get likes with user details
  static Future<List<Map<String, dynamic>>> getLikesWithUserDetails(String storyId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('likes')
        .select('*, users!inner(full_name, avatar_url)')
        .eq('story_id', storyId)
        .order('created_at', ascending: false);
    
    return data.cast<Map<String, dynamic>>();
  }

  // Get most liked stories
  static Future<List<Map<String, dynamic>>> getMostLikedStories({int limit = 10}) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('stories')
        .select('*, likes!inner(count)')
        .eq('is_public', true)
        .order('likes.count', ascending: false)
        .limit(limit);
    
    return data.cast<Map<String, dynamic>>();
  }
}