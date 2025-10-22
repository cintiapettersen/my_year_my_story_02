import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/comment_model.dart';

class CommentService {
  // Get comments for a story
  static Future<List<CommentModel>> getStoryComments(String storyId) async {
    final data = await SupabaseService.select(
      'comments',
      where: 'story_id',
      equals: storyId,
      orderBy: 'created_at',
      ascending: true,
    );
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  // Get user's comments
  static Future<List<CommentModel>> getUserComments(String userId) async {
    final data = await SupabaseService.select(
      'comments',
      where: 'user_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
    );
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  // Create comment
  static Future<CommentModel> createComment({
    required String storyId,
    required String userId,
    required String content,
  }) async {
    final data = await SupabaseService.insert('comments', {
      'story_id': storyId,
      'user_id': userId,
      'content': content,
    });
    return CommentModel.fromJson(data.first);
  }

  // Update comment
  static Future<CommentModel> updateComment(String commentId, String content) async {
    final data = await SupabaseService.update(
      'comments',
      {'content': content},
      where: 'id',
      equals: commentId,
    );
    return CommentModel.fromJson(data.first);
  }

  // Delete comment
  static Future<void> deleteComment(String commentId) async {
    await SupabaseService.delete(
      'comments',
      where: 'id',
      equals: commentId,
    );
  }

  // Get comment count for story
  static Future<int> getCommentCount(String storyId) async {
    final data = await SupabaseService.select(
      'comments',
      where: 'story_id',
      equals: storyId,
    );
    return data.length;
  }

  // Get recent comments
  static Future<List<CommentModel>> getRecentComments({int limit = 10}) async {
    final data = await SupabaseService.select(
      'comments',
      orderBy: 'created_at',
      ascending: false,
      limit: limit,
    );
    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  // Get comments with user details
  static Future<List<Map<String, dynamic>>> getCommentsWithUserDetails(String storyId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('comments')
        .select('*, users!inner(full_name, avatar_url)')
        .eq('story_id', storyId)
        .order('created_at', ascending: true);
    
    return data.cast<Map<String, dynamic>>();
  }
}