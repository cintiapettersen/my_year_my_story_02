import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'package:my_year_my_story/utils/month_colors.dart';

class MonthlyPhotoGallery extends StatefulWidget {
  final int month;
  final int year;
  final String title;

  const MonthlyPhotoGallery({
    super.key,
    required this.month,
    required this.year,
    this.title = "Galeria do Mês 💕",
  });

  @override
  State<MonthlyPhotoGallery> createState() => _MonthlyPhotoGalleryState();
}

class _MonthlyPhotoGalleryState extends State<MonthlyPhotoGallery>
    with AutomaticKeepAliveClientMixin {
  final _supabase = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // ================== MOCK PARA TESTE ==================
    _photos = [
      // {
      //   'id': 1,
      //   'file_path': 'assets/imagens/icone-01.png',
      //   'signed_url': 'assets/imagens/icone-01.png'
      // },
    ];
    _isLoading = false;

    // 👉 Quando estiver pronto pra usar o Supabase, ative:
    // _loadPhotos();
  }

  // ================== Buscar fotos (Supabase) ==================
  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("Usuário não logado.");

      final response = await _supabase
          .from('monthly_photos')
          .select('id, file_path, description')
          .eq('user_id', userId)
          .eq('month', widget.month)
          .eq('year', widget.year);

      final List<Map<String, dynamic>> photosWithUrls = [];
      for (final photo in response) {
        final path = photo['file_path'] as String?;
        if (path != null) {
          final signed = await _supabase.storage
              .from('photos')
              .createSignedUrl(path, 60 * 60 * 24);
          photo['signed_url'] = signed;
        }
        photosWithUrls.add(photo);
      }

      setState(() => _photos = photosWithUrls);
    } catch (e) {
      print("❌ Erro ao carregar fotos mensais: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================== Upload de foto ==================
  Future<void> _pickAndUploadPhoto() async {
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Você só pode adicionar 4 fotos por mês.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileName =
          "${_supabase.auth.currentUser?.id}_${widget.year}_${widget.month}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = "${widget.year}/${widget.month}/$fileName";

      await _supabase.storage.from('photos').upload(filePath, file);

      await _supabase.from('monthly_photos').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'year': widget.year,
        'month': widget.month,
        'file_path': filePath,
        'description': "Foto adicionada em ${DateTime.now()}",
      });

      _loadPhotos();
    } catch (e) {
      print("❌ Erro ao fazer upload mensal: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ================== Deletar foto ==================
  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
    try {
      final path = photo['file_path'];
      final id = photo['id'];

      if (path != null) {
        await _supabase.storage.from('photos').remove([path]);
      }
      if (id != null) {
        await _supabase.from('monthly_photos').delete().eq('id', id);
      }

      _loadPhotos();
    } catch (e) {
      print("❌ Erro ao deletar foto: $e");
    }
  }

  // ================== Layout ==================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthlyPageTemplate(
      title: widget.title, // ✅ repassa o título corretamente
      month: widget.month,
      year: widget.year,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: const [
                  Icon(Icons.photo_camera_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "Nenhuma foto ainda 💕\nEscolha até 4 fotos especiais deste mês!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                final photo = _photos[index];
                final url = photo['signed_url'] as String?;

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: url != null
                          ? (url.startsWith('assets/')
                          ? Image.asset(url,
                          fit: BoxFit.cover,
                          width: double.infinity)
                          : Image.network(url,
                          fit: BoxFit.cover,
                          width: double.infinity))
                          : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deletePhoto(photo),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      border: Border.all(
                          color: Colors.grey[400]!, width: 1),
                    ),
                    child: _isUploading
                        ? const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                        : const Icon(Icons.add,
                        color: Colors.grey, size: 40),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
