import 'dart:io';


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

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

  static const Color _photosAccent = Color(0xFFb71691);
  static const Color _shellSecondary = Color(0xFFD7C3EE);

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

  Widget _slotShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _photosAccent.withValues(alpha: 0.18),
            _shellSecondary.withValues(alpha: 0.20),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _photosAccent.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
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
	              autocorrect: true,
	              enableSuggestions: true,
	              smartQuotesType: SmartQuotesType.enabled,
	              smartDashesType: SmartDashesType.enabled,
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
              child: AppPillButton(
                expand: true,
                text: 'common.save'.tr(),
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
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxWidth = isTablet ? 520.0 : 420.0;

    return MonthPageTemplate(
      title: '',
      month: widget.month,
      year: widget.year,
      pageLabel: 'photos.title'.tr(),
      labelColor: const Color(0xFFb71691),
      description: 'photos.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
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
                              final user =
                                  Supabase.instance.client.auth.currentUser;

                              if (user == null) {
                                _requireLogin();
                                return;
                              }

                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (_) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.chat_bubble_outline,
                                          ),
                                          title: Text(
                                            'photos.comment_title'.tr(),
                                          ),
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
                                            await Future.delayed(
                                              const Duration(milliseconds: 300),
                                            );
                                            if (!mounted) return;
                                            _replacePhoto(photo);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
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
                            child: _slotShell(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _openCommentModal(photo),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          photo['description'] == null
                                              ? Icons.chat_bubble_outline
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
                          child: _slotShell(
                            child: Container(
                              color: const Color(0xFFFFF7FA),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_rounded,
                                      size: 46,
                                      color: Colors.black.withValues(alpha: 0.30),
                                    ),
                                    Positioned(
                                      bottom: 26,
                                      right: 26,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: _photosAccent.withValues(
                                            alpha: 0.92,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
