import 'package:flutter/material.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/widgets/shared/main_scaffold.dart'; // 👈 importa o scaffold base

class AnnualPhotoAlbumScreen extends StatefulWidget {
  final int month;
  final int year;

  const AnnualPhotoAlbumScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<AnnualPhotoAlbumScreen> createState() => _AnnualPhotoAlbumScreenState();
}

class _AnnualPhotoAlbumScreenState extends State<AnnualPhotoAlbumScreen> {
  final _supabase = SupabaseConfig.client;
  Map<int, List<Map<String, dynamic>>> _photosByMonth = {};
  bool _isLoading = true;

  final List<String> _monthNames = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnualPhotos();
  }

  /// ================== Buscar fotos anuais ==================
  Future<void> _loadAnnualPhotos() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('monthly_photos') // 👈 tabela de fotos mensais
          .select('id, month, year, file_path')
          .eq('user_id', userId)
          .eq('year', widget.year);

      final photos = List<Map<String, dynamic>>.from(response);

      final List<Map<String, dynamic>> photosWithUrls = [];
      for (final photo in photos) {
        final path = photo['file_path'] as String?;
        if (path != null) {
          final signedUrl = await _supabase.storage
              .from('photos') // 👈 bucket
              .createSignedUrl(path, 60 * 60 * 24);
          photo['signed_url'] = signedUrl;
        }
        photosWithUrls.add(photo);
      }

      // Agrupar por mês (máx. 4 fotos)
      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (final photo in photosWithUrls) {
        final month = photo['month'] as int;
        grouped.putIfAbsent(month, () => []);
        if (grouped[month]!.length < 4) {
          grouped[month]!.add(photo);
        }
      }

      if (!mounted) return;
      setState(() => _photosByMonth = grouped);
    } catch (e) {
      debugPrint("❌ Erro ao carregar fotos anuais: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// ================== Layout ==================
  @override
  Widget build(BuildContext context) {
    final year = widget.year;

    return MainScaffold(
      currentIndex: 3, // 👈 coloque o índice da aba "Fotos" ou o que for correto no menu
      title: "Seu Álbum de Fotos $year",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photosByMonth.isEmpty
          ? _buildFallback()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Suas memórias do ano registradas aqui, continue fazendo sua história!",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ..._buildPhotoSections(),
          ],
        ),
      ),
    );
  }


  /// ================== Fallback (nenhuma foto no ano) ==================
  Widget _buildFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_album_outlined, size: 80, color: Color(0xFF1fa396)),
            SizedBox(height: 20),
            Text(
              "Suas fotos mensais vão aparecer aqui 📷✨",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Adicione fotos em cada mês para construir\n"
                  "seu álbum anual automaticamente!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  /// ================== Seções com fotos ==================
  List<Widget> _buildPhotoSections() {
    final List<Widget> sections = [];

    _photosByMonth.forEach((month, photos) {
      sections.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthNames[month - 1],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1fa396),
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final url = photo['signed_url'] as String?;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url != null
                    ? Image.network(url, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      color: Colors.grey, size: 40),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ));
    });

    return sections;
  }
}
