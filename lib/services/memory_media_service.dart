import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/models/memory_media_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryMediaService {
  static final _client = Supabase.instance.client;

  // 📸 Buscar mídias de uma memória específica
  static Future<List<MemoryMediaModel>> getMemoryMedia(String memoryId) async {
    final data = await _client
        .from('memory_media')
        .select()
        .eq('memory_id', memoryId)
        .order('display_order', ascending: true);

    return (data as List)
        .map((json) => MemoryMediaModel.fromJson(json))
        .toList();
  }

  // 👤 Buscar mídias de um usuário
  static Future<List<MemoryMediaModel>> getUserMedia(String userId, {String? mediaType}) async {
    var query = _client
        .from('memory_media')
        .select()
        .eq('user_id', userId);

    if (mediaType != null) {
      query = query.eq('media_type', mediaType);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((json) => MemoryMediaModel.fromJson(json))
        .toList();
  }

  // ➕ Adicionar nova mídia
  static Future<MemoryMediaModel> addMemoryMedia({
    required String memoryId,
    required String userId,
    required String mediaUrl,
    required String mediaType,
    String? caption,
    int displayOrder = 0,
  }) async {
    final data = await _client.from('memory_media').insert({
      'memory_id': memoryId,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
      'display_order': displayOrder,
    }).select();

    return MemoryMediaModel.fromJson((data as List).first);
  }

  // ✏️ Atualizar mídia
  static Future<MemoryMediaModel> updateMemoryMedia(
      String mediaId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('memory_media')
        .update(updates)
        .eq('id', mediaId)
        .select();

    return MemoryMediaModel.fromJson((data as List).first);
  }

  // 🗑️ Excluir mídia
  static Future<void> deleteMemoryMedia(String mediaId) async {
    await _client.from('memory_media').delete().eq('id', mediaId);
  }

  // 🔢 Reordenar mídias
  static Future<void> reorderMemoryMedia(List<String> mediaIds) async {
    for (int i = 0; i < mediaIds.length; i++) {
      await _client
          .from('memory_media')
          .update({'display_order': i})
          .eq('id', mediaIds[i]);
    }
  }

  // 🎨 Buscar mídias por tipo
  static Future<List<MemoryMediaModel>> getMediaByType(
      String userId, String mediaType) async {
    final data = await _client
        .from('memory_media')
        .select()
        .eq('user_id', userId)
        .eq('media_type', mediaType)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => MemoryMediaModel.fromJson(json))
        .toList();
  }
}
