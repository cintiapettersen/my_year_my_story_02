import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/models/memory_media_model.dart';

class MemoryMediaService {
  // Get media for a memory
  static Future<List<MemoryMediaModel>> getMemoryMedia(String memoryId) async {
    final data = await SupabaseService.select(
      'memory_media',
      where: 'memory_id',
      equals: memoryId,
      orderBy: 'display_order',
      ascending: true,
    );
    return data.map((json) => MemoryMediaModel.fromJson(json)).toList();
  }

  // Get user's media
  static Future<List<MemoryMediaModel>> getUserMedia(String userId, {String? mediaType}) async {
    dynamic query = SupabaseConfig.client
        .from('memory_media')
        .select()
        .eq('user_id', userId);
    
    if (mediaType != null) {
      query = query.eq('media_type', mediaType);
    }
    
    final data = await query.order('created_at', ascending: false);
    return data.map<MemoryMediaModel>((json) => MemoryMediaModel.fromJson(json)).toList();
  }

  // Add media to memory
  static Future<MemoryMediaModel> addMemoryMedia({
    required String memoryId,
    required String userId,
    required String mediaUrl,
    required String mediaType,
    String? caption,
    int displayOrder = 0,
  }) async {
    final data = await SupabaseService.insert('memory_media', {
      'memory_id': memoryId,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
      'display_order': displayOrder,
    });
    return MemoryMediaModel.fromJson(data.first);
  }

  // Update media
  static Future<MemoryMediaModel> updateMemoryMedia(String mediaId, Map<String, dynamic> updates) async {
    final data = await SupabaseService.update(
      'memory_media',
      updates,
      where: 'id',
      equals: mediaId,
    );
    return MemoryMediaModel.fromJson(data.first);
  }

  // Delete media
  static Future<void> deleteMemoryMedia(String mediaId) async {
    await SupabaseService.delete(
      'memory_media',
      where: 'id',
      equals: mediaId,
    );
  }

  // Reorder media for a memory
  static Future<void> reorderMemoryMedia(List<String> mediaIds) async {
    final client = SupabaseConfig.client;
    
    for (int i = 0; i < mediaIds.length; i++) {
      await client
          .from('memory_media')
          .update({'display_order': i})
          .eq('id', mediaIds[i]);
    }
  }

  // Get media by type
  static Future<List<MemoryMediaModel>> getMediaByType(String userId, String mediaType) async {
    final data = await SupabaseService.select(
      'memory_media',
      where: 'user_id',
      equals: userId,
      orderBy: 'created_at',
      ascending: false,
    );
    
    return data
        .map((json) => MemoryMediaModel.fromJson(json))
        .where((media) => media.mediaType == mediaType)
        .toList();
  }
}