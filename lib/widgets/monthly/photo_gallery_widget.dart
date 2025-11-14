import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/monthly/monthly_page_template.dart';

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
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // ================== MOCK PARA TESTE ==================
    _photos = [
      {
        'id': 1,
        'signed_url': 'assets/imagens/icone-01.png',
        'file_path': 'assets/imagens/icone-01.png',
      },
    ];
    _isLoading = false;
  }

  // ================== POPUP “DISPONÍVEL EM BREVE” ==================
  Future<void> _showComingSoonDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Disponível em breve 💫"),
        content: const Text(
          "A galeria de fotos será ativada nas próximas atualizações.\n"
              "Por enquanto, aproveite as outras seções do app!",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }

  // ================== Layout ==================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthlyPageTemplate(
      title: widget.title,
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
                    "Nenhuma foto ainda 💕\n"
                        "Escolha até 4 fotos especiais deste mês!",
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

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null
                      ? (url.startsWith('assets/')
                      ? Image.asset(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                      : Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ))
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 40),
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: _showComingSoonDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      border: Border.all(
                          color: Colors.grey[400]!, width: 1),
                    ),
                    child: const Icon(Icons.add,
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
