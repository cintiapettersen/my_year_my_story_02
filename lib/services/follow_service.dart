import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/follow_model.dart';

class FollowService {
  // Follow a user
  static Future<FollowModel> followUser({
    required String followerId,
    required String followingId,
  }) async {
    final data = await SupabaseService.insert('follows', {
      'follower_id': followerId,
      'following_id': followingId,
    });
    return FollowModel.fromJson(data.first);
  }

  // Unfollow a user
  static Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    final client = SupabaseConfig.client;
    await client
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  // Check if user is following another user
  static Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('follows')
        .select()
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    
    return data != null;
  }

  // Get user's followers
  static Future<List<FollowModel>> getFollowers(String userId) async {
    final data = await SupabaseService.select(
      'follows',
      where: 'following_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
    );
    return data.map((json) => FollowModel.fromJson(json)).toList();
  }

  // Get users that a user is following
  static Future<List<FollowModel>> getFollowing(String userId) async {
    final data = await SupabaseService.select(
      'follows',
      where: 'follower_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
    );
    return data.map((json) => FollowModel.fromJson(json)).toList();
  }

  // Get followers count
  static Future<int> getFollowersCount(String userId) async {
    final data = await SupabaseService.select(
      'follows',
      where: 'following_id',
      equals: userId,
    );
    return data.length;
  }

  // Get following count
  static Future<int> getFollowingCount(String userId) async {
    final data = await SupabaseService.select(
      'follows',
      where: 'follower_id',
      equals: userId,
    );
    return data.length;
  }

  // Toggle follow (follow if not following, unfollow if following)
  static Future<bool> toggleFollow({
    required String followerId,
    required String followingId,
  }) async {
    final isFollowing = await FollowService.isFollowing(
      followerId: followerId,
      followingId: followingId,
    );
    
    if (isFollowing) {
      await unfollowUser(followerId: followerId, followingId: followingId);
      return false;
    } else {
      await followUser(followerId: followerId, followingId: followingId);
      return true;
    }
  }

  // Get followers with user details
  static Future<List<Map<String, dynamic>>> getFollowersWithDetails(String userId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('follows')
        .select('*, users!follows_follower_id_fkey(id, full_name, avatar_url)')
        .eq('following_id', userId)
        .order('created_at', ascending: false);
    
    return data.cast<Map<String, dynamic>>();
  }

  // Get following with user details
  static Future<List<Map<String, dynamic>>> getFollowingWithDetails(String userId) async {
    final client = SupabaseConfig.client;
    final data = await client
        .from('follows')
        .select('*, users!follows_following_id_fkey(id, full_name, avatar_url)')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);
    
    return data.cast<Map<String, dynamic>>();
  }

  // Get user stats (followers and following count)
  static Future<Map<String, int>> getUserFollowStats(String userId) async {
    final followersCount = await getFollowersCount(userId);
    final followingCount = await getFollowingCount(userId);
    
    return {
      'followers': followersCount,
      'following': followingCount,
    };
  }

  // Get suggested users to follow (users with most followers that current user doesn't follow)
  static Future<List<Map<String, dynamic>>> getSuggestedUsers(String currentUserId, {int limit = 10}) async {
    final client = SupabaseConfig.client;
    
    // Get users current user is already following
    final following = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId);
    
    final followingIds = following.map((f) => f['following_id']).toList();
    followingIds.add(currentUserId); // Don't suggest self
    
    // Get users with most followers that current user doesn't follow
    final data = await client
        .from('users')
        .select('*, follows!follows_following_id_fkey(count)')
        .not('id', 'in', followingIds)
        .order('follows.count', ascending: false)
        .limit(limit);
    
    return data.cast<Map<String, dynamic>>();
  }
}