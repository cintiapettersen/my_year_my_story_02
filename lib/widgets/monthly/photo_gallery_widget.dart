import 'dart:io';


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';

class MonthlyPhotoGallery extends StatefulWidget {
  final int month;
  final int year;

  const MonthlyPhotoGallery({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MonthlyPhotoGallery> createState() => _MonthlyPhotoGalleryState();
}

class _MonthlyPhotoGalleryState extends State<MonthlyPhotoGallery>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

// =========================
  // SNACKBAR
  // =========================
 void _showSnack(String textKey, {Color? color}) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color ?? const Color.fromARGB(255, 215, 126, 194),
      content: Text(textKey.tr()),
    ),
  );
}



  // =========================
  // FETCH
  // =========================
  Future<void> _fetchPhotos() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    if (!mounted) return;
    setState(() {
      _photos = [];
      _isLoading = false;
    });
    return;
  }

  try {
    setState(() => _isLoading = true);

    final res = await Supabase.instance.client
        .from('monthly_photos')
        .select()
        .eq('user_id', user.id)
        .eq('year', widget.year)
        .eq('month', widget.month)
        .order('created_at')
        .limit(4);

    if (!mounted) return;

    setState(() {
      _photos = List<Map<String, dynamic>>.from(res);
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Erro ao carregar fotos: $e');

    if (!mounted) return;

    setState(() {
      _photos = [];
      _isLoading = false; // 🔴 ISSO evita o loop
    });
  }
}


  // =========================
  // PICK + VALIDATE IMAGE
  // =========================
  Future<File?> _pickImageWithValidation(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked == null) return null;

    final file = File(picked.path);
    final size = await file.length();

    const maxSize = 5 * 1024 * 1024;

    if (size > maxSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFDECEA),
          content: const Text(
            'A foto é muito grande. Escolha uma imagem de até 5MB.',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
      return null;
    }

    return file;
  }

  // =========================
  // ADD PHOTO
  // =========================
  Future<void> _addPhoto(BuildContext context) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    _requireLogin();
    return;
  }

  final file = await _pickImageWithValidation(context);
  if (file == null) return;

  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final path = '${user.id}/${widget.year}/${widget.month}/$fileName';

  try {
    await Supabase.instance.client.storage.from('photos').upload(path, file);
  } catch (e) {
    debugPrint('Erro upload foto: $e');
    _showSnack('offline.save_warning', color: const Color(0xFFFDECEA));
    return;
  }

  try {
    await Supabase.instance.client.from('monthly_photos').insert({
      'year': widget.year,
      'month': widget.month,
      'file_path': path,
    });
  } catch (e) {
    debugPrint('Erro salvar no banco: $e');

    await Supabase.instance.client.storage.from('photos').remove([path]);

    _showSnack('offline.save_warning', color: const Color(0xFFFDECEA));
    return;
  }

  await _fetchPhotos();
}

// =========================
  // DELETE PHOTO SILENTLY
  // =========================
Future<void> _deletePhotoSilently(Map<String, dynamic> photo) async {
  final path = photo['file_path'] as String;

  await Supabase.instance.client.storage
      .from('photos')
      .remove([path]);

  await Supabase.instance.client
      .from('monthly_photos')
      .delete()
      .eq('id', photo['id']);
}

  // =========================
  // DELETE PHOTO
  // =========================
  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
  try {
    final path = photo['file_path'] as String;

    await Supabase.instance.client.storage.from('photos').remove([path]);
    await Supabase.instance.client
        .from('monthly_photos')
        .delete()
        .eq('id', photo['id']);

    await _fetchPhotos();
  } catch (e) {
    debugPrint('Erro ao deletar foto: $e');
    _showSnack('offline.delete_warning', color: const Color(0xFFFDECEA));
  }
}

  // =========================
  // REPLACE PHOTO
  // =========================
  Future<void> _replacePhoto(Map<String, dynamic> photo) async {
  await _deletePhotoSilently(photo);

  // ⏱️ pequeno respiro antes do picker
  await Future.delayed(const Duration(milliseconds: 200));

  if (!mounted) return;

  // ✅ aqui o context é o do State, seguro
  await _addPhoto(context);

}


// =========================
// REQUIRE LOGIN (GUEST)
// =========================
void _requireLogin() {
  showLoginPrompt(context);
}

  // =========================
  // COMMENT MODAL
  // =========================
  void _openCommentModal(Map<String, dynamic> photo) {
  final controller =
      TextEditingController(text: photo['description'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          bottomInset > 0 ? bottomInset + 40 : 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'photos.comment_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: controller, // ✅ agora está sendo usado
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'photos.comment_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
  try {
    await Supabase.instance.client
        .from('monthly_photos')
        .update({'description': controller.text})
        .eq('id', photo['id']);

    if (!mounted) return;

    Navigator.pop(context);
    await _fetchPhotos();
  } catch (e) {
    _showSnack(
      'offline.save_warning',
      color: const Color(0xFFFDECEA),
    );
  }
},

                child: Text('common.save'.tr()),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}


  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthPageTemplate(
      title: '',
      month: widget.month,
      year: widget.year,
      pageLabel: 'photos.title'.tr(),
      labelColor: const Color(0xFFb71691),
      description: 'photos.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final user =
                    Supabase.instance.client.auth.currentUser;

                if (index < _photos.length) {
                  final photo = _photos[index];
                  final path = photo['file_path'] as String;

                  final imageUrl = Supabase.instance.client.storage
                      .from('photos')
                      .getPublicUrl(path);

                  return GestureDetector(
  onTap: () {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _requireLogin();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text('photos.comment_title'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _openCommentModal(photo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text('photos.replace'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  _replacePhoto(photo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('photos.delete'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto(photo);
                },
              ),
            ],
          ),
        );
      },
    );
  },
  child: ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  _openCommentModal(photo),
                              child: Container(
                                padding:
                                    const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  photo['description'] == null
                                      ? Icons
                                          .chat_bubble_outline
                                      : Icons.chat_bubble,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ADD BUTTON
return GestureDetector(
  onTap: () async {
    if (user == null) {
  _requireLogin();
  return;
}

    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('photos.limit_reached'.tr()),
        ),
      );
      return;
    }

    await _addPhoto(context);
  },
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: const Color(0xFFFFE8F1),
      border: Border.all(
        color: const Color.fromARGB(255, 158, 118, 135),
      ),
    ),
    child: const Icon(Icons.add, size: 42),
  ),
);

              },
            ),
    );
  }
}
